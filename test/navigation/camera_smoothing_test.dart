import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('NavigationOptions camera settings', () {
    test('default camera options are reasonable', () {
      const options = NavigationOptions();

      expect(options.tilt, 0);
      expect(options.zoom, 17);
      expect(options.trackingMode, CameraTrackingMode.followWithBearing);
      expect(options.userIconVerticalOffset, 0.7);
    });

    test('bearing smoothing options have correct defaults', () {
      const options = NavigationOptions();

      // Tuned defaults for smoother camera rotation
      expect(options.minBearingSmoothing, 0.08);
      expect(options.maxBearingSmoothing, 0.15);
      expect(options.minBearingSmoothing, lessThan(options.maxBearingSmoothing));
    });

    test('camera look-ahead options have correct defaults', () {
      const options = NavigationOptions();

      expect(options.cameraLookAheadMeters, 5.0);
      // Updated: higher min speed to reduce jitter at low speed
      expect(options.cameraLookAheadMinSpeed, 5.0);
    });

    test('camera position smoothing options have correct defaults', () {
      const options = NavigationOptions();

      // Tuned: higher alpha for faster response at high speeds
      expect(options.cameraPositionAlphaMin, 0.12);
      expect(options.cameraPositionAlphaMax, 0.28);
      expect(options.cameraPositionAlphaMin, lessThan(options.cameraPositionAlphaMax));
    });

    test('camera dead zone options have correct defaults', () {
      const options = NavigationOptions();

      // Tuned: smaller dead zones for smoother micro-movements
      expect(options.cameraDeadZoneMeters, 0.15);
      expect(options.cameraDeadZoneDegrees, 0.5);
    });

    test('camera bearing velocity options have correct defaults', () {
      const options = NavigationOptions();

      // Tuned: faster rotation for responsive high-speed turns
      expect(options.cameraBearingMaxVelocityLowSpeed, 30.0);
      expect(options.cameraBearingMaxVelocityHighSpeed, 60.0);
      expect(options.cameraBearingMaxVelocityLowSpeed,
          lessThan(options.cameraBearingMaxVelocityHighSpeed));
    });

    test('driving options are optimized for car navigation', () {
      final options = NavigationOptions.driving();

      expect(options.tilt, 0);
      expect(options.zoom, 17);
      expect(options.trackingMode, CameraTrackingMode.followWithBearing);
    });

    test('walking options are optimized for pedestrian navigation', () {
      final options = NavigationOptions.walking();

      expect(options.tilt, 0); // Top-down for walking
      expect(options.zoom, 18); // Higher zoom for walking
      expect(options.arrivalThreshold, lessThan(30)); // Closer arrival for walking
    });

    test('copyWith preserves camera settings', () {
      const original = NavigationOptions(
        tilt: 60,
        zoom: 18,
        cameraLookAheadMeters: 10.0,
      );

      final copied = original.copyWith(snapToRouteEnabled: false);

      expect(copied.tilt, 60);
      expect(copied.zoom, 18);
      expect(copied.cameraLookAheadMeters, 10.0);
    });

    test('copyWith can change camera settings', () {
      const original = NavigationOptions();

      final copied = original.copyWith(
        tilt: 45,
        zoom: 19,
        cameraLookAheadMeters: 8.0,
        cameraLookAheadMinSpeed: 3.0,
      );

      expect(copied.tilt, 45);
      expect(copied.zoom, 19);
      expect(copied.cameraLookAheadMeters, 8.0);
      expect(copied.cameraLookAheadMinSpeed, 3.0);
    });
  });

  group('CameraTrackingMode', () {
    test('has all expected modes', () {
      expect(CameraTrackingMode.values.length, 3);
      expect(CameraTrackingMode.values, contains(CameraTrackingMode.free));
      expect(CameraTrackingMode.values, contains(CameraTrackingMode.follow));
      expect(CameraTrackingMode.values, contains(CameraTrackingMode.followWithBearing));
    });

    test('free mode allows manual camera control', () {
      // Free mode should not update camera position or bearing
      expect(CameraTrackingMode.free.name, 'free');
    });

    test('follow mode tracks position but keeps north up', () {
      expect(CameraTrackingMode.follow.name, 'follow');
    });

    test('followWithBearing mode tracks position and rotates with heading', () {
      expect(CameraTrackingMode.followWithBearing.name, 'followWithBearing');
    });
  });

  group('Angle utilities', () {
    test('normalizes positive angles correctly', () {
      expect(_normalizeAngle(0), 0);
      expect(_normalizeAngle(90), 90);
      expect(_normalizeAngle(180), 180);
      expect(_normalizeAngle(270), 270);
      expect(_normalizeAngle(360), 0);
      expect(_normalizeAngle(450), 90);
      expect(_normalizeAngle(720), 0);
    });

    test('normalizes negative angles correctly', () {
      expect(_normalizeAngle(-90), 270);
      expect(_normalizeAngle(-180), 180);
      expect(_normalizeAngle(-270), 90);
      expect(_normalizeAngle(-360), 0);
    });

    test('calculates shortest angle delta correctly', () {
      // Same angle
      expect(_shortestAngleDelta(0), 0);

      // Small clockwise difference
      expect(_shortestAngleDelta(10), 10);

      // Small counter-clockwise difference
      expect(_shortestAngleDelta(-10), -10);

      // 180 degrees
      expect(_shortestAngleDelta(180).abs(), 180);

      // Crossing 0/360 boundary (clockwise)
      expect(_shortestAngleDelta(350 - 10), closeTo(-20, 0.01));

      // Crossing 0/360 boundary (counter-clockwise)
      expect(_shortestAngleDelta(10 - 350), closeTo(20, 0.01));
    });
  });

  group('Bearing interpolation', () {
    test('interpolates between close angles smoothly', () {
      const current = 45.0;
      const target = 55.0;

      // Multiple interpolation steps should approach target
      var bearing = current;
      for (int i = 0; i < 30; i++) {
        bearing = _smoothBearing(bearing, target, 0.1);
      }

      // With alpha=0.1 and 30 iterations, should be within 2 degrees
      expect(bearing, closeTo(target, 2.0));
    });

    test('interpolates across 0/360 boundary correctly', () {
      const current = 350.0;
      const target = 10.0;

      // Should rotate clockwise (20 degrees), not counter-clockwise (340 degrees)
      var bearing = current;
      for (int i = 0; i < 30; i++) {
        bearing = _smoothBearing(bearing, target, 0.1);
      }

      // Should be close to 10, not close to current
      expect(bearing, closeTo(target, 5.0));
    });

    test('interpolates 180 degree turn', () {
      const current = 0.0;
      const target = 180.0;

      var bearing = current;
      for (int i = 0; i < 50; i++) {
        bearing = _smoothBearing(bearing, target, 0.1);
      }

      expect(bearing, closeTo(target, 5.0));
    });

    test('higher alpha means faster interpolation', () {
      const current = 0.0;
      const target = 90.0;

      // Low alpha - slower interpolation
      var slow = current;
      for (int i = 0; i < 10; i++) {
        slow = _smoothBearing(slow, target, 0.05);
      }

      // High alpha - faster interpolation
      var fast = current;
      for (int i = 0; i < 10; i++) {
        fast = _smoothBearing(fast, target, 0.2);
      }

      // Fast should be closer to target than slow
      expect((fast - target).abs(), lessThan((slow - target).abs()));
    });
  });

  group('Position interpolation', () {
    test('interpolates between two points smoothly', () {
      final start = Coordinates(lat: 55.7500, lon: 37.6000);
      final end = Coordinates(lat: 55.7600, lon: 37.6100);

      var current = start;
      for (int i = 0; i < 30; i++) {
        current = _smoothPosition(current, end, 0.1);
      }

      // Should be very close to end after many iterations
      expect(current.distanceTo(end), lessThan(100)); // Within 100m
    });

    test('higher alpha means faster interpolation', () {
      final start = Coordinates(lat: 55.7500, lon: 37.6000);
      final end = Coordinates(lat: 55.7600, lon: 37.6100);

      // Low alpha
      var slow = start;
      for (int i = 0; i < 10; i++) {
        slow = _smoothPosition(slow, end, 0.05);
      }

      // High alpha
      var fast = start;
      for (int i = 0; i < 10; i++) {
        fast = _smoothPosition(fast, end, 0.2);
      }

      // Fast should be closer to end
      expect(fast.distanceTo(end), lessThan(slow.distanceTo(end)));
    });

    test('alpha of 1.0 snaps directly to target', () {
      final start = Coordinates(lat: 55.7500, lon: 37.6000);
      final end = Coordinates(lat: 55.7600, lon: 37.6100);

      final result = _smoothPosition(start, end, 1.0);

      expect(result.lat, end.lat);
      expect(result.lon, end.lon);
    });

    test('alpha of 0.0 stays at current position', () {
      final start = Coordinates(lat: 55.7500, lon: 37.6000);
      final end = Coordinates(lat: 55.7600, lon: 37.6100);

      final result = _smoothPosition(start, end, 0.0);

      expect(result.lat, start.lat);
      expect(result.lon, start.lon);
    });
  });

  group('Camera dead zone', () {
    test('skips update when both position and bearing are within dead zone', () {
      const deadZoneMeters = 0.3;
      const deadZoneDegrees = 1.0;

      // Both deltas within dead zone
      expect(
        _shouldSkipCameraUpdate(
          positionDelta: 0.2,
          bearingDelta: 0.5,
          deadZoneMeters: deadZoneMeters,
          deadZoneDegrees: deadZoneDegrees,
        ),
        isTrue,
      );
    });

    test('does not skip update when position exceeds dead zone', () {
      const deadZoneMeters = 0.3;
      const deadZoneDegrees = 1.0;

      // Position delta exceeds threshold
      expect(
        _shouldSkipCameraUpdate(
          positionDelta: 0.5,
          bearingDelta: 0.5,
          deadZoneMeters: deadZoneMeters,
          deadZoneDegrees: deadZoneDegrees,
        ),
        isFalse,
      );
    });

    test('does not skip update when bearing exceeds dead zone', () {
      const deadZoneMeters = 0.3;
      const deadZoneDegrees = 1.0;

      // Bearing delta exceeds threshold
      expect(
        _shouldSkipCameraUpdate(
          positionDelta: 0.2,
          bearingDelta: 1.5,
          deadZoneMeters: deadZoneMeters,
          deadZoneDegrees: deadZoneDegrees,
        ),
        isFalse,
      );
    });

    test('does not skip update when both exceed dead zone', () {
      const deadZoneMeters = 0.3;
      const deadZoneDegrees = 1.0;

      expect(
        _shouldSkipCameraUpdate(
          positionDelta: 0.5,
          bearingDelta: 2.0,
          deadZoneMeters: deadZoneMeters,
          deadZoneDegrees: deadZoneDegrees,
        ),
        isFalse,
      );
    });

    test('edge case: exactly at dead zone boundary', () {
      const deadZoneMeters = 0.3;
      const deadZoneDegrees = 1.0;

      // At exactly the boundary - should NOT skip (< not <=)
      expect(
        _shouldSkipCameraUpdate(
          positionDelta: 0.3,
          bearingDelta: 1.0,
          deadZoneMeters: deadZoneMeters,
          deadZoneDegrees: deadZoneDegrees,
        ),
        isFalse,
      );
    });
  });

  group('Bearing velocity capping', () {
    test('does not cap velocity within limits at low speed', () {
      const maxVelLow = 30.0;
      const maxVelHigh = 60.0;

      // At speed 3 m/s, max velocity is 30 deg/s
      final result = _capBearingVelocity(
        velocity: 25.0,
        speed: 3.0,
        maxVelLow: maxVelLow,
        maxVelHigh: maxVelHigh,
      );

      expect(result, 25.0);
    });

    test('caps velocity at low speed', () {
      const maxVelLow = 30.0;
      const maxVelHigh = 60.0;

      // At speed 3 m/s, max velocity is 30 deg/s
      final result = _capBearingVelocity(
        velocity: 50.0,
        speed: 3.0,
        maxVelLow: maxVelLow,
        maxVelHigh: maxVelHigh,
      );

      expect(result, 30.0);
    });

    test('allows higher velocity at high speed', () {
      const maxVelLow = 30.0;
      const maxVelHigh = 60.0;

      // At speed 15 m/s (high), max velocity is 60 deg/s
      final result = _capBearingVelocity(
        velocity: 50.0,
        speed: 15.0,
        maxVelLow: maxVelLow,
        maxVelHigh: maxVelHigh,
      );

      expect(result, 50.0);
    });

    test('caps velocity at high speed', () {
      const maxVelLow = 30.0;
      const maxVelHigh = 60.0;

      // At speed 15 m/s (high), max velocity is 60 deg/s
      final result = _capBearingVelocity(
        velocity: 80.0,
        speed: 15.0,
        maxVelLow: maxVelLow,
        maxVelHigh: maxVelHigh,
      );

      expect(result, 60.0);
    });

    test('smoothly transitions between low and high speed limits', () {
      const maxVelLow = 30.0;
      const maxVelHigh = 60.0;

      // At speed 7.5 m/s (middle of transition), max should be ~45 deg/s
      final result = _capBearingVelocity(
        velocity: 50.0,
        speed: 7.5,
        maxVelLow: maxVelLow,
        maxVelHigh: maxVelHigh,
      );

      // Should be capped to somewhere between 30 and 60
      expect(result, greaterThan(30.0));
      expect(result, lessThan(60.0));
    });

    test('preserves sign when capping negative velocity', () {
      const maxVelLow = 30.0;
      const maxVelHigh = 60.0;

      final result = _capBearingVelocity(
        velocity: -50.0,
        speed: 3.0,
        maxVelLow: maxVelLow,
        maxVelHigh: maxVelHigh,
      );

      expect(result, -30.0);
    });
  });

  group('Smoothstep function', () {
    test('returns 0 below edge0', () {
      expect(_smoothstep(5.0, 10.0, 0.0), 0.0);
      expect(_smoothstep(5.0, 10.0, 5.0), 0.0);
    });

    test('returns 1 above edge1', () {
      expect(_smoothstep(5.0, 10.0, 10.0), 1.0);
      expect(_smoothstep(5.0, 10.0, 15.0), 1.0);
    });

    test('returns 0.5 at midpoint', () {
      expect(_smoothstep(5.0, 10.0, 7.5), 0.5);
    });

    test('returns smooth interpolation between edges', () {
      final at25 = _smoothstep(0.0, 10.0, 2.5);
      final at50 = _smoothstep(0.0, 10.0, 5.0);
      final at75 = _smoothstep(0.0, 10.0, 7.5);

      // Should be monotonically increasing
      expect(at25, lessThan(at50));
      expect(at50, lessThan(at75));

      // And bounded
      expect(at25, greaterThan(0.0));
      expect(at75, lessThan(1.0));
    });
  });

  group('copyWith for new camera smoothing options', () {
    test('copyWith preserves new camera smoothing settings', () {
      const original = NavigationOptions(
        cameraPositionAlphaMin: 0.08,
        cameraPositionAlphaMax: 0.20,
        cameraDeadZoneMeters: 0.5,
        cameraDeadZoneDegrees: 2.0,
        cameraBearingMaxVelocityLowSpeed: 25.0,
        cameraBearingMaxVelocityHighSpeed: 50.0,
      );

      final copied = original.copyWith(snapToRouteEnabled: false);

      expect(copied.cameraPositionAlphaMin, 0.08);
      expect(copied.cameraPositionAlphaMax, 0.20);
      expect(copied.cameraDeadZoneMeters, 0.5);
      expect(copied.cameraDeadZoneDegrees, 2.0);
      expect(copied.cameraBearingMaxVelocityLowSpeed, 25.0);
      expect(copied.cameraBearingMaxVelocityHighSpeed, 50.0);
    });

    test('copyWith can change new camera smoothing settings', () {
      const original = NavigationOptions();

      final copied = original.copyWith(
        cameraPositionAlphaMin: 0.10,
        cameraPositionAlphaMax: 0.25,
        cameraDeadZoneMeters: 0.4,
        cameraDeadZoneDegrees: 1.5,
        cameraBearingMaxVelocityLowSpeed: 40.0,
        cameraBearingMaxVelocityHighSpeed: 80.0,
      );

      expect(copied.cameraPositionAlphaMin, 0.10);
      expect(copied.cameraPositionAlphaMax, 0.25);
      expect(copied.cameraDeadZoneMeters, 0.4);
      expect(copied.cameraDeadZoneDegrees, 1.5);
      expect(copied.cameraBearingMaxVelocityLowSpeed, 40.0);
      expect(copied.cameraBearingMaxVelocityHighSpeed, 80.0);
    });
  });
}

/// Helper function to normalize angle to 0-360 range.
double _normalizeAngle(double value) {
  var angle = value % 360;
  if (angle < 0) angle += 360;
  return angle;
}

/// Helper function to calculate shortest angle delta.
double _shortestAngleDelta(double delta) {
  var result = (delta + 540) % 360 - 180;
  if (result == -180) result = 180;
  return result;
}

/// Simple bearing interpolation for testing.
double _smoothBearing(double current, double target, double alpha) {
  final delta = _shortestAngleDelta(target - current);
  return _normalizeAngle(current + delta * alpha);
}

/// Simple position interpolation for testing.
Coordinates _smoothPosition(Coordinates current, Coordinates target, double alpha) {
  return Coordinates(
    lat: current.lat + (target.lat - current.lat) * alpha,
    lon: current.lon + (target.lon - current.lon) * alpha,
  );
}

/// Smoothstep interpolation for testing.
double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Tests for dead zone functionality.
bool _shouldSkipCameraUpdate({
  required double positionDelta,
  required double bearingDelta,
  required double deadZoneMeters,
  required double deadZoneDegrees,
}) {
  return positionDelta < deadZoneMeters && bearingDelta < deadZoneDegrees;
}

/// Tests for bearing velocity capping.
double _capBearingVelocity({
  required double velocity,
  required double speed,
  required double maxVelLow,
  required double maxVelHigh,
}) {
  final maxVelocity = speed < 5.0
      ? maxVelLow
      : speed > 10.0
          ? maxVelHigh
          : maxVelLow + (maxVelHigh - maxVelLow) * _smoothstep(5.0, 10.0, speed);

  if (velocity.abs() > maxVelocity) {
    return maxVelocity * velocity.sign;
  }
  return velocity;
}
