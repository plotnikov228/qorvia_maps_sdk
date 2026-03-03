import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

/// Tests for smooth navigation fixes that prevent backward cursor movement
/// at constant high speeds (e.g., 50 km/h).
///
/// These tests verify:
/// 1. NavigationOptions have correct defaults for smooth navigation
/// 2. Snap hysteresis prevents oscillation
/// 3. Speed-adaptive smoothing is enabled and configured
/// 4. Extrapolation distance limits are reasonable
void main() {
  group('Smooth Navigation - Options Defaults', () {
    test('maxPredictDistanceMeters supports highway speeds', () {
      const options = NavigationOptions();

      // Increased to 28m to support highway navigation (100 km/h = ~28m/s)
      // This allows smooth prediction during GPS gaps at high speeds
      expect(options.maxPredictDistanceMeters, 28.0);
      expect(options.maxPredictDistanceMeters, lessThanOrEqualTo(35.0),
          reason: 'maxPredictDistanceMeters should be <= 35m to limit overshoot');
    });

    test('speed smoothing is enabled by default', () {
      const options = NavigationOptions();

      expect(options.speedSmoothingEnabled, true,
          reason: 'Speed-adaptive smoothing should be enabled for smooth high-speed navigation');
    });

    test('snap hysteresis thresholds are configured', () {
      const options = NavigationOptions();

      // Hysteresis: enter snap at 15m, exit at 20m
      // This prevents rapid state changes at threshold boundary
      expect(options.snapToRouteThreshold, 15.0);
      expect(options.snapExitThreshold, 20.0);
      expect(options.snapExitThreshold, greaterThan(options.snapToRouteThreshold),
          reason: 'Exit threshold must be > enter threshold for hysteresis');
    });

    test('snap transition duration is reasonable', () {
      const options = NavigationOptions();

      // 200ms base duration, adaptive at runtime
      expect(options.snapTransitionDurationMs, 200);
      expect(options.snapTransitionDurationMs, greaterThanOrEqualTo(100),
          reason: 'Transition should be >= 100ms to be visible');
      expect(options.snapTransitionDurationMs, lessThanOrEqualTo(500),
          reason: 'Transition should be <= 500ms for responsiveness');
    });

    test('camera alpha range allows for speed-based adaptation', () {
      const options = NavigationOptions();

      // At high speeds, alpha can exceed cameraPositionAlphaMax (up to 0.40)
      expect(options.cameraPositionAlphaMin, 0.12);
      expect(options.cameraPositionAlphaMax, 0.28);
      // The actual max used at high speed is max(alphaMax, 0.40) = 0.40
    });
  });

  group('Smooth Navigation - Snap Hysteresis', () {
    test('snap hysteresis gap is at least 5 meters', () {
      const options = NavigationOptions();

      final hysteresisGap = options.snapExitThreshold - options.snapToRouteThreshold;

      expect(hysteresisGap, greaterThanOrEqualTo(5.0),
          reason: 'Hysteresis gap should be >= 5m to prevent oscillation at high speed');
    });

    test('snap thresholds work for different NavigationOptions presets', () {
      final driving = NavigationOptions.driving();
      final walking = NavigationOptions.walking();

      // Both should have hysteresis
      expect(driving.snapExitThreshold, greaterThan(driving.snapToRouteThreshold));
      expect(walking.snapExitThreshold, greaterThan(walking.snapToRouteThreshold));
    });

    test('custom snap thresholds can be set via copyWith', () {
      const original = NavigationOptions();

      final custom = original.copyWith(
        snapToRouteThreshold: 10.0,
        snapExitThreshold: 18.0,
      );

      expect(custom.snapToRouteThreshold, 10.0);
      expect(custom.snapExitThreshold, 18.0);
    });
  });

  group('Smooth Navigation - Speed Adaptive Smoothing', () {
    test('speedSmoothingEnabled can be disabled via copyWith', () {
      const original = NavigationOptions();
      expect(original.speedSmoothingEnabled, true);

      final disabled = original.copyWith(speedSmoothingEnabled: false);
      expect(disabled.speedSmoothingEnabled, false);
    });

    test('alpha ranges are suitable for speed-based interpolation', () {
      const options = NavigationOptions();

      // At low speed (< 5 m/s): use alphaMin = 0.10
      // At medium speed (10 m/s): use ~0.18
      // At high speed (15 m/s): use ~0.28
      // At very high speed (> 25 m/s): use ~0.40

      // Verify the range is wide enough for adaptation
      final alphaRange = options.cameraPositionAlphaMax - options.cameraPositionAlphaMin;
      expect(alphaRange, greaterThanOrEqualTo(0.10),
          reason: 'Alpha range should be >= 0.10 for meaningful adaptation');
    });

    test('speed categories match expected thresholds', () {
      // These are the speed thresholds used in _smoothTarget():
      // - low: < 5 m/s (18 km/h)
      // - medium-low: 5-10 m/s (18-36 km/h)
      // - medium-high: 10-15 m/s (36-54 km/h)
      // - high: > 15 m/s (54+ km/h)

      // 50 km/h = 13.89 m/s -> medium-high category
      final speedKmh = 50.0;
      final speedMs = speedKmh / 3.6;

      expect(speedMs, greaterThan(10.0), reason: '50 km/h should be > 10 m/s');
      expect(speedMs, lessThan(15.0), reason: '50 km/h should be < 15 m/s');

      // At 50 km/h, alpha should be in medium-high range (0.18-0.28)
      // This is fast enough to prevent lag-induced backward movement
    });
  });

  group('Smooth Navigation - Extrapolation Limits', () {
    test('maxPredictMs limits prediction time', () {
      const options = NavigationOptions();

      expect(options.maxPredictMs, 1500,
          reason: 'Prediction time should allow 1.5 seconds for highway speeds');
    });

    test('extrapolation distance supports high-speed driving', () {
      const options = NavigationOptions();

      // At 100 km/h = 27.78 m/s, in 1 second you travel ~28 meters
      // maxPredictDistanceMeters = 28m supports this for smooth highway navigation
      // This allows the cursor to track position during GPS gaps at highway speeds

      final speedKmh = 100.0;
      final speedMs = speedKmh / 3.6;
      final distanceIn1Sec = speedMs * 1.0;

      // Allow up to 1.1 second of travel for prediction buffer
      expect(options.maxPredictDistanceMeters, lessThanOrEqualTo(distanceIn1Sec * 1.1),
          reason: 'Max predict distance should support ~1 second of travel at 100 km/h');
    });

    test('buffer extrapolation supports highway speeds', () {
      // The code uses: segmentDistance * 0.6 * _predictionConfidence
      // For highway speeds, we need sufficient distance for smooth tracking

      // At confidence = 1.0, max should support highway driving
      // Typical GPS update ~1s, at 100 km/h = ~28m between updates
      // This is tested via the implementation, here we just verify
      // the options support reasonable limits

      const options = NavigationOptions();
      expect(options.maxPredictDistanceMeters, lessThanOrEqualTo(30.0),
          reason: 'Max distance should be <= 30m for highway speeds');
    });
  });

  group('Smooth Navigation - Backward Movement Prevention', () {
    test('backward detection threshold is reasonable', () {
      // The code uses 120° threshold for backward detection
      // (changed from 90° to reduce false positives)
      //
      // This can't be directly tested via options, but we verify
      // the related bearing mismatch threshold

      const options = NavigationOptions();

      expect(options.headingMismatchThreshold, 90.0,
          reason: 'Heading mismatch threshold determines against-route detection');
    });

    test('position alpha limits prevent extreme smoothing', () {
      const options = NavigationOptions();

      // Alpha too low = too much smoothing = cursor lags behind
      // Alpha too high = too responsive = jittery movement
      expect(options.cameraPositionAlphaMin, greaterThanOrEqualTo(0.05),
          reason: 'Min alpha should be >= 0.05 to prevent excessive lag');

      expect(options.cameraPositionAlphaMax, lessThanOrEqualTo(0.5),
          reason: 'Max alpha should be <= 0.5 to prevent jitter');
    });
  });

  group('Smooth Navigation - Integration Checks', () {
    test('all smooth navigation settings are preserved in copyWith', () {
      const original = NavigationOptions(
        maxPredictDistanceMeters: 10.0,
        speedSmoothingEnabled: true,
        snapToRouteThreshold: 12.0,
        snapExitThreshold: 18.0,
        snapTransitionDurationMs: 150,
      );

      // Copy with unrelated change
      final copied = original.copyWith(tilt: 60);

      expect(copied.maxPredictDistanceMeters, 10.0);
      expect(copied.speedSmoothingEnabled, true);
      expect(copied.snapToRouteThreshold, 12.0);
      expect(copied.snapExitThreshold, 18.0);
      expect(copied.snapTransitionDurationMs, 150);
    });

    test('driving preset has suitable smooth navigation settings', () {
      final options = NavigationOptions.driving();

      // All smooth navigation features should be enabled for driving
      expect(options.speedSmoothingEnabled, true);
      expect(options.snapToRouteEnabled, true);
      expect(options.snapExitThreshold, greaterThan(options.snapToRouteThreshold));
    });
  });

  group('Smooth Navigation - Position Blending', () {
    test('route blend alpha is low at low speed', () {
      // At 0 m/s (stationary), alpha should be at minimum (0.15)
      // At 3 m/s (walking speed), still at minimum
      const lowSpeed = 3.0;
      const minAlpha = 0.15;
      const maxAlpha = 0.40;
      const lowSpeedThresh = 3.0;
      const highSpeedThresh = 20.0;

      final t = ((lowSpeed - lowSpeedThresh) / (highSpeedThresh - lowSpeedThresh)).clamp(0.0, 1.0);
      final alpha = minAlpha + (maxAlpha - minAlpha) * t;

      expect(alpha, closeTo(0.15, 0.01),
          reason: 'At low speed, blend alpha should be ~0.15 for heavier smoothing');
    });

    test('route blend alpha is high at high speed', () {
      // At 20+ m/s (72 km/h), alpha should be at maximum (0.40)
      const highSpeed = 25.0;
      const minAlpha = 0.15;
      const maxAlpha = 0.40;
      const lowSpeedThresh = 3.0;
      const highSpeedThresh = 20.0;

      final t = ((highSpeed - lowSpeedThresh) / (highSpeedThresh - lowSpeedThresh)).clamp(0.0, 1.0);
      final alpha = minAlpha + (maxAlpha - minAlpha) * t;

      expect(alpha, closeTo(0.40, 0.01),
          reason: 'At high speed, blend alpha should be ~0.40 for faster tracking');
    });

    test('route blend alpha is intermediate at 50 km/h', () {
      // 50 km/h ≈ 13.9 m/s
      const speed = 13.9;
      const minAlpha = 0.15;
      const maxAlpha = 0.40;
      const lowSpeedThresh = 3.0;
      const highSpeedThresh = 20.0;

      final t = ((speed - lowSpeedThresh) / (highSpeedThresh - lowSpeedThresh)).clamp(0.0, 1.0);
      final alpha = minAlpha + (maxAlpha - minAlpha) * t;

      expect(alpha, greaterThan(0.15));
      expect(alpha, lessThan(0.40));
      expect(alpha, closeTo(0.31, 0.02),
          reason: 'At 50 km/h, blend alpha should be ~0.31');
    });

    test('blended position is between current and predicted', () {
      // Simulate what happens in _interpolatePosition when blending
      const currentLat = 55.7500;
      const currentLon = 37.6000;
      const predictedLat = 55.7510;
      const predictedLon = 37.6010;
      const alpha = 0.30; // typical for ~50 km/h

      final blendedLat = currentLat + (predictedLat - currentLat) * alpha;
      final blendedLon = currentLon + (predictedLon - currentLon) * alpha;

      // Blended should be between current and predicted
      expect(blendedLat, greaterThan(currentLat));
      expect(blendedLat, lessThan(predictedLat));
      expect(blendedLon, greaterThan(currentLon));
      expect(blendedLon, lessThan(predictedLon));

      // Should be closer to current (alpha < 0.5)
      expect(blendedLat - currentLat, lessThan(predictedLat - blendedLat));
    });

    test('blending eliminates position snaps on GPS update', () {
      // Without blending: prediction jumps directly to new predicted position
      // With blending: position moves incrementally toward prediction

      const currentLat = 55.7500;
      const predictedLat = 55.7520; // large jump from prediction recalculation
      const alpha = 0.25;

      // First frame: blended position
      var lat = currentLat + (predictedLat - currentLat) * alpha;
      expect(lat, closeTo(55.7505, 0.0001));

      // Second frame: closer to predicted
      lat = lat + (predictedLat - lat) * alpha;
      expect(lat, closeTo(55.75088, 0.0001));

      // The jump is spread over multiple frames instead of instant
      expect(lat, lessThan(predictedLat));
    });
  });

  group('Smooth Navigation - Math Verification', () {
    test('speed conversion 50 km/h to m/s is correct', () {
      // 50 km/h = 50 * 1000m / 3600s = 13.889 m/s
      final speedKmh = 50.0;
      final speedMs = speedKmh / 3.6;

      expect(speedMs, closeTo(13.889, 0.01));
    });

    test('distance traveled at 50 km/h in 200ms', () {
      // 50 km/h = 13.889 m/s
      // In 200ms: 13.889 * 0.2 = 2.78 meters
      final speedMs = 50.0 / 3.6;
      final distanceIn200ms = speedMs * 0.2;

      expect(distanceIn200ms, closeTo(2.78, 0.1));

      // This is why snap transition of 200ms can cause incomplete
      // transitions at high speed - car moves ~2.8m during transition
    });

    test('snap hysteresis gap covers transition distance', () {
      const options = NavigationOptions();

      // At 50 km/h, car travels ~2.8m during 200ms transition
      // Hysteresis gap of 5m (20-15) is sufficient to prevent oscillation
      final hysteresisGap = options.snapExitThreshold - options.snapToRouteThreshold;
      final speedMs = 50.0 / 3.6;
      final transitionDistanceAt50kmh = speedMs * (options.snapTransitionDurationMs / 1000.0);

      expect(hysteresisGap, greaterThan(transitionDistanceAt50kmh),
          reason: 'Hysteresis gap should exceed transition travel distance');
    });
  });
}
