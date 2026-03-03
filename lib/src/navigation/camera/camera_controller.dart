import 'dart:async';
import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/coordinates.dart';
import '../navigation_logger.dart';
import '../navigation_options.dart';
import 'bearing_smoother.dart';

/// Manages camera state, smooth transitions, and tracking modes.
///
/// Responsibilities:
/// - Camera tracking modes (free, follow, followWithBearing)
/// - Smooth camera movement with dead zone filtering
/// - Look-ahead offset in direction of travel
/// - Auto-recenter timer when user pans away
class CameraController {
  MaplibreMapController? _mapController;
  final NavigationOptions options;

  // Camera state
  Coordinates? _lastCameraPosition;
  double? _lastCameraBearing;

  // Configuration extracted from options
  final double _deadZoneMeters;
  final double _deadZoneDegrees;
  final double _lookAheadMeters;
  final double _lookAheadMinSpeed;
  final double _tilt;
  final double _zoom;

  CameraController({
    required this.options,
  })  : _deadZoneMeters = options.cameraDeadZoneMeters,
        _deadZoneDegrees = options.cameraDeadZoneDegrees,
        _lookAheadMeters = options.cameraLookAheadMeters,
        _lookAheadMinSpeed = options.cameraLookAheadMinSpeed,
        _tilt = options.tilt,
        _zoom = options.zoom;

  /// Attaches the MapLibre controller.
  void attach(MaplibreMapController controller) {
    _mapController = controller;
    NavigationLogger.info('CameraController', 'Map controller attached');
  }

  /// Detaches the MapLibre controller.
  void detach() {
    _mapController = null;
  }

  /// Updates camera to follow the given position and bearing.
  ///
  /// [position] target position
  /// [bearing] target bearing in degrees (0-360)
  /// [speedMs] current speed (for look-ahead and adaptive behavior)
  /// [trackingMode] current tracking mode
  Future<void> updateCamera({
    required Coordinates position,
    required double bearing,
    required double speedMs,
    required CameraTrackingMode trackingMode,
  }) async {
    if (_mapController == null) return;
    if (trackingMode == CameraTrackingMode.free) return;

    // Apply look-ahead offset
    final target = _applyLookAhead(position, bearing, speedMs);

    // Dead zone filtering
    if (_lastCameraPosition != null && _lastCameraBearing != null) {
      final positionDelta = _lastCameraPosition!.distanceTo(target);
      final bearingDelta =
          BearingSmoother.shortestAngleDelta(_lastCameraBearing!, bearing).abs();

      if (positionDelta < _deadZoneMeters &&
          bearingDelta < _deadZoneDegrees) {
        NavigationLogger.debug('CameraController', 'Dead zone skip', {
          'posDelta': positionDelta,
          'bearDelta': bearingDelta,
        });
        return;
      }
    }

    // Determine camera bearing
    final cameraBearing =
        trackingMode == CameraTrackingMode.followWithBearing ? bearing : 0.0;

    // Move camera
    final cameraUpdate = CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(target.lat, target.lon),
        zoom: _zoom,
        bearing: cameraBearing,
        tilt: _tilt,
      ),
    );

    try {
      // Always use moveCamera — PositionAnimator already provides smoothed
      // per-frame positions. Using animateCamera in 60fps mode causes
      // double-animation conflicts where MapLibre's internal easing gets
      // cancelled each frame, producing micro-stuttering.
      await _mapController!.moveCamera(cameraUpdate);

      _lastCameraPosition = target;
      _lastCameraBearing = cameraBearing;

      NavigationLogger.debug('CameraController', 'Camera updated', {
        'lat': target.lat,
        'lon': target.lon,
        'bearing': cameraBearing,
        'zoom': _zoom,
      });
    } catch (e) {
      NavigationLogger.error('CameraController', 'Camera update failed', e);
    }
  }

  /// Sets initial camera position without animation.
  Future<void> setInitialPosition(Coordinates position, double bearing) async {
    if (_mapController == null) return;

    try {
      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.lat, position.lon),
            zoom: _zoom,
            bearing: bearing,
            tilt: _tilt,
          ),
        ),
      );
      _lastCameraPosition = position;
      _lastCameraBearing = bearing;
      NavigationLogger.info(
          'CameraController', 'Initial camera position set', {
        'lat': position.lat,
        'lon': position.lon,
      });
    } catch (e) {
      NavigationLogger.error(
          'CameraController', 'Failed to set initial position', e);
    }
  }

  /// Animates camera smoothly to a target position.
  ///
  /// Used for recenter after free mode — provides a smooth transition
  /// back to follow mode instead of an abrupt jump.
  Future<void> animateToPosition({
    required Coordinates position,
    required double bearing,
    Duration duration = const Duration(milliseconds: 500),
  }) async {
    if (_mapController == null) return;

    try {
      final cameraUpdate = CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.lat, position.lon),
          zoom: _zoom,
          bearing: bearing,
          tilt: _tilt,
        ),
      );

      await _mapController!.animateCamera(
        cameraUpdate,
        duration: duration,
      );

      _lastCameraPosition = position;
      _lastCameraBearing = bearing;

      NavigationLogger.info('CameraController', 'Animated to position', {
        'lat': position.lat,
        'lon': position.lon,
        'bearing': bearing,
        'durationMs': duration.inMilliseconds,
      });
    } catch (e) {
      NavigationLogger.error(
          'CameraController', 'Animate to position failed', e);
    }
  }

  /// Resets camera state (e.g., after reroute).
  void reset() {
    _lastCameraPosition = null;
    _lastCameraBearing = null;
  }

  /// Applies look-ahead offset in direction of travel.
  Coordinates _applyLookAhead(
      Coordinates position, double bearing, double speedMs) {
    if (_lookAheadMeters <= 0 || speedMs < _lookAheadMinSpeed) {
      return position;
    }

    // Smoothstep between minSpeed and minSpeed * 2
    final speedFactor =
        ((speedMs - _lookAheadMinSpeed) / _lookAheadMinSpeed).clamp(0.0, 1.0);
    final lookAhead = _lookAheadMeters * speedFactor;

    if (lookAhead < 0.1) return position;

    // Convert bearing to radians and offset position
    final bearingRad = bearing * math.pi / 180;
    // Approximate: 1 degree latitude ≈ 111000m
    final dLat = lookAhead * math.cos(bearingRad) / 111000;
    final dLon = lookAhead *
        math.sin(bearingRad) /
        (111000 * math.cos(position.lat * math.pi / 180));

    return Coordinates(
      lat: (position.lat + dLat).clamp(-90.0, 90.0),
      lon: (position.lon + dLon).clamp(-180.0, 180.0),
    );
  }

  /// Disposes resources.
  void dispose() {
    _mapController = null;
  }
}
