import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

import '../../models/coordinates.dart';
import '../../location/location_data.dart';
import '../navigation_logger.dart';
import '../navigation_options.dart';
import '../tracking/motion_predictor.dart';
import '../tracking/position_smoother.dart';
import '../tracking/route_cursor_engine.dart';
import 'bearing_smoother.dart';

/// Callback fired every animation frame with interpolated position, bearing,
/// speed, and current segment index for route line snapping.
typedef AnimationFrameCallback = void Function(
  Coordinates position,
  double bearing,
  double speed,
  int segmentIndex,
);

/// Route state for smooth on-route ↔ off-route transitions.
enum _RouteTransitionState {
  /// Cursor is on the route, using RouteCursorEngine.
  onRoute,

  /// Transitioning from route to free-space (blending out).
  leavingRoute,

  /// Cursor is off-route, using spline/prediction fallback.
  offRoute,

  /// Transitioning from free-space back to route (blending in).
  joiningRoute,
}

/// Produces smooth 60fps position updates from 1Hz GPS input.
///
/// **Route-first pipeline (when on-route):**
/// GPS → RouteCursorEngine.feedGps() → advance(dt) → position ON route
///
/// **Fallback pipeline (when off-route):**
/// GPS → MotionPredictor → PositionSmoother → Spline/Linear/DeadReckoning
///
/// Smooth transitions between the two modes via blend factor animation.
class PositionAnimator {
  final NavigationOptions options;

  // Sub-components
  final MotionPredictor _predictor;
  final PositionSmoother _positionSmoother;
  final BearingSmoother _bearingSmoother;

  // Route cursor engine — primary position source when on-route
  RouteCursorEngine? _routeCursorEngine;

  // Route transition state
  _RouteTransitionState _routeState = _RouteTransitionState.offRoute;
  double _blendFactor = 1.0; // 0.0 = route, 1.0 = free-space
  DateTime? _blendStartTime;

  // Animation state
  Ticker? _ticker;
  Duration _lastTickTime = Duration.zero;
  bool _running = false;

  // GPS control points for spline interpolation (off-route fallback)
  final List<_ControlPoint> _controlPoints = [];
  static const int _maxControlPoints = 6;

  // Current interpolated state
  Coordinates? _currentPosition;
  double _currentBearing = 0;
  double _currentSpeed = 0;

  // Route constraint (kept for off-route fallback predictor)
  List<Coordinates>? _routePolyline;
  int _currentSegmentIndex = 0;

  // Callback
  AnimationFrameCallback? onFrame;

  PositionAnimator({
    required this.options,
    MotionPredictor? predictor,
    PositionSmoother? positionSmoother,
    BearingSmoother? bearingSmoother,
  })  : _predictor = predictor ??
            MotionPredictor(
              bufferSize: 8,
              maxPredictionTimeSec: 2.0,
              maxPredictionDistanceM: options.maxPredictDistanceMeters,
            ),
        _positionSmoother = positionSmoother ??
            PositionSmoother(
              alphaMin: options.cameraPositionAlphaMin,
              alphaMax: options.cameraPositionAlphaMax,
              deadZoneMeters: 0.05,
            ),
        _bearingSmoother = bearingSmoother ??
            BearingSmoother(
              alphaMin: options.minBearingSmoothing,
              alphaMax: options.maxBearingSmoothing,
              maxVelocityLowSpeed: options.cameraBearingMaxVelocityLowSpeed,
              maxVelocityHighSpeed: options.cameraBearingMaxVelocityHighSpeed,
            );

  /// Current interpolated position.
  Coordinates? get position => _currentPosition;

  /// Current interpolated bearing.
  double get bearing => _currentBearing;

  /// Current speed in m/s.
  double get speed => _currentSpeed;

  /// Whether the animator is running.
  bool get isRunning => _running;

  /// Whether cursor is currently on the route.
  bool get isOnRoute =>
      _routeState == _RouteTransitionState.onRoute ||
      _routeState == _RouteTransitionState.joiningRoute;

  /// The route cursor engine (for external access to distance, segment, etc.).
  RouteCursorEngine? get routeCursorEngine => _routeCursorEngine;

  /// Sets the route polyline for route-constrained interpolation.
  ///
  /// Creates a [RouteCursorEngine] for on-route position tracking.
  void setRoute(List<Coordinates> polyline) {
    _routePolyline = polyline;
    _currentSegmentIndex = 0;

    // Create route cursor engine
    _routeCursorEngine = RouteCursorEngine(options: options);
    _routeCursorEngine!.setRoute(polyline);

    // Start in on-route state
    _routeState = _RouteTransitionState.onRoute;
    _blendFactor = 0.0;

    NavigationLogger.info('PositionAnimator', 'Route set with cursor engine', {
      'points': polyline.length,
    });
  }

  /// Updates the current segment index for route-constrained prediction.
  void updateSegmentIndex(int index) {
    _currentSegmentIndex = index;
  }

  /// Feeds a new GPS location into the animation pipeline.
  void feedLocation(LocationData location) {
    final now = DateTime.now();

    // Always feed to predictor (for off-route fallback)
    _predictor.addSample(location);

    // Feed to route cursor engine
    _routeCursorEngine?.feedGps(
      location.coordinates,
      location.speed ?? 0,
    );

    // Feed to off-route pipeline (smoother + control points)
    final smoothedPos = _positionSmoother.smooth(
      location.coordinates,
      location.speed ?? 0,
    );

    // Use route segment bearing when available (stable), fall back to GPS heading
    double bearing = location.heading ?? _currentBearing;
    if (_routePolyline != null &&
        _currentSegmentIndex < _routePolyline!.length - 1) {
      final segStart = _routePolyline![_currentSegmentIndex];
      final segEnd = _routePolyline![_currentSegmentIndex + 1];
      bearing = segStart.bearingTo(segEnd);
    }

    _controlPoints.add(_ControlPoint(
      position: smoothedPos,
      bearing: bearing,
      speed: location.speed ?? 0,
      timestamp: now,
    ));

    while (_controlPoints.length > _maxControlPoints) {
      _controlPoints.removeAt(0);
    }

    _currentSpeed = location.speed ?? 0;

    // Check route transition
    _checkRouteTransition();
  }

  /// Starts the 60fps animation loop.
  void start(TickerProvider vsync) {
    if (_running) return;

    _ticker = vsync.createTicker(_onTick);
    _ticker!.start();
    _running = true;
    _lastTickTime = Duration.zero;

    NavigationLogger.info('PositionAnimator', 'Animation started');
  }

  /// Stops the animation loop.
  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _running = false;
    _lastTickTime = Duration.zero;

    NavigationLogger.info('PositionAnimator', 'Animation stopped');
  }

  /// Resets all state.
  void reset() {
    _controlPoints.clear();
    _predictor.reset();
    _positionSmoother.reset();
    _bearingSmoother.reset();
    _routeCursorEngine?.reset();
    _routeCursorEngine = null;
    _currentPosition = null;
    _currentBearing = 0;
    _currentSpeed = 0;
    _routePolyline = null;
    _currentSegmentIndex = 0;
    _routeState = _RouteTransitionState.offRoute;
    _blendFactor = 1.0;
    _blendStartTime = null;
  }

  /// Disposes all resources.
  void dispose() {
    stop();
    reset();
  }

  // ---------------------------------------------------------------------------
  // Route transition management
  // ---------------------------------------------------------------------------

  void _checkRouteTransition() {
    if (_routeCursorEngine == null) return;

    final engineOnRoute = _routeCursorEngine!.isOnRoute;

    switch (_routeState) {
      case _RouteTransitionState.onRoute:
        if (!engineOnRoute) {
          _routeState = _RouteTransitionState.leavingRoute;
          _blendStartTime = DateTime.now();
          _blendFactor = 0.0;
          NavigationLogger.info(
              'PositionAnimator', 'Route state: onRoute → leavingRoute');
        }
        break;

      case _RouteTransitionState.leavingRoute:
        if (engineOnRoute) {
          _routeState = _RouteTransitionState.joiningRoute;
          _blendStartTime = DateTime.now();
          NavigationLogger.info(
              'PositionAnimator', 'Route state: leavingRoute → joiningRoute');
        }
        break;

      case _RouteTransitionState.offRoute:
        if (engineOnRoute) {
          _routeState = _RouteTransitionState.joiningRoute;
          _blendStartTime = DateTime.now();
          _blendFactor = 1.0;
          NavigationLogger.info(
              'PositionAnimator', 'Route state: offRoute → joiningRoute');
        }
        break;

      case _RouteTransitionState.joiningRoute:
        if (!engineOnRoute) {
          _routeState = _RouteTransitionState.leavingRoute;
          _blendStartTime = DateTime.now();
          NavigationLogger.info(
              'PositionAnimator', 'Route state: joiningRoute → leavingRoute');
        }
        break;
    }
  }

  void _updateBlendFactor() {
    if (_blendStartTime == null) return;

    const transitionDurationMs = 500;
    final elapsed =
        DateTime.now().difference(_blendStartTime!).inMilliseconds;
    final progress = (elapsed / transitionDurationMs).clamp(0.0, 1.0);

    switch (_routeState) {
      case _RouteTransitionState.leavingRoute:
        _blendFactor = progress; // 0 → 1 (route → free)
        if (progress >= 1.0) {
          _routeState = _RouteTransitionState.offRoute;
          _blendStartTime = null;
          NavigationLogger.info(
              'PositionAnimator', 'Route state: leavingRoute → offRoute');
        }
        break;

      case _RouteTransitionState.joiningRoute:
        _blendFactor = 1.0 - progress; // 1 → 0 (free → route)
        if (progress >= 1.0) {
          _routeState = _RouteTransitionState.onRoute;
          _blendFactor = 0.0;
          _blendStartTime = null;
          NavigationLogger.info(
              'PositionAnimator', 'Route state: joiningRoute → onRoute');
        }
        break;

      case _RouteTransitionState.onRoute:
        _blendFactor = 0.0;
        break;

      case _RouteTransitionState.offRoute:
        _blendFactor = 1.0;
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Ticker callback
  // ---------------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    if (_controlPoints.isEmpty && _routeCursorEngine?.currentPosition == null) {
      return;
    }

    // Calculate dt since last tick
    final dt = _lastTickTime == Duration.zero
        ? const Duration(milliseconds: 16)
        : elapsed - _lastTickTime;
    _lastTickTime = elapsed;

    // Update blend factor for transitions
    _updateBlendFactor();

    // Get position from appropriate source
    final interpolated = _interpolatePosition(dt);
    if (interpolated == null) return;

    // Smooth bearing
    final rawBearing = interpolated.bearing;
    final smoothedBearing = _bearingSmoother.smooth(
      rawBearing,
      _currentSpeed,
      dt,
    );

    _currentPosition = interpolated.position;
    _currentBearing = smoothedBearing;

    // Notify listener with current segment index for route line snapping
    onFrame?.call(
      _currentPosition!,
      _currentBearing,
      _currentSpeed,
      _currentSegmentIndex,
    );
  }

  // ---------------------------------------------------------------------------
  // Position interpolation
  // ---------------------------------------------------------------------------

  _InterpolatedResult? _interpolatePosition(Duration dt) {
    // Get route-constrained position (if available)
    CursorPosition? routePos;
    if (_routeCursorEngine != null && _routeCursorEngine!.hasRoute) {
      routePos = _routeCursorEngine!.advance(dt);
      // Update segment index from cursor engine for route line manager
      if (routePos != null) {
        _currentSegmentIndex = routePos.segmentIndex;
      }
    }

    // Get free-space position (fallback)
    _InterpolatedResult? freePos;
    if (_blendFactor > 0.0 || routePos == null) {
      freePos = _interpolateFreeSpace(dt);
    }

    // Determine output based on route state
    switch (_routeState) {
      case _RouteTransitionState.onRoute:
        if (routePos != null) {
          return _InterpolatedResult(
            position: routePos.position,
            bearing: routePos.bearing,
          );
        }
        return freePos;

      case _RouteTransitionState.offRoute:
        return freePos ?? (routePos != null
            ? _InterpolatedResult(
                position: routePos.position,
                bearing: routePos.bearing,
              )
            : null);

      case _RouteTransitionState.leavingRoute:
      case _RouteTransitionState.joiningRoute:
        // Blend between route and free-space
        if (routePos != null && freePos != null) {
          return _blendPositions(
            routePosition: routePos.position,
            routeBearing: routePos.bearing,
            freePosition: freePos.position,
            freeBearing: freePos.bearing,
            blend: _blendFactor,
          );
        }
        // Fallback to whichever is available
        if (routePos != null) {
          return _InterpolatedResult(
            position: routePos.position,
            bearing: routePos.bearing,
          );
        }
        return freePos;
    }
  }

  /// Blends between route and free-space positions.
  _InterpolatedResult _blendPositions({
    required Coordinates routePosition,
    required double routeBearing,
    required Coordinates freePosition,
    required double freeBearing,
    required double blend, // 0 = route, 1 = free
  }) {
    final lat =
        routePosition.lat + (freePosition.lat - routePosition.lat) * blend;
    final lon =
        routePosition.lon + (freePosition.lon - routePosition.lon) * blend;

    // Shortest-angle bearing blend
    final bearingDelta =
        BearingSmoother.shortestAngleDelta(routeBearing, freeBearing);
    var bearing = (routeBearing + bearingDelta * blend) % 360;
    if (bearing < 0) bearing += 360;

    return _InterpolatedResult(
      position: Coordinates(
        lat: lat.clamp(-90.0, 90.0),
        lon: lon.clamp(-180.0, 180.0),
      ),
      bearing: bearing,
    );
  }

  /// Free-space interpolation (used when off-route).
  ///
  /// Strategy:
  /// 1. If route available, use predictAlongRoute from MotionPredictor
  /// 2. If 4+ control points, use Catmull-Rom spline
  /// 3. If 2+ control points, use linear interpolation
  /// 4. Fallback: dead-reckoning
  _InterpolatedResult? _interpolateFreeSpace(Duration dt) {
    if (_controlPoints.isEmpty) return null;

    // Try route-constrained prediction (MotionPredictor, for off-route smoothing)
    if (_routePolyline != null && _routePolyline!.length > 1) {
      final predicted = _predictor.predictAlongRoute(
        Duration.zero,
        _routePolyline!,
        _currentSegmentIndex,
      );
      if (predicted != null && predicted.confidence > 0.5) {
        var pos = predicted.position;
        if (_currentPosition != null) {
          final alpha = _routeBlendAlpha(_currentSpeed);
          pos = Coordinates(
            lat: _currentPosition!.lat +
                (pos.lat - _currentPosition!.lat) * alpha,
            lon: _currentPosition!.lon +
                (pos.lon - _currentPosition!.lon) * alpha,
          );
        }
        return _InterpolatedResult(
          position: pos,
          bearing: predicted.bearing,
        );
      }
    }

    final now = DateTime.now();
    final lastPoint = _controlPoints.last;
    final timeSinceLastPoint =
        now.difference(lastPoint.timestamp).inMicroseconds / 1e6;

    if (_controlPoints.length >= 4 && timeSinceLastPoint < 2.0) {
      return _catmullRomInterpolate(timeSinceLastPoint);
    }

    if (_controlPoints.length >= 2 && timeSinceLastPoint < 2.0) {
      return _linearInterpolate(timeSinceLastPoint);
    }

    return _deadReckon(lastPoint, timeSinceLastPoint);
  }

  // ---------------------------------------------------------------------------
  // Free-space interpolation methods (unchanged from original)
  // ---------------------------------------------------------------------------

  _InterpolatedResult _catmullRomInterpolate(double timeSinceLastPoint) {
    final n = _controlPoints.length;
    final p0 = _controlPoints[n - 4];
    final p1 = _controlPoints[n - 3];
    final p2 = _controlPoints[n - 2];
    final p3 = _controlPoints[n - 1];

    final interval =
        p3.timestamp.difference(p0.timestamp).inMicroseconds / (3 * 1e6);
    if (interval <= 0) {
      return _InterpolatedResult(
        position: p3.position,
        bearing: p3.bearing,
      );
    }

    final t = (timeSinceLastPoint / interval).clamp(0.0, 1.0);

    final lat = _catmullRomValue(
      p0.position.lat,
      p1.position.lat,
      p2.position.lat,
      p3.position.lat,
      t,
    );
    final lon = _catmullRomValue(
      p0.position.lon,
      p1.position.lon,
      p2.position.lon,
      p3.position.lon,
      t,
    );

    final clampedLat = lat.clamp(-90.0, 90.0);
    final clampedLon = lon.clamp(-180.0, 180.0);

    final bearingDelta =
        BearingSmoother.shortestAngleDelta(p2.bearing, p3.bearing);
    final bearing = (p3.bearing + bearingDelta * t) % 360;

    final result = Coordinates(lat: clampedLat, lon: clampedLon);
    final maxDist = _currentSpeed * 2.0;
    if (maxDist > 0 && result.distanceTo(p3.position) > maxDist) {
      return _deadReckon(p3, timeSinceLastPoint);
    }

    return _InterpolatedResult(
      position: result,
      bearing: bearing < 0 ? bearing + 360 : bearing,
    );
  }

  double _catmullRomValue(
    double p0,
    double p1,
    double p2,
    double p3,
    double t,
  ) {
    final tt = t;
    final tt2 = tt * tt;
    final tt3 = tt2 * tt;

    final ext = p3 + (p3 - p2);

    return 0.5 *
        ((2 * p2) +
            (-p1 + p3) * tt +
            (2 * p1 - 5 * p2 + 4 * p3 - ext) * tt2 +
            (-p1 + 3 * p2 - 3 * p3 + ext) * tt3);
  }

  _InterpolatedResult _linearInterpolate(double timeSinceLastPoint) {
    final n = _controlPoints.length;
    final prev = _controlPoints[n - 2];
    final last = _controlPoints[n - 1];

    final dt =
        last.timestamp.difference(prev.timestamp).inMicroseconds / 1e6;
    if (dt <= 0) {
      return _InterpolatedResult(
        position: last.position,
        bearing: last.bearing,
      );
    }

    final vLat = (last.position.lat - prev.position.lat) / dt;
    final vLon = (last.position.lon - prev.position.lon) / dt;

    final t = timeSinceLastPoint.clamp(0.0, 2.0);

    var lat = last.position.lat + vLat * t;
    var lon = last.position.lon + vLon * t;

    lat = lat.clamp(-90.0, 90.0);
    lon = lon.clamp(-180.0, 180.0);

    final result = Coordinates(lat: lat, lon: lon);
    final maxDist = _currentSpeed * 2.0;
    if (maxDist > 0 && result.distanceTo(last.position) > maxDist) {
      return _deadReckon(last, timeSinceLastPoint);
    }

    final bearingDelta =
        BearingSmoother.shortestAngleDelta(prev.bearing, last.bearing);
    final bearingRate = bearingDelta / dt;
    var bearing = (last.bearing + bearingRate * t) % 360;
    if (bearing < 0) bearing += 360;

    return _InterpolatedResult(
      position: result,
      bearing: bearing,
    );
  }

  double _routeBlendAlpha(double speedMs) {
    const minAlpha = 0.15;
    const maxAlpha = 0.40;
    const lowSpeed = 3.0;
    const highSpeed = 20.0;
    final t =
        ((speedMs - lowSpeed) / (highSpeed - lowSpeed)).clamp(0.0, 1.0);
    return minAlpha + (maxAlpha - minAlpha) * t;
  }

  _InterpolatedResult _deadReckon(
      _ControlPoint lastPoint, double timeSinceLastPoint) {
    final speed = lastPoint.speed;
    if (speed < 0.5) {
      return _InterpolatedResult(
        position: lastPoint.position,
        bearing: lastPoint.bearing,
      );
    }

    final t = timeSinceLastPoint.clamp(0.0, 2.0);
    final distance = speed * t;

    final maxDist = options.maxPredictDistanceMeters;
    final clampedDistance = distance.clamp(0.0, maxDist);

    if (clampedDistance < 0.1) {
      return _InterpolatedResult(
        position: lastPoint.position,
        bearing: lastPoint.bearing,
      );
    }

    final bearingRad = lastPoint.bearing * math.pi / 180;
    final dLat = clampedDistance * math.cos(bearingRad) / 111000;
    final dLon = clampedDistance *
        math.sin(bearingRad) /
        (111000 * math.cos(lastPoint.position.lat * math.pi / 180));

    final lat = (lastPoint.position.lat + dLat).clamp(-90.0, 90.0);
    final lon = (lastPoint.position.lon + dLon).clamp(-180.0, 180.0);

    return _InterpolatedResult(
      position: Coordinates(lat: lat, lon: lon),
      bearing: lastPoint.bearing,
    );
  }
}

/// Internal control point from a GPS fix.
class _ControlPoint {
  final Coordinates position;
  final double bearing;
  final double speed;
  final DateTime timestamp;

  const _ControlPoint({
    required this.position,
    required this.bearing,
    required this.speed,
    required this.timestamp,
  });
}

/// Internal interpolation result.
class _InterpolatedResult {
  final Coordinates position;
  final double bearing;

  const _InterpolatedResult({
    required this.position,
    required this.bearing,
  });
}
