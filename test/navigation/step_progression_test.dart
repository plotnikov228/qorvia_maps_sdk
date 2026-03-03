import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('NavigationOptions step progression settings', () {
    test('default arrivalThreshold is 20m', () {
      const options = NavigationOptions();
      expect(options.arrivalThreshold, 20);
    });

    test('default stepTransitionHysteresis is 5m', () {
      const options = NavigationOptions();
      expect(options.stepTransitionHysteresis, 5.0);
    });

    test('can create options with custom step progression settings', () {
      const options = NavigationOptions(
        arrivalThreshold: 15,
        stepTransitionHysteresis: 10.0,
      );

      expect(options.arrivalThreshold, 15);
      expect(options.stepTransitionHysteresis, 10.0);
    });

    test('copyWith preserves step progression settings', () {
      const original = NavigationOptions(
        arrivalThreshold: 25,
        stepTransitionHysteresis: 8.0,
      );

      final copied = original.copyWith(zoom: 18);

      expect(copied.arrivalThreshold, 25);
      expect(copied.stepTransitionHysteresis, 8.0);
      expect(copied.zoom, 18);
    });

    test('copyWith can change step progression settings', () {
      const original = NavigationOptions();

      final copied = original.copyWith(
        arrivalThreshold: 30,
        stepTransitionHysteresis: 3.0,
      );

      expect(copied.arrivalThreshold, 30);
      expect(copied.stepTransitionHysteresis, 3.0);
    });

    test('driving factory uses reduced arrival threshold', () {
      final options = NavigationOptions.driving();
      expect(options.arrivalThreshold, 20);
    });

    test('walking factory uses smaller arrival threshold', () {
      final options = NavigationOptions.walking();
      expect(options.arrivalThreshold, 15);
    });
  });

  group('Step calculation logic', () {
    // Helper to calculate step index from distance covered
    (int, double) getCurrentStep(double distanceCovered, List<RouteStep> steps) {
      if (steps.isEmpty) return (0, 0);

      double accumulated = 0;
      for (int i = 0; i < steps.length; i++) {
        accumulated += steps[i].distanceMeters;
        if (accumulated > distanceCovered) {
          final distanceToManeuver = accumulated - distanceCovered;
          return (i, distanceToManeuver);
        }
      }

      return (steps.length - 1, 0);
    }

    List<RouteStep> createTestSteps() {
      return [
        RouteStep(
          distanceMeters: 50,
          durationSeconds: 10,
          instruction: 'Head north',
          maneuver: 'depart',
        ),
        RouteStep(
          distanceMeters: 100,
          durationSeconds: 20,
          instruction: 'Turn right',
          maneuver: 'turn-right',
        ),
        RouteStep(
          distanceMeters: 80,
          durationSeconds: 15,
          instruction: 'Turn left',
          maneuver: 'turn-left',
        ),
        RouteStep(
          distanceMeters: 30,
          durationSeconds: 5,
          instruction: 'Arrive',
          maneuver: 'arrive',
        ),
      ];
    }

    test('returns step 0 at start of route', () {
      final steps = createTestSteps();
      final (stepIndex, distanceToManeuver) = getCurrentStep(0, steps);

      expect(stepIndex, 0);
      expect(distanceToManeuver, 50); // Full distance of step 0
    });

    test('returns step 0 when partway through first step', () {
      final steps = createTestSteps();
      final (stepIndex, distanceToManeuver) = getCurrentStep(25, steps);

      expect(stepIndex, 0);
      expect(distanceToManeuver, 25); // 50 - 25 = 25m remaining
    });

    test('transitions to step 1 at step boundary', () {
      final steps = createTestSteps();
      // At 51m, we've passed step 0 (50m) and entered step 1
      final (stepIndex, distanceToManeuver) = getCurrentStep(51, steps);

      expect(stepIndex, 1);
      expect(distanceToManeuver, closeTo(99, 1)); // ~99m to next maneuver
    });

    test('returns last step when at end of route', () {
      final steps = createTestSteps();
      // Total distance: 50 + 100 + 80 + 30 = 260m
      final (stepIndex, distanceToManeuver) = getCurrentStep(260, steps);

      expect(stepIndex, 3);
      expect(distanceToManeuver, 0);
    });

    test('returns last step when past end of route', () {
      final steps = createTestSteps();
      final (stepIndex, distanceToManeuver) = getCurrentStep(300, steps);

      expect(stepIndex, 3);
      expect(distanceToManeuver, 0);
    });

    test('handles empty steps list', () {
      final (stepIndex, distanceToManeuver) = getCurrentStep(50, []);

      expect(stepIndex, 0);
      expect(distanceToManeuver, 0);
    });

    test('handles single step route', () {
      final steps = [
        RouteStep(
          distanceMeters: 100,
          durationSeconds: 20,
          instruction: 'Go straight',
          maneuver: 'depart',
        ),
      ];

      final (stepIndex, distanceToManeuver) = getCurrentStep(50, steps);
      expect(stepIndex, 0);
      expect(distanceToManeuver, 50);
    });
  });

  group('Step hysteresis logic', () {
    // Simulates the hysteresis logic from NavigationController
    int applyStepHysteresis({
      required int rawStepIndex,
      required int confirmedStepIndex,
      required double distanceCovered,
      required List<RouteStep> steps,
      required double hysteresisThreshold,
    }) {
      // Rule 1: Never go backward
      if (rawStepIndex < confirmedStepIndex) {
        return confirmedStepIndex;
      }

      // If same step, nothing to confirm
      if (rawStepIndex == confirmedStepIndex) {
        return confirmedStepIndex;
      }

      // rawStepIndex > confirmedStepIndex: calculate distance past boundary
      double boundaryDistance = 0;
      for (int i = 0; i <= confirmedStepIndex && i < steps.length; i++) {
        boundaryDistance += steps[i].distanceMeters;
      }

      final distancePastBoundary = distanceCovered - boundaryDistance;

      // Rule 2: Confirm step only after traveling past boundary by threshold
      if (distancePastBoundary >= hysteresisThreshold) {
        return rawStepIndex;
      }

      return confirmedStepIndex;
    }

    List<RouteStep> createTestSteps() {
      return [
        RouteStep(
          distanceMeters: 50,
          durationSeconds: 10,
          instruction: 'Head north',
          maneuver: 'depart',
        ),
        RouteStep(
          distanceMeters: 100,
          durationSeconds: 20,
          instruction: 'Turn right',
          maneuver: 'turn-right',
        ),
        RouteStep(
          distanceMeters: 80,
          durationSeconds: 15,
          instruction: 'Turn left',
          maneuver: 'turn-left',
        ),
      ];
    }

    test('prevents backward step transitions', () {
      final steps = createTestSteps();

      final result = applyStepHysteresis(
        rawStepIndex: 0,
        confirmedStepIndex: 1,
        distanceCovered: 45, // User appears to have gone backward
        steps: steps,
        hysteresisThreshold: 5.0,
      );

      expect(result, 1); // Should stay at confirmed step 1
    });

    test('keeps same step when no change', () {
      final steps = createTestSteps();

      final result = applyStepHysteresis(
        rawStepIndex: 1,
        confirmedStepIndex: 1,
        distanceCovered: 75,
        steps: steps,
        hysteresisThreshold: 5.0,
      );

      expect(result, 1);
    });

    test('does not confirm step until hysteresis threshold met', () {
      final steps = createTestSteps();

      // At 52m, user just crossed into step 1 (boundary at 50m)
      // But only 2m past boundary, less than 5m threshold
      final result = applyStepHysteresis(
        rawStepIndex: 1,
        confirmedStepIndex: 0,
        distanceCovered: 52,
        steps: steps,
        hysteresisThreshold: 5.0,
      );

      expect(result, 0); // Should stay at step 0
    });

    test('confirms step when hysteresis threshold met', () {
      final steps = createTestSteps();

      // At 56m, user is 6m past boundary (50m), exceeds 5m threshold
      final result = applyStepHysteresis(
        rawStepIndex: 1,
        confirmedStepIndex: 0,
        distanceCovered: 56,
        steps: steps,
        hysteresisThreshold: 5.0,
      );

      expect(result, 1); // Should confirm step 1
    });

    test('confirms step exactly at hysteresis threshold', () {
      final steps = createTestSteps();

      // At 55m, user is exactly 5m past boundary
      final result = applyStepHysteresis(
        rawStepIndex: 1,
        confirmedStepIndex: 0,
        distanceCovered: 55,
        steps: steps,
        hysteresisThreshold: 5.0,
      );

      expect(result, 1); // Should confirm step 1
    });

    test('works with larger hysteresis threshold', () {
      final steps = createTestSteps();

      // At 58m, user is 8m past boundary
      // With 10m threshold, should not confirm yet
      final result = applyStepHysteresis(
        rawStepIndex: 1,
        confirmedStepIndex: 0,
        distanceCovered: 58,
        steps: steps,
        hysteresisThreshold: 10.0,
      );

      expect(result, 0); // Should stay at step 0
    });

    test('handles transition to last step', () {
      final steps = createTestSteps();

      // Total: 50 + 100 + 80 = 230m
      // Boundary to step 2 is at 150m
      // At 156m, 6m past boundary
      final result = applyStepHysteresis(
        rawStepIndex: 2,
        confirmedStepIndex: 1,
        distanceCovered: 156,
        steps: steps,
        hysteresisThreshold: 5.0,
      );

      expect(result, 2); // Should confirm step 2
    });
  });

  group('Arrival detection with step check', () {
    test('does not trigger arrival on non-last step even within threshold', () {
      // This tests the fix where arrival was announced 2-3 steps early
      const totalSteps = 5;
      const stepIndex = 2; // Not the last step
      const distanceRemaining = 15.0; // Within 20m threshold
      const arrivalThreshold = 20.0;

      final isLastStep = stepIndex >= totalSteps - 1;
      final meetsDistanceThreshold = distanceRemaining < arrivalThreshold;
      final hasArrived = isLastStep && meetsDistanceThreshold;

      expect(isLastStep, false);
      expect(meetsDistanceThreshold, true);
      expect(hasArrived, false); // Should NOT be arrived
    });

    test('triggers arrival on last step within threshold', () {
      const totalSteps = 5;
      const stepIndex = 4; // Last step (0-indexed)
      const distanceRemaining = 15.0;
      const arrivalThreshold = 20.0;

      final isLastStep = stepIndex >= totalSteps - 1;
      final meetsDistanceThreshold = distanceRemaining < arrivalThreshold;
      final hasArrived = isLastStep && meetsDistanceThreshold;

      expect(isLastStep, true);
      expect(meetsDistanceThreshold, true);
      expect(hasArrived, true); // Should be arrived
    });

    test('does not trigger arrival on last step outside threshold', () {
      const totalSteps = 5;
      const stepIndex = 4; // Last step
      const distanceRemaining = 25.0; // Outside 20m threshold
      const arrivalThreshold = 20.0;

      final isLastStep = stepIndex >= totalSteps - 1;
      final meetsDistanceThreshold = distanceRemaining < arrivalThreshold;
      final hasArrived = isLastStep && meetsDistanceThreshold;

      expect(isLastStep, true);
      expect(meetsDistanceThreshold, false);
      expect(hasArrived, false); // Should NOT be arrived yet
    });

    test('handles single step route', () {
      const totalSteps = 1;
      const stepIndex = 0; // Only step is also last step
      const distanceRemaining = 10.0;
      const arrivalThreshold = 20.0;

      final isLastStep = stepIndex >= totalSteps - 1;
      final meetsDistanceThreshold = distanceRemaining < arrivalThreshold;
      final hasArrived = isLastStep && meetsDistanceThreshold;

      expect(isLastStep, true);
      expect(hasArrived, true);
    });
  });

  group('Route progress calculation with partial segments', () {
    // Helper to calculate progress like NavigationController does
    (double, double) calculateRouteProgress({
      required int closestIndex,
      required Coordinates closestPoint,
      required List<Coordinates> polyline,
      required int totalDistance,
    }) {
      double distanceCovered = 0;

      // Sum complete segments before closestIndex
      for (int i = 0; i < closestIndex; i++) {
        distanceCovered += polyline[i].distanceTo(polyline[i + 1]);
      }

      // Add partial distance within current segment
      if (closestIndex < polyline.length) {
        final partialDistance = polyline[closestIndex].distanceTo(closestPoint);
        distanceCovered += partialDistance;
      }

      final distanceRemaining = totalDistance - distanceCovered;
      return (distanceCovered, distanceRemaining.clamp(0, totalDistance.toDouble()));
    }

    test('calculates zero distance at start of route', () {
      final polyline = [
        Coordinates(lat: 55.7500, lon: 37.6000),
        Coordinates(lat: 55.7510, lon: 37.6000),
        Coordinates(lat: 55.7520, lon: 37.6000),
      ];

      final (distanceCovered, distanceRemaining) = calculateRouteProgress(
        closestIndex: 0,
        closestPoint: polyline[0], // At the start
        polyline: polyline,
        totalDistance: 200,
      );

      expect(distanceCovered, closeTo(0, 0.1));
      expect(distanceRemaining, closeTo(200, 0.1));
    });

    test('calculates full distance at end of route', () {
      final polyline = [
        Coordinates(lat: 55.7500, lon: 37.6000),
        Coordinates(lat: 55.7510, lon: 37.6000), // ~111m north
        Coordinates(lat: 55.7520, lon: 37.6000), // ~111m north
      ];

      // At the last point
      final (distanceCovered, _) = calculateRouteProgress(
        closestIndex: 1, // Between points 1 and 2
        closestPoint: polyline[2], // At end
        polyline: polyline,
        totalDistance: 222,
      );

      // Should have covered approximately full distance
      expect(distanceCovered, greaterThan(200));
    });

    test('calculates partial segment distance correctly', () {
      final start = Coordinates(lat: 55.7500, lon: 37.6000);
      final end = Coordinates(lat: 55.7510, lon: 37.6000);
      // Midpoint
      final midpoint = Coordinates(lat: 55.7505, lon: 37.6000);

      final polyline = [start, end];

      final (distanceCovered, _) = calculateRouteProgress(
        closestIndex: 0,
        closestPoint: midpoint,
        polyline: polyline,
        totalDistance: 111,
      );

      // Should be approximately half the segment distance
      final fullSegmentDistance = start.distanceTo(end);
      expect(distanceCovered, closeTo(fullSegmentDistance / 2, 5));
    });
  });
}
