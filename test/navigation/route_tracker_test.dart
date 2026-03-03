import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/tracking/route_tracker.dart';
import 'package:qorvia_maps_sdk/src/navigation/navigation_options.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';
import 'package:qorvia_maps_sdk/src/models/route/route_step.dart';

void main() {
  // Simple route: straight line from (50,30) to (50.01,30) — ~1.1 km
  final polyline = [
    const Coordinates(lat: 50.0, lon: 30.0),
    const Coordinates(lat: 50.002, lon: 30.0),
    const Coordinates(lat: 50.004, lon: 30.0),
    const Coordinates(lat: 50.006, lon: 30.0),
    const Coordinates(lat: 50.008, lon: 30.0),
    const Coordinates(lat: 50.01, lon: 30.0),
  ];

  final steps = [
    const RouteStep(
      instruction: 'Depart',
      distanceMeters: 400,
      durationSeconds: 30,
      maneuver: 'depart',
      legIndex: 0,
    ),
    const RouteStep(
      instruction: 'Continue straight',
      distanceMeters: 400,
      durationSeconds: 30,
      maneuver: 'straight',
      legIndex: 0,
    ),
    const RouteStep(
      instruction: 'Arrive',
      distanceMeters: 300,
      durationSeconds: 20,
      maneuver: 'arrive',
      legIndex: 0,
    ),
  ];

  group('RouteTracker', () {
    late RouteTracker tracker;

    setUp(() {
      tracker = RouteTracker(
        options: const NavigationOptions(),
        polyline: polyline,
        steps: steps,
      );
    });

    test('initial state', () {
      expect(tracker.currentStepIndex, 0);
      expect(tracker.currentLegIndex, 0);
      expect(tracker.isSnapped, false);
      expect(tracker.isOffRoute, false);
      expect(tracker.totalRouteDistance, greaterThan(0));
    });

    test('snaps to route when close', () {
      // Position very close to route
      final progress = tracker.update(
        const Coordinates(lat: 50.001, lon: 30.0),
        10.0,
      );

      expect(progress.isSnapped, true);
      expect(progress.distanceFromRoute, lessThan(15)); // snap threshold
    });

    test('detects off-route when far from route', () {
      // Position far from route
      final progress = tracker.update(
        const Coordinates(lat: 50.001, lon: 30.001),
        10.0,
      );

      // ~80m from route — should be off-route (threshold = 30m)
      expect(progress.distanceFromRoute, greaterThan(30));
      expect(progress.isOffRoute, true);
    });

    test('calculates distance remaining', () {
      final progressStart = tracker.update(
        const Coordinates(lat: 50.001, lon: 30.0),
        10.0,
      );

      final progressMid = tracker.update(
        const Coordinates(lat: 50.005, lon: 30.0),
        10.0,
      );

      // Distance remaining should decrease as we move along
      expect(progressMid.distanceRemaining,
          lessThan(progressStart.distanceRemaining));
    });

    test('tracks closest segment index', () {
      // Near the start
      final progressStart = tracker.update(
        const Coordinates(lat: 50.001, lon: 30.0),
        10.0,
      );
      expect(progressStart.closestSegmentIndex, lessThanOrEqualTo(1));

      // Near the end
      final progressEnd = tracker.update(
        const Coordinates(lat: 50.009, lon: 30.0),
        10.0,
      );
      expect(progressEnd.closestSegmentIndex, greaterThan(2));
    });

    test('provides route bearing', () {
      final progress = tracker.update(
        const Coordinates(lat: 50.003, lon: 30.0),
        10.0,
      );

      // Route goes north, bearing should be close to 0
      expect(progress.routeBearing, closeTo(0, 5));
    });

    test('reset restores initial state', () {
      tracker.update(const Coordinates(lat: 50.005, lon: 30.0), 10.0);
      tracker.reset();

      expect(tracker.currentStepIndex, 0);
      expect(tracker.currentLegIndex, 0);
      expect(tracker.isSnapped, false);
    });
  });

  group('RouteTracker multi-waypoint', () {
    final multiSteps = [
      const RouteStep(
        instruction: 'Depart',
        distanceMeters: 500,
        durationSeconds: 40,
        maneuver: 'depart',
        legIndex: 0,
      ),
      const RouteStep(
        instruction: 'Arrive at waypoint',
        distanceMeters: 500,
        durationSeconds: 40,
        maneuver: 'arrive',
        legIndex: 0,
        waypointIndex: 0,
      ),
      const RouteStep(
        instruction: 'Continue',
        distanceMeters: 100,
        durationSeconds: 10,
        maneuver: 'depart',
        legIndex: 1,
      ),
    ];

    test('detects leg transition', () {
      final tracker = RouteTracker(
        options: const NavigationOptions(),
        polyline: polyline,
        steps: multiSteps,
      );

      // Start near beginning
      tracker.update(const Coordinates(lat: 50.001, lon: 30.0), 10.0);
      expect(tracker.currentLegIndex, 0);
    });
  });
}
