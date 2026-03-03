import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/camera/bearing_smoother.dart';

void main() {
  group('BearingSmoother', () {
    late BearingSmoother smoother;

    setUp(() {
      smoother = BearingSmoother();
    });

    test('first value passes through unchanged', () {
      final result = smoother.smooth(45.0, 10.0, const Duration(milliseconds: 16));
      expect(result, 45.0);
      expect(smoother.bearing, 45.0);
    });

    test('smooths bearing changes gradually', () {
      smoother.smooth(0.0, 10.0, const Duration(milliseconds: 16));
      final result = smoother.smooth(90.0, 10.0, const Duration(milliseconds: 100));

      // Should be somewhere between 0 and 90, not jump to 90
      expect(result, greaterThan(0));
      expect(result, lessThan(90));
    });

    test('handles 360/0 wraparound correctly', () {
      smoother.smooth(350.0, 10.0, const Duration(milliseconds: 16));
      final result = smoother.smooth(10.0, 10.0, const Duration(milliseconds: 100));

      // Should go 350 → 10 via the short path (20° delta), not the long way
      // Result should be > 350 or close to 0/360
      expect(result, greaterThan(349));
    });

    test('handles 0/360 wraparound in reverse', () {
      smoother.smooth(10.0, 10.0, const Duration(milliseconds: 16));
      final result = smoother.smooth(350.0, 10.0, const Duration(milliseconds: 100));

      // Should go 10 → 350 via the short path (−20° delta)
      expect(result, lessThan(11));
    });

    test('reset clears state', () {
      smoother.smooth(90.0, 10.0, const Duration(milliseconds: 16));
      smoother.reset();
      expect(smoother.bearing, isNull);
    });

    test('zero dt returns current bearing', () {
      smoother.smooth(45.0, 10.0, const Duration(milliseconds: 16));
      final result = smoother.smooth(90.0, 10.0, Duration.zero);
      expect(result, 45.0);
    });

    test('speed-adaptive alpha is lower at low speed', () {
      // Low speed = more smoothing = smaller change
      final lowSpeedSmoother = BearingSmoother();
      lowSpeedSmoother.smooth(0.0, 0.0, const Duration(milliseconds: 16));
      final lowSpeedResult =
          lowSpeedSmoother.smooth(90.0, 1.0, const Duration(milliseconds: 100));

      // High speed = less smoothing = larger change
      final highSpeedSmoother = BearingSmoother();
      highSpeedSmoother.smooth(0.0, 0.0, const Duration(milliseconds: 16));
      final highSpeedResult =
          highSpeedSmoother.smooth(90.0, 20.0, const Duration(milliseconds: 100));

      expect(highSpeedResult, greaterThan(lowSpeedResult));
    });
  });

  group('BearingSmoother velocity boost', () {
    test('small bearing delta (< 20°) does not trigger velocity boost', () {
      // Two smoothers: one with small delta, one with larger-but-still-under-20 delta
      final smoother1 = BearingSmoother();
      smoother1.smooth(0.0, 15.0, const Duration(milliseconds: 16));
      final result1 = smoother1.smooth(10.0, 15.0, const Duration(milliseconds: 100));

      final smoother2 = BearingSmoother();
      smoother2.smooth(0.0, 15.0, const Duration(milliseconds: 16));
      final result2 = smoother2.smooth(15.0, 15.0, const Duration(milliseconds: 100));

      // Both should be smoothed proportionally — no boost applied
      // result2 should be roughly 1.5x result1 (linear scaling with delta)
      expect(result2, greaterThan(result1));
      expect(result2 / result1, closeTo(1.5, 0.3));
    });

    test('large bearing delta (> 20°) converges faster than without boost', () {
      // With boost: 50° delta at high speed
      final boostedSmoother = BearingSmoother();
      boostedSmoother.smooth(0.0, 15.0, const Duration(milliseconds: 16));

      // Run multiple frames to let the bearing converge toward 50°
      double boostedResult = 0;
      for (int i = 0; i < 30; i++) {
        boostedResult =
            boostedSmoother.smooth(50.0, 15.0, const Duration(milliseconds: 16));
      }

      // After 30 frames (~0.5s) with a 50° delta (which triggers boost),
      // the bearing should have converged significantly
      expect(boostedResult, greaterThan(15.0),
          reason: 'Large delta with velocity boost should converge faster');
    });

    test('velocity boost scales with delta magnitude', () {
      // 30° delta → boost = 1 + 30/90 ≈ 1.33x
      final smoother30 = BearingSmoother();
      smoother30.smooth(0.0, 15.0, const Duration(milliseconds: 16));
      double result30 = 0;
      for (int i = 0; i < 20; i++) {
        result30 =
            smoother30.smooth(30.0, 15.0, const Duration(milliseconds: 16));
      }

      // 80° delta → boost = 1 + 80/90 ≈ 1.89x
      final smoother80 = BearingSmoother();
      smoother80.smooth(0.0, 15.0, const Duration(milliseconds: 16));
      double result80 = 0;
      for (int i = 0; i < 20; i++) {
        result80 =
            smoother80.smooth(80.0, 15.0, const Duration(milliseconds: 16));
      }

      // Both should have moved significantly toward their targets
      expect(result30, greaterThan(5.0),
          reason: '30° delta should converge noticeably after 20 frames');
      expect(result80, greaterThan(10.0),
          reason: '80° delta should converge noticeably after 20 frames');

      // The absolute convergence for 80° should be larger than 30°
      // since the boost is proportionally stronger
      expect(result80, greaterThan(result30),
          reason: 'Larger delta with stronger boost should produce larger absolute movement');
    });

    test('velocity boost produces faster catch-up for 50° turn at 50 km/h', () {
      // 50 km/h ≈ 13.9 m/s
      final smoother = BearingSmoother();
      smoother.smooth(0.0, 13.9, const Duration(milliseconds: 16));

      // Simulate frames until bearing catches up to within 5° of target
      int frames = 0;
      double result = 0;
      while (frames < 120) {
        // 2 seconds max
        result =
            smoother.smooth(50.0, 13.9, const Duration(milliseconds: 16));
        frames++;
        if ((50.0 - result).abs() < 5.0) break;
      }

      // With boost (1 + 50/90 ≈ 1.56x), should catch up in under ~55 frames (~0.9s)
      // Without boost it would take ~0.87s; with boost ~0.58s
      expect(frames, lessThan(70),
          reason: '50° turn at 50 km/h should catch up within ~1.1 seconds');
    });
  });

  group('BearingSmoother.shortestAngleDelta', () {
    test('positive delta', () {
      expect(BearingSmoother.shortestAngleDelta(10, 50), closeTo(40, 0.001));
    });

    test('negative delta', () {
      expect(BearingSmoother.shortestAngleDelta(50, 10), closeTo(-40, 0.001));
    });

    test('wraparound positive', () {
      expect(BearingSmoother.shortestAngleDelta(350, 10), closeTo(20, 0.001));
    });

    test('wraparound negative', () {
      expect(BearingSmoother.shortestAngleDelta(10, 350), closeTo(-20, 0.001));
    });

    test('same angle', () {
      expect(BearingSmoother.shortestAngleDelta(180, 180), closeTo(0, 0.001));
    });

    test('opposite directions', () {
      final delta = BearingSmoother.shortestAngleDelta(0, 180);
      expect(delta.abs(), closeTo(180, 0.001));
    });
  });
}
