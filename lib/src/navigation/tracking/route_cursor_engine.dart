import 'dart:math' as math;

import '../../models/coordinates.dart';
import '../navigation_logger.dart';
import '../navigation_options.dart';

/// Result of a cursor advance step.
class CursorPosition {
  /// Position on the route polyline.
  final Coordinates position;

  /// Bearing at this position (degrees 0-360).
  final double bearing;

  /// Segment index on the polyline.
  final int segmentIndex;

  /// Distance along route in meters.
  final double distanceAlongRoute;

  const CursorPosition({
    required this.position,
    required this.bearing,
    required this.segmentIndex,
    required this.distanceAlongRoute,
  });
}

/// Route-constrained cursor engine.
///
/// Maintains a `distanceAlongRoute` value (meters from route start).
/// GPS updates adjust the target distance; the cursor advances smoothly
/// along the polyline geometry at a controlled velocity.
///
/// Key behaviors:
/// - Cursor position is ALWAYS on the route polyline (when on-route).
/// - Cursor never moves backward — GPS backward jumps cause deceleration.
/// - Smooth acceleration/deceleration with configurable limits.
/// - Off-route detection with threshold.
class RouteCursorEngine {
  final NavigationOptions options;

  // Route geometry
  List<Coordinates> _polyline = [];
  final List<double> _cumulativeDistances = [];
  double _totalDistance = 0;

  // Cursor state
  double _distanceAlongRoute = 0;
  double _velocity = 0; // m/s, always >= 0
  double _targetVelocity = 0; // m/s from GPS speed
  double _gpsDistanceAlongRoute = 0; // where GPS projects on route

  // GPS state
  double _gpsDistanceFromRoute = 0;
  bool _isOnRoute = true;
  double _lastGpsSpeed = 0;

  // Deceleration flag — set when GPS projects behind cursor
  bool _isDecelerating = false;

  // Current output
  Coordinates? _currentPosition;
  double _currentBearing = 0;
  int _currentSegmentIndex = 0;

  // Turn detection state
  _UpcomingTurn? _upcomingTurn;

  // Logging throttle
  int _frameCount = 0;

  RouteCursorEngine({required this.options});

  // --- Public getters ---

  /// Current cursor distance along route in meters.
  double get distanceAlongRoute => _distanceAlongRoute;

  /// Total route distance in meters.
  double get totalDistance => _totalDistance;

  /// Current cursor position on route.
  Coordinates? get currentPosition => _currentPosition;

  /// Current bearing at cursor position (degrees 0-360).
  double get currentBearing => _currentBearing;

  /// Current segment index on polyline.
  int get currentSegmentIndex => _currentSegmentIndex;

  /// Whether GPS is within snap threshold of route.
  bool get isOnRoute => _isOnRoute;

  /// Distance from GPS to closest point on route (meters).
  double get gpsDistanceFromRoute => _gpsDistanceFromRoute;

  /// Current cursor velocity in m/s.
  double get velocity => _velocity;

  /// Whether cursor is decelerating (GPS behind cursor).
  bool get isDecelerating => _isDecelerating;

  /// Upcoming turn info (null if no turn within look-ahead distance).
  double? get upcomingTurnAngle => _upcomingTurn?.angle;

  /// Distance to next turn in meters (null if no turn within look-ahead).
  double? get distanceToNextTurn => _upcomingTurn?.distance;

  /// Whether cursor is approaching a turn.
  bool get isApproachingTurn => _upcomingTurn != null;

  /// Whether a route is loaded.
  bool get hasRoute => _polyline.length >= 2;

  // --- Route management ---

  /// Sets a new route polyline. Resets cursor to start.
  void setRoute(List<Coordinates> polyline) {
    _polyline = List.unmodifiable(polyline);
    _precomputeDistances();
    _distanceAlongRoute = 0;
    _velocity = 0;
    _targetVelocity = 0;
    _gpsDistanceAlongRoute = 0;
    _gpsDistanceFromRoute = 0;
    _isOnRoute = true;
    _isDecelerating = false;
    _currentPosition = polyline.isNotEmpty ? polyline.first : null;
    _currentBearing = polyline.length >= 2
        ? polyline[0].bearingTo(polyline[1])
        : 0;
    _currentSegmentIndex = 0;
    _upcomingTurn = null;
    _frameCount = 0;

    NavigationLogger.info('RouteCursorEngine', 'Route set', {
      'points': polyline.length,
      'totalDistance': _totalDistance.round(),
    });
  }

  /// Resets all state.
  void reset() {
    _polyline = [];
    _cumulativeDistances.clear();
    _totalDistance = 0;
    _distanceAlongRoute = 0;
    _velocity = 0;
    _targetVelocity = 0;
    _gpsDistanceAlongRoute = 0;
    _gpsDistanceFromRoute = 0;
    _isOnRoute = true;
    _isDecelerating = false;
    _lastGpsSpeed = 0;
    _currentPosition = null;
    _currentBearing = 0;
    _currentSegmentIndex = 0;
    _upcomingTurn = null;
    _frameCount = 0;

    NavigationLogger.info('RouteCursorEngine', 'Reset');
  }

  // --- GPS feed ---

  /// Feeds a GPS position update into the engine.
  ///
  /// [gpsPosition] raw GPS coordinates
  /// [speed] GPS speed in m/s
  void feedGps(Coordinates gpsPosition, double speed) {
    if (_polyline.length < 2) return;

    _lastGpsSpeed = speed;

    // Find closest point on route
    final closest = _findClosestPoint(gpsPosition);
    _gpsDistanceFromRoute = closest.distance;

    // Compute GPS distance along route
    _gpsDistanceAlongRoute = _distanceAtSegment(
      closest.segmentIndex,
      closest.point,
    );

    // Update on-route state
    final wasOnRoute = _isOnRoute;
    _isOnRoute = _gpsDistanceFromRoute <= options.snapToRouteThreshold;

    if (wasOnRoute && !_isOnRoute) {
      NavigationLogger.warn('RouteCursorEngine', 'Left route', {
        'distFromRoute': _gpsDistanceFromRoute.toStringAsFixed(1),
        'threshold': options.snapToRouteThreshold,
      });
    } else if (!wasOnRoute && _isOnRoute) {
      NavigationLogger.info('RouteCursorEngine', 'Returned to route', {
        'distFromRoute': _gpsDistanceFromRoute.toStringAsFixed(1),
      });
    }

    if (!_isOnRoute) {
      // Off-route: target velocity = 0, let cursor slow down
      _targetVelocity = 0;
      _isDecelerating = true;
      return;
    }

    // Check for backward GPS jump
    if (_gpsDistanceAlongRoute < _distanceAlongRoute) {
      final gap = _distanceAlongRoute - _gpsDistanceAlongRoute;

      // Small backward jump (< 5m): likely GPS noise, ignore
      if (gap < 5.0) {
        _targetVelocity = speed;
        _isDecelerating = false;
      } else {
        // Significant backward jump: decelerate to let GPS catch up
        _targetVelocity = 0;
        _isDecelerating = true;
        NavigationLogger.info('RouteCursorEngine', 'GPS backward jump', {
          'gap': gap.toStringAsFixed(1),
          'cursorDist': _distanceAlongRoute.toStringAsFixed(1),
          'gpsDist': _gpsDistanceAlongRoute.toStringAsFixed(1),
        });
      }
    } else {
      // GPS is ahead or at cursor position
      final gap = _gpsDistanceAlongRoute - _distanceAlongRoute;
      _isDecelerating = false;

      if (gap > 2.0) {
        // GPS significantly ahead: add catch-up factor
        // Catch-up proportional to gap: more gap = more boost
        final catchUpFactor = (gap / 10.0).clamp(0.0, 2.0);
        _targetVelocity = speed + speed * catchUpFactor;
      } else {
        // GPS close to cursor: normal speed
        _targetVelocity = speed;
      }
    }

    NavigationLogger.debug('RouteCursorEngine', 'GPS fed', {
      'distFromRoute': _gpsDistanceFromRoute.toStringAsFixed(1),
      'gpsDist': _gpsDistanceAlongRoute.toStringAsFixed(0),
      'cursorDist': _distanceAlongRoute.toStringAsFixed(0),
      'speed': speed.toStringAsFixed(1),
      'targetV': _targetVelocity.toStringAsFixed(1),
      'decel': _isDecelerating,
    });
  }

  // --- Frame advance ---

  /// Advances cursor along route by one frame.
  ///
  /// [dt] time since last frame.
  /// Returns [CursorPosition] with the new position, or null if no route.
  CursorPosition? advance(Duration dt) {
    if (_polyline.length < 2) return null;

    final dtSec = dt.inMicroseconds / 1e6;
    if (dtSec <= 0 || dtSec > 1.0) return _currentCursorPosition();

    _frameCount++;

    // --- Velocity control ---
    _updateVelocity(dtSec);

    // --- Advance distance ---
    _distanceAlongRoute += _velocity * dtSec;
    _distanceAlongRoute = _distanceAlongRoute.clamp(0.0, _totalDistance);

    // --- Micro-correction toward GPS ---
    // When cursor is behind GPS projection, blend to catch up.
    // Increased catch-up rate to reduce cursor lag after turns.
    if (_isOnRoute && !_isDecelerating) {
      final gap = _gpsDistanceAlongRoute - _distanceAlongRoute;
      if (gap > 0.05 && gap < 10.0) {
        // Progressive catch-up: faster when gap is larger
        // ~15% per frame for small gaps, ~30% for larger gaps
        final catchUpRate = 0.15 + (gap / 10.0) * 0.15;
        final correction = gap * catchUpRate * dtSec * 60;
        _distanceAlongRoute += correction.clamp(0.0, gap);
      }
    }

    // --- Project onto polyline ---
    final projected = _positionAtDistance(_distanceAlongRoute);
    _currentPosition = projected.position;
    _currentBearing = projected.bearing;
    _currentSegmentIndex = projected.segmentIndex;

    // --- Scan for upcoming turns ---
    _scanForUpcomingTurn();

    // Throttled logging (every 60th frame ≈ 1/sec)
    if (_frameCount % 60 == 0) {
      NavigationLogger.debug('RouteCursorEngine', 'Frame', {
        'dist': _distanceAlongRoute.toStringAsFixed(1),
        'v': _velocity.toStringAsFixed(1),
        'seg': _currentSegmentIndex,
        'bear': _currentBearing.toStringAsFixed(0),
        'turn': _upcomingTurn?.angle.toStringAsFixed(0),
      });
    }

    return _currentCursorPosition();
  }

  // --- Private: velocity ---

  void _updateVelocity(double dtSec) {
    // Acceleration/deceleration limits
    const maxAcceleration = 5.0; // m/s²
    const maxDeceleration = 4.0; // m/s²
    const velocitySmoothingTime = 0.3; // seconds

    double targetV = _targetVelocity;

    // Apply turn velocity reduction
    if (_upcomingTurn != null) {
      final turnFactor = _turnVelocityFactor(_upcomingTurn!);
      targetV *= turnFactor;
    }

    // Compute desired acceleration
    final diff = targetV - _velocity;
    final rawAccel = diff / velocitySmoothingTime;

    // Clamp acceleration
    double accel;
    if (rawAccel > 0) {
      accel = rawAccel.clamp(0.0, maxAcceleration);
    } else {
      accel = rawAccel.clamp(-maxDeceleration, 0.0);
    }

    // Update velocity
    _velocity = math.max(0.0, _velocity + accel * dtSec);

    // Hard clamp: never exceed 2x GPS speed (safety)
    final maxSpeed = math.max(_lastGpsSpeed * 2.5, 1.0);
    _velocity = _velocity.clamp(0.0, maxSpeed);
  }

  /// Computes velocity reduction factor for an upcoming turn.
  ///
  /// Returns 1.0 (no reduction) to 0.5 (maximum reduction for sharp turns).
  /// The minimum factor is increased to prevent excessive cursor lag during turns.
  double _turnVelocityFactor(_UpcomingTurn turn) {
    const slowdownDistance = 25.0; // meters before turn to start slowing (reduced from 30)
    if (turn.distance > slowdownDistance) return 1.0;

    // How close we are (0 = at turn, 1 = at slowdown start)
    final proximity = turn.distance / slowdownDistance;

    // Sharpness factor (0 = no turn, 1 = U-turn)
    final sharpness = (turn.angle.abs() / 180.0).clamp(0.0, 1.0);

    // Minimum velocity factor based on sharpness
    // Increased from 0.3-0.7 range to 0.5-0.8 range to reduce cursor lag
    final minFactor = 0.5 + 0.3 * (1.0 - sharpness); // 0.5 for U-turn, 0.8 for mild

    // Interpolate: full speed at slowdown distance, minimum at turn
    final factor = minFactor + (1.0 - minFactor) * proximity;

    NavigationLogger.debug('RouteCursorEngine', 'Turn velocity factor', {
      'angle': turn.angle.toStringAsFixed(0),
      'distance': turn.distance.toStringAsFixed(1),
      'sharpness': sharpness.toStringAsFixed(2),
      'factor': factor.toStringAsFixed(2),
    });

    return factor;
  }

  // --- Private: turn detection ---

  void _scanForUpcomingTurn() {
    const lookAheadMeters = 80.0;
    const angleThreshold = 30.0; // degrees

    if (_currentSegmentIndex >= _polyline.length - 2) {
      _upcomingTurn = null;
      return;
    }

    double distanceScanned = 0;
    final startSeg = _currentSegmentIndex;

    // Distance from cursor to end of current segment
    if (_currentPosition != null && startSeg + 1 < _polyline.length) {
      distanceScanned = _currentPosition!.distanceTo(_polyline[startSeg + 1]);
    }

    for (int i = startSeg + 1; i < _polyline.length - 1; i++) {
      if (distanceScanned > lookAheadMeters) break;

      final bearingBefore = _polyline[i - 1].bearingTo(_polyline[i]);
      final bearingAfter = _polyline[i].bearingTo(_polyline[i + 1]);
      final delta = _shortestAngleDelta(bearingBefore, bearingAfter);

      if (delta.abs() >= angleThreshold) {
        // Distance from cursor to this turn vertex
        double distToTurn = 0;
        if (_currentPosition != null) {
          distToTurn = _currentPosition!.distanceTo(_polyline[startSeg + 1]);
          for (int j = startSeg + 1; j < i; j++) {
            distToTurn += _polyline[j].distanceTo(_polyline[j + 1]);
          }
        }

        final oldTurn = _upcomingTurn;
        _upcomingTurn = _UpcomingTurn(
          angle: delta,
          distance: distToTurn,
          vertexIndex: i,
        );

        if (oldTurn == null || oldTurn.vertexIndex != i) {
          NavigationLogger.debug('RouteCursorEngine', 'Turn detected', {
            'angle': delta.toStringAsFixed(0),
            'distance': distToTurn.toStringAsFixed(0),
            'vertex': i,
          });
        }
        return;
      }

      distanceScanned += _polyline[i].distanceTo(_polyline[i + 1]);
    }

    _upcomingTurn = null;
  }

  // --- Private: geometry helpers ---

  void _precomputeDistances() {
    _cumulativeDistances.clear();
    double cumulative = 0;

    for (int i = 0; i < _polyline.length - 1; i++) {
      cumulative += _polyline[i].distanceTo(_polyline[i + 1]);
      _cumulativeDistances.add(cumulative);
    }

    _totalDistance = cumulative;
  }

  /// Computes the distance along route at a given segment and point.
  double _distanceAtSegment(int segmentIndex, Coordinates point) {
    double dist = segmentIndex > 0
        ? _cumulativeDistances[segmentIndex - 1]
        : 0;
    dist += _polyline[segmentIndex].distanceTo(point);
    return dist;
  }

  /// Projects a distance value onto the polyline.
  ///
  /// Returns position, bearing, and segment index.
  _ProjectedPoint _positionAtDistance(double distance) {
    if (_polyline.length < 2) {
      return _ProjectedPoint(
        position: _polyline.isNotEmpty
            ? _polyline.first
            : const Coordinates(lat: 0, lon: 0),
        bearing: 0,
        segmentIndex: 0,
      );
    }

    final clampedDist = distance.clamp(0.0, _totalDistance);

    // Binary search for the segment containing this distance
    int segIndex = _findSegmentForDistance(clampedDist);

    final segStart = _polyline[segIndex];
    final segEnd = _polyline[segIndex + 1];
    final segStartDist = segIndex > 0 ? _cumulativeDistances[segIndex - 1] : 0.0;
    final segLength = _polyline[segIndex].distanceTo(_polyline[segIndex + 1]);

    if (segLength < 0.001) {
      // Degenerate segment
      return _ProjectedPoint(
        position: segStart,
        bearing: segIndex + 2 < _polyline.length
            ? segEnd.bearingTo(_polyline[segIndex + 2])
            : _currentBearing,
        segmentIndex: segIndex,
      );
    }

    final t = ((clampedDist - segStartDist) / segLength).clamp(0.0, 1.0);

    final lat = segStart.lat + (segEnd.lat - segStart.lat) * t;
    final lon = segStart.lon + (segEnd.lon - segStart.lon) * t;

    return _ProjectedPoint(
      position: Coordinates(
        lat: lat.clamp(-90.0, 90.0),
        lon: lon.clamp(-180.0, 180.0),
      ),
      bearing: segStart.bearingTo(segEnd),
      segmentIndex: segIndex,
    );
  }

  /// Binary search for the segment that contains the given distance.
  int _findSegmentForDistance(double distance) {
    if (_cumulativeDistances.isEmpty) return 0;
    if (distance <= 0) return 0;
    if (distance >= _totalDistance) return _cumulativeDistances.length - 1;

    int lo = 0;
    int hi = _cumulativeDistances.length - 1;

    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_cumulativeDistances[mid] < distance) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }

    return lo;
  }

  /// Finds closest point on route to given position.
  _ClosestResult _findClosestPoint(Coordinates point) {
    // Windowed search around current segment for performance
    final windowSize = 20;
    final start = (_currentSegmentIndex - windowSize ~/ 2)
        .clamp(0, _polyline.length - 2);
    final end = (_currentSegmentIndex + windowSize)
        .clamp(0, _polyline.length - 1);

    double bestDist = double.infinity;
    int bestSeg = _currentSegmentIndex;
    Coordinates bestPoint = _polyline.isNotEmpty ? _polyline[0] : point;

    for (int i = start; i < end; i++) {
      final projected =
          _projectOntoSegment(point, _polyline[i], _polyline[i + 1]);
      final dist = point.distanceTo(projected);

      if (dist < bestDist) {
        bestDist = dist;
        bestSeg = i;
        bestPoint = projected;
      }
    }

    return _ClosestResult(
      point: bestPoint,
      segmentIndex: bestSeg,
      distance: bestDist,
    );
  }

  /// Projects a point onto a line segment.
  Coordinates _projectOntoSegment(
    Coordinates point,
    Coordinates segA,
    Coordinates segB,
  ) {
    final dx = segB.lon - segA.lon;
    final dy = segB.lat - segA.lat;

    if (dx == 0 && dy == 0) return segA;

    final t = ((point.lon - segA.lon) * dx + (point.lat - segA.lat) * dy) /
        (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0);

    return Coordinates(
      lat: (segA.lat + clamped * dy).clamp(-90.0, 90.0),
      lon: (segA.lon + clamped * dx).clamp(-180.0, 180.0),
    );
  }

  CursorPosition? _currentCursorPosition() {
    if (_currentPosition == null) return null;
    return CursorPosition(
      position: _currentPosition!,
      bearing: _currentBearing,
      segmentIndex: _currentSegmentIndex,
      distanceAlongRoute: _distanceAlongRoute,
    );
  }

  static double _shortestAngleDelta(double from, double to) {
    double delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }
}

/// Internal: upcoming turn info.
class _UpcomingTurn {
  final double angle; // degrees, signed
  final double distance; // meters to turn vertex
  final int vertexIndex; // polyline index of turn vertex

  const _UpcomingTurn({
    required this.angle,
    required this.distance,
    required this.vertexIndex,
  });
}

/// Internal: projected point on polyline.
class _ProjectedPoint {
  final Coordinates position;
  final double bearing;
  final int segmentIndex;

  const _ProjectedPoint({
    required this.position,
    required this.bearing,
    required this.segmentIndex,
  });
}

/// Internal: closest point search result.
class _ClosestResult {
  final Coordinates point;
  final int segmentIndex;
  final double distance;

  const _ClosestResult({
    required this.point,
    required this.segmentIndex,
    required this.distance,
  });
}
