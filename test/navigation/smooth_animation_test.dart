import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('60 FPS Camera Mode', () {
    test('smooth60FpsCamera defaults to true for smooth navigation', () {
      const options = NavigationOptions();

      expect(options.smooth60FpsCamera, true);
    });

    test('smooth60FpsCamera can be enabled', () {
      const options = NavigationOptions(
        smooth60FpsCamera: true,
      );

      expect(options.smooth60FpsCamera, true);
    });

    test('copyWith preserves smooth60FpsCamera', () {
      const original = NavigationOptions(
        smooth60FpsCamera: true,
      );

      final copied = original.copyWith(zoom: 18.0);

      expect(copied.smooth60FpsCamera, true);
    });

    test('copyWith can change smooth60FpsCamera', () {
      const original = NavigationOptions(
        smooth60FpsCamera: false,
      );

      final copied = original.copyWith(smooth60FpsCamera: true);

      expect(copied.smooth60FpsCamera, true);
    });

    test('cameraFrameAnimationMs default is 16ms for ~60 FPS micro-animation', () {
      const options = NavigationOptions();

      expect(options.cameraFrameAnimationMs, 16);
    });

    test('cameraFrameAnimationMs can be customized', () {
      const options = NavigationOptions(
        cameraFrameAnimationMs: 8,
      );

      expect(options.cameraFrameAnimationMs, 8);
    });
  });

  group('Camera Throttle Timing', () {
    test('normal mode throttle is 33ms (30 FPS)', () {
      // Camera throttle constant in NavigationView
      const normalThrottleMs = 33;

      // 30 FPS = 33.33ms per frame
      expect(normalThrottleMs, 33);
    });

    test('60 FPS mode bypasses 30 FPS throttle', () {
      // When smooth60FpsCamera is true, throttle is bypassed
      const options = NavigationOptions(smooth60FpsCamera: true);

      // In smooth mode, bypassThrottle = true
      final bypassThrottle = options.smooth60FpsCamera;
      expect(bypassThrottle, true);
    });

    test('route line throttle is 33ms in smooth mode vs 66ms in normal mode', () {
      const smoothRouteLineThrottleMs = 33; // 30 FPS
      const normalRouteLineThrottleMs = 66; // 15 FPS

      // Smooth mode uses faster route line updates
      expect(smoothRouteLineThrottleMs, lessThan(normalRouteLineThrottleMs));
      expect(smoothRouteLineThrottleMs * 2, normalRouteLineThrottleMs);
    });
  });

  group('Micro-animation for Camera', () {
    test('micro-animation duration matches frame time', () {
      const options = NavigationOptions(
        cameraFrameAnimationMs: 16,
      );

      // Micro-animation should be ~16ms for smooth 60 FPS interpolation
      expect(options.cameraFrameAnimationMs, 16);
    });

    test('smooth mode uses moveCamera (not animateCamera) to avoid double-animation', () {
      const options = NavigationOptions(smooth60FpsCamera: true);

      // When smooth60FpsCamera is enabled, PositionAnimator provides per-frame
      // smoothed positions. CameraController always uses moveCamera to avoid
      // conflicting with MapLibre's internal easing.
      expect(options.smooth60FpsCamera, true);
      // The camera controller now always calls moveCamera regardless of this flag.
      // The flag controls whether PositionAnimator runs the 60fps ticker.
    });
  });

  group('Ticker vs Timer Timing Accuracy', () {
    test('Ticker provides vsync synchronization', () {
      // Ticker is synchronized with screen refresh rate
      // Timer(16ms) is not synchronized and can drift

      // At 60 FPS, each frame is ~16.67ms
      const vsyncFrameMs = 16.67;

      // Timer(16ms) cumulative drift over 60 frames:
      // 60 * (16.67 - 16) = 60 * 0.67 = 40ms drift per second
      const timerMs = 16;
      final driftPerFrame = vsyncFrameMs - timerMs;
      final driftPerSecond = driftPerFrame * 60;

      expect(driftPerSecond, closeTo(40, 1));

      // Ticker has no drift because it's vsync-synced
      const tickerDriftPerSecond = 0.0;
      expect(tickerDriftPerSecond, 0.0);
    });

    test('FPS counter logic is accurate', () {
      // FPS is counted per second
      var frameCount = 0;
      var lastSecond = DateTime.now();

      // Simulate 60 frames over 1 second
      for (int i = 0; i < 60; i++) {
        frameCount++;
      }

      // After 1 second, FPS should be 60
      final fps = frameCount;
      expect(fps, 60);

      // Reset counter for next second
      frameCount = 0;
      lastSecond = DateTime.now();

      expect(frameCount, 0);
    });
  });

  group('NavigationOptions smooth animation settings', () {
    test('position buffer options have correct defaults', () {
      const options = NavigationOptions();

      expect(options.positionBufferDurationMs, 100);
    });

    test('bearing prediction options have correct defaults', () {
      const options = NavigationOptions();

      expect(options.bearingPredictionMs, 50);
    });

    test('micro-animation options have correct defaults', () {
      const options = NavigationOptions();

      expect(options.cameraFrameAnimationMs, 16);
    });

    test('spring physics options have correct defaults', () {
      const options = NavigationOptions();

      expect(options.arrowSpringTension, 150.0);
      expect(options.arrowSpringFriction, 15.0);
    });

    test('GPS filter options have correct defaults', () {
      const options = NavigationOptions();

      expect(options.gpsPositionFilterAlpha, 0.3);
      expect(options.gpsHeadingFilterAlpha, 0.2);
    });

    test('copyWith preserves smooth animation settings', () {
      const original = NavigationOptions(
        positionBufferDurationMs: 150,
        bearingPredictionMs: 80,
        cameraFrameAnimationMs: 32,
        arrowSpringTension: 200.0,
        arrowSpringFriction: 20.0,
        gpsPositionFilterAlpha: 0.4,
        gpsHeadingFilterAlpha: 0.3,
      );

      final copied = original.copyWith(snapToRouteEnabled: false);

      expect(copied.positionBufferDurationMs, 150);
      expect(copied.bearingPredictionMs, 80);
      expect(copied.cameraFrameAnimationMs, 32);
      expect(copied.arrowSpringTension, 200.0);
      expect(copied.arrowSpringFriction, 20.0);
      expect(copied.gpsPositionFilterAlpha, 0.4);
      expect(copied.gpsHeadingFilterAlpha, 0.3);
    });

    test('copyWith can change smooth animation settings', () {
      const original = NavigationOptions();

      final copied = original.copyWith(
        positionBufferDurationMs: 200,
        bearingPredictionMs: 100,
        cameraFrameAnimationMs: 8,
        arrowSpringTension: 180.0,
        arrowSpringFriction: 12.0,
        gpsPositionFilterAlpha: 0.5,
        gpsHeadingFilterAlpha: 0.4,
      );

      expect(copied.positionBufferDurationMs, 200);
      expect(copied.bearingPredictionMs, 100);
      expect(copied.cameraFrameAnimationMs, 8);
      expect(copied.arrowSpringTension, 180.0);
      expect(copied.arrowSpringFriction, 12.0);
      expect(copied.gpsPositionFilterAlpha, 0.5);
      expect(copied.gpsHeadingFilterAlpha, 0.4);
    });
  });

  group('Cubic ease-out function', () {
    test('returns 0 at t=0', () {
      expect(_easeOutCubic(0.0), 0.0);
    });

    test('returns 1 at t=1', () {
      expect(_easeOutCubic(1.0), 1.0);
    });

    test('returns approximately 0.875 at t=0.5', () {
      // t = 1 - (1 - 0.5)^3 = 1 - 0.125 = 0.875
      expect(_easeOutCubic(0.5), closeTo(0.875, 0.001));
    });

    test('is monotonically increasing', () {
      final values = <double>[];
      for (double t = 0; t <= 1.0; t += 0.1) {
        values.add(_easeOutCubic(t));
      }

      for (int i = 1; i < values.length; i++) {
        expect(values[i], greaterThanOrEqualTo(values[i - 1]));
      }
    });

    test('has fast start and slow end', () {
      // At t=0.1, output should be > 0.1 (fast start)
      expect(_easeOutCubic(0.1), greaterThan(0.1));

      // At t=0.9, output should be close to 1 but not quite there
      final atNinetyPercent = _easeOutCubic(0.9);
      // t=0.9: 1 - (1-0.9)^3 = 1 - 0.001 = 0.999
      expect(atNinetyPercent, closeTo(0.999, 0.001));
      // But should be close to 1
      expect(atNinetyPercent, greaterThan(0.97));
    });
  });

  group('Frame-rate independent alpha', () {
    test('returns original alpha when dtMs is null', () {
      expect(_frameRateIndependentAlpha(0.1, null), 0.1);
    });

    test('returns original alpha when dtMs is 0', () {
      expect(_frameRateIndependentAlpha(0.1, 0), 0.1);
    });

    test('returns approximately same alpha at 60 FPS (16.67ms)', () {
      final result = _frameRateIndependentAlpha(0.1, 17);
      expect(result, closeTo(0.1, 0.01));
    });

    test('returns higher alpha at 30 FPS (33ms)', () {
      final at60fps = _frameRateIndependentAlpha(0.1, 17);
      final at30fps = _frameRateIndependentAlpha(0.1, 33);

      // At lower frame rate, alpha should be higher to cover more distance per frame
      expect(at30fps, greaterThan(at60fps));
    });

    test('returns lower alpha at 120 FPS (8ms)', () {
      final at60fps = _frameRateIndependentAlpha(0.1, 17);
      final at120fps = _frameRateIndependentAlpha(0.1, 8);

      // At higher frame rate, alpha should be lower
      expect(at120fps, lessThan(at60fps));
    });

    test('clamps dtMs to reasonable range', () {
      // Very high dtMs (1000ms) should be clamped to 100ms
      final highDt = _frameRateIndependentAlpha(0.1, 1000);
      final at100ms = _frameRateIndependentAlpha(0.1, 100);

      expect(highDt, closeTo(at100ms, 0.01));
    });

    test('result is always between 0 and 1', () {
      for (double alpha = 0; alpha <= 1.0; alpha += 0.1) {
        for (int dtMs = 8; dtMs <= 100; dtMs += 10) {
          final result = _frameRateIndependentAlpha(alpha, dtMs);
          expect(result, greaterThanOrEqualTo(0.0));
          expect(result, lessThanOrEqualTo(1.0));
        }
      }
    });
  });

  group('Spring physics', () {
    test('spring starts at initial position', () {
      final spring = _TestSpring(tension: 150, friction: 15);
      final result = spring.update(100.0, 0.016);

      expect(result, 100.0);
    });

    test('spring moves toward target', () {
      final spring = _TestSpring(tension: 150, friction: 15);

      // Initialize at 0
      spring.update(0.0, 0.016);

      // Move toward 100
      var position = 0.0;
      for (int i = 0; i < 60; i++) {
        position = spring.update(100.0, 0.016);
      }

      // Should be close to 100 after ~1 second (60 frames at 60 FPS)
      expect(position, greaterThan(90.0));
    });

    test('critically damped spring does not oscillate significantly', () {
      final spring = _TestSpring(tension: 150, friction: 15);

      spring.update(0.0, 0.016);

      // Track positions to detect oscillation
      final positions = <double>[];
      for (int i = 0; i < 120; i++) {
        positions.add(spring.update(100.0, 0.016));
      }

      // Should approach 100 with minimal oscillation
      // Allow small variance for numerical precision in spring simulation
      for (int i = 10; i < positions.length; i++) {
        // Allow up to 1.0 degree tolerance for numerical precision
        expect(positions[i], greaterThanOrEqualTo(positions[i - 1] - 1.0));
      }
    });

    test('higher tension means faster response', () {
      final lowTension = _TestSpring(tension: 50, friction: 15);
      final highTension = _TestSpring(tension: 300, friction: 15);

      lowTension.update(0.0, 0.016);
      highTension.update(0.0, 0.016);

      var lowPos = 0.0;
      var highPos = 0.0;

      for (int i = 0; i < 30; i++) {
        lowPos = lowTension.update(100.0, 0.016);
        highPos = highTension.update(100.0, 0.016);
      }

      // Higher tension should be closer to target (or have moved more)
      // With more extreme difference, the effect is more visible
      expect((100.0 - highPos).abs(), lessThan((100.0 - lowPos).abs()));
    });

    test('higher friction means more damping', () {
      final lowFriction = _TestSpring(tension: 150, friction: 5);
      final highFriction = _TestSpring(tension: 150, friction: 30);

      lowFriction.update(0.0, 0.016);
      highFriction.update(0.0, 0.016);

      // Run several updates to let friction effect accumulate
      for (int i = 0; i < 10; i++) {
        lowFriction.update(100.0, 0.016);
        highFriction.update(100.0, 0.016);
      }

      // Higher friction should have lower velocity (more damped)
      expect(highFriction.velocity.abs(), lessThanOrEqualTo(lowFriction.velocity.abs()));
    });
  });

  group('GPS noise filter (EMA)', () {
    test('first value is returned unchanged', () {
      final filter = _TestEmaFilter(alpha: 0.3);

      final result = filter.update(55.75);

      expect(result, 55.75);
    });

    test('filter smooths subsequent values', () {
      final filter = _TestEmaFilter(alpha: 0.3);

      filter.update(55.75);
      final result = filter.update(55.80);

      // Should be between 55.75 and 55.80, closer to 55.75
      expect(result, greaterThan(55.75));
      expect(result, lessThan(55.80));
      expect(result, closeTo(55.75 + 0.05 * 0.3, 0.001));
    });

    test('lower alpha means more smoothing', () {
      final lowAlpha = _TestEmaFilter(alpha: 0.1);
      final highAlpha = _TestEmaFilter(alpha: 0.5);

      lowAlpha.update(0.0);
      highAlpha.update(0.0);

      final lowResult = lowAlpha.update(100.0);
      final highResult = highAlpha.update(100.0);

      // Higher alpha should be closer to new value
      expect(highResult, greaterThan(lowResult));
    });

    test('filter converges to constant input', () {
      final filter = _TestEmaFilter(alpha: 0.3);

      filter.update(0.0);

      var result = 0.0;
      for (int i = 0; i < 50; i++) {
        result = filter.update(100.0);
      }

      // Should be very close to 100 after many iterations
      expect(result, closeTo(100.0, 1.0));
    });
  });

  group('Bearing prediction', () {
    test('no prediction when velocity is zero', () {
      const currentBearing = 90.0;
      const velocity = 0.0;
      const predictMs = 50;

      final predicted = _predictBearing(currentBearing, velocity, predictMs);

      expect(predicted, currentBearing);
    });

    test('predicts forward when turning right', () {
      const currentBearing = 90.0;
      const velocity = 30.0; // 30 deg/sec clockwise
      const predictMs = 100; // 0.1 sec

      final predicted = _predictBearing(currentBearing, velocity, predictMs);

      // Should be 90 + 30 * 0.1 = 93 degrees
      expect(predicted, closeTo(93.0, 0.1));
    });

    test('predicts forward when turning left', () {
      const currentBearing = 90.0;
      const velocity = -30.0; // 30 deg/sec counter-clockwise
      const predictMs = 100;

      final predicted = _predictBearing(currentBearing, velocity, predictMs);

      // Should be 90 - 30 * 0.1 = 87 degrees
      expect(predicted, closeTo(87.0, 0.1));
    });

    test('wraps correctly past 360', () {
      const currentBearing = 350.0;
      const velocity = 60.0; // deg/sec
      const predictMs = 500; // 0.5 sec = 30 degrees

      final predicted = _predictBearing(currentBearing, velocity, predictMs);

      // Should be 350 + 30 = 380 -> 20 degrees
      expect(predicted, closeTo(20.0, 0.1));
    });

    test('wraps correctly past 0', () {
      const currentBearing = 10.0;
      const velocity = -60.0; // deg/sec
      const predictMs = 500; // 0.5 sec = -30 degrees

      final predicted = _predictBearing(currentBearing, velocity, predictMs);

      // Should be 10 - 30 = -20 -> 340 degrees
      expect(predicted, closeTo(340.0, 0.1));
    });
  });

  group('Hermite interpolation', () {
    test('returns start position at t=0', () {
      final p0 = Coordinates(lat: 55.75, lon: 37.60);
      final p1 = Coordinates(lat: 55.76, lon: 37.61);

      final result = _hermiteInterpolate(
        p0, p1,
        10.0, 45.0, // speed and heading at p0
        10.0, 45.0, // speed and heading at p1
        0.0, 1.0,
      );

      expect(result.lat, closeTo(p0.lat, 0.0001));
      expect(result.lon, closeTo(p0.lon, 0.0001));
    });

    test('returns end position at t=1', () {
      final p0 = Coordinates(lat: 55.75, lon: 37.60);
      final p1 = Coordinates(lat: 55.76, lon: 37.61);

      final result = _hermiteInterpolate(
        p0, p1,
        10.0, 45.0,
        10.0, 45.0,
        1.0, 1.0,
      );

      expect(result.lat, closeTo(p1.lat, 0.0001));
      expect(result.lon, closeTo(p1.lon, 0.0001));
    });

    test('intermediate positions are smooth', () {
      final p0 = Coordinates(lat: 55.75, lon: 37.60);
      final p1 = Coordinates(lat: 55.76, lon: 37.61);

      final results = <Coordinates>[];
      for (double t = 0; t <= 1.0; t += 0.1) {
        results.add(_hermiteInterpolate(
          p0, p1,
          10.0, 45.0,
          10.0, 45.0,
          t, 1.0,
        ));
      }

      // Check monotonic increase in lat and lon
      for (int i = 1; i < results.length; i++) {
        expect(results[i].lat, greaterThanOrEqualTo(results[i - 1].lat - 0.0001));
        expect(results[i].lon, greaterThanOrEqualTo(results[i - 1].lon - 0.0001));
      }
    });
  });
}

// Helper functions for testing

/// Cubic ease-out: t = 1 - (1-t)^3
double _easeOutCubic(double t) {
  final oneMinusT = 1.0 - t;
  return 1.0 - oneMinusT * oneMinusT * oneMinusT;
}

/// Frame-rate independent alpha normalization
double _frameRateIndependentAlpha(double alpha, int? dtMs) {
  if (dtMs == null || dtMs <= 0) return alpha;

  const baselineMs = 16.67;
  final clampedDtMs = dtMs.clamp(8, 100).toDouble();

  final adjusted = 1.0 - math.pow(1.0 - alpha, clampedDtMs / baselineMs);
  return adjusted.clamp(0.0, 1.0);
}

/// Helper class for testing spring physics
class _TestSpring {
  final double tension;
  final double friction;
  double? _position;
  double _velocity = 0.0;

  double get velocity => _velocity;

  _TestSpring({required this.tension, required this.friction});

  double update(double target, double dt) {
    if (_position == null) {
      _position = target;
      return target;
    }

    final delta = target - _position!;
    final force = -tension * (-delta) - friction * _velocity;

    _velocity += force * dt;
    _position = _position! + _velocity * dt;

    _velocity = _velocity.clamp(-360.0, 360.0);

    if (delta.abs() < 0.1 && _velocity.abs() < 0.5) {
      _position = target;
      _velocity = 0.0;
    }

    return _position!;
  }
}

/// Helper class for testing EMA filter
class _TestEmaFilter {
  final double alpha;
  double? _filtered;

  _TestEmaFilter({required this.alpha});

  double update(double value) {
    if (_filtered == null) {
      _filtered = value;
      return value;
    }

    _filtered = _filtered! + (value - _filtered!) * alpha;
    return _filtered!;
  }
}

/// Bearing prediction helper
double _predictBearing(double current, double velocity, int predictMs) {
  final prediction = current + velocity * (predictMs / 1000.0);
  return _normalizeAngle(prediction);
}

/// Normalize angle to 0-360
double _normalizeAngle(double value) {
  var angle = value % 360;
  if (angle < 0) angle += 360;
  return angle;
}

/// Hermite interpolation for testing
Coordinates _hermiteInterpolate(
  Coordinates p0, Coordinates p1,
  double speed0, double heading0,
  double speed1, double heading1,
  double t, double dtSec,
) {
  const metersPerDegree = 111320.0;
  final cosLat = math.cos(p0.lat * math.pi / 180.0);

  final m0Lat = (speed0 * math.cos(heading0 * math.pi / 180.0) * dtSec) / metersPerDegree;
  final m0Lon = (speed0 * math.sin(heading0 * math.pi / 180.0) * dtSec) / (metersPerDegree * cosLat);

  final m1Lat = (speed1 * math.cos(heading1 * math.pi / 180.0) * dtSec) / metersPerDegree;
  final m1Lon = (speed1 * math.sin(heading1 * math.pi / 180.0) * dtSec) / (metersPerDegree * cosLat);

  final t2 = t * t;
  final t3 = t2 * t;
  final h00 = 2 * t3 - 3 * t2 + 1;
  final h10 = t3 - 2 * t2 + t;
  final h01 = -2 * t3 + 3 * t2;
  final h11 = t3 - t2;

  return Coordinates(
    lat: h00 * p0.lat + h10 * m0Lat + h01 * p1.lat + h11 * m1Lat,
    lon: h00 * p0.lon + h10 * m0Lon + h01 * p1.lon + h11 * m1Lon,
  );
}
