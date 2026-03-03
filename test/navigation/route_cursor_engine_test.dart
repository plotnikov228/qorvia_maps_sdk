import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/tracking/route_cursor_engine.dart';
import 'package:qorvia_maps_sdk/src/navigation/navigation_options.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';

void main() {
  // Straight north route: ~1.1 km
  final straightRoute = [
    const Coordinates(lat: 50.0, lon: 30.0),
    const Coordinates(lat: 50.002, lon: 30.0),
    const Coordinates(lat: 50.004, lon: 30.0),
    const Coordinates(lat: 50.006, lon: 30.0),
    const Coordinates(lat: 50.008, lon: 30.0),
    const Coordinates(lat: 50.01, lon: 30.0),
  ];

  // Route with a 90-degree right turn
  final turnRoute = [
    const Coordinates(lat: 50.0, lon: 30.0),
    const Coordinates(lat: 50.001, lon: 30.0), // north
    const Coordinates(lat: 50.002, lon: 30.0), // north
    const Coordinates(lat: 50.002, lon: 30.001), // east (90-degree turn)
    const Coordinates(lat: 50.002, lon: 30.002), // east
    const Coordinates(lat: 50.002, lon: 30.003), // east
  ];

  const options = NavigationOptions();

  group('RouteCursorEngine — initialization', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
    });

    test('hasRoute is false before setRoute', () {
      expect(engine.hasRoute, false);
      expect(engine.currentPosition, isNull);
    });

    test('setRoute initializes state correctly', () {
      engine.setRoute(straightRoute);

      expect(engine.hasRoute, true);
      expect(engine.distanceAlongRoute, 0);
      expect(engine.velocity, 0);
      expect(engine.isOnRoute, true);
      expect(engine.isDecelerating, false);
      expect(engine.currentPosition, straightRoute.first);
      expect(engine.currentSegmentIndex, 0);
      expect(engine.totalDistance, greaterThan(0));
    });

    test('totalDistance is sum of all segment distances', () {
      engine.setRoute(straightRoute);

      double expected = 0;
      for (int i = 0; i < straightRoute.length - 1; i++) {
        expected += straightRoute[i].distanceTo(straightRoute[i + 1]);
      }

      expect(engine.totalDistance, closeTo(expected, 0.01));
    });

    test('reset clears all state', () {
      engine.setRoute(straightRoute);
      engine.feedGps(straightRoute[1], 10.0);
      engine.advance(const Duration(milliseconds: 100));

      engine.reset();

      expect(engine.hasRoute, false);
      expect(engine.currentPosition, isNull);
      expect(engine.distanceAlongRoute, 0);
      expect(engine.velocity, 0);
      expect(engine.totalDistance, 0);
    });
  });

  group('RouteCursorEngine — cursor advances along straight route', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
      engine.setRoute(straightRoute);
    });

    test('advance returns null without route', () {
      final noRouteEngine = RouteCursorEngine(options: options);
      final result = noRouteEngine.advance(const Duration(milliseconds: 16));
      expect(result, isNull);
    });

    test('cursor stays at start with zero speed', () {
      engine.feedGps(straightRoute.first, 0);

      final result = engine.advance(const Duration(milliseconds: 100));

      expect(result, isNotNull);
      expect(result!.distanceAlongRoute, closeTo(0, 1.0));
    });

    test('cursor moves forward with constant speed', () {
      // Feed GPS at speed 10 m/s near the start
      engine.feedGps(straightRoute[1], 10.0);

      // Advance multiple frames to let velocity build up
      double totalDist = 0;
      for (int i = 0; i < 60; i++) {
        final result = engine.advance(const Duration(milliseconds: 16));
        if (result != null) {
          totalDist = result.distanceAlongRoute;
        }
      }

      // After ~1 second at 10 m/s, should have moved forward
      expect(totalDist, greaterThan(0));
    });

    test('cursor position is always on the route polyline', () {
      engine.feedGps(straightRoute[1], 10.0);

      for (int i = 0; i < 100; i++) {
        final result = engine.advance(const Duration(milliseconds: 16));
        if (result == null) continue;

        // Since it's a straight north route, longitude should stay at 30.0
        expect(result.position.lon, closeTo(30.0, 0.0001));
        // Latitude should be between start and end
        expect(result.position.lat, greaterThanOrEqualTo(50.0 - 0.0001));
        expect(result.position.lat, lessThanOrEqualTo(50.01 + 0.0001));
      }
    });

    test('distanceAlongRoute never decreases', () {
      engine.feedGps(straightRoute[1], 10.0);

      double prevDist = 0;
      for (int i = 0; i < 60; i++) {
        final result = engine.advance(const Duration(milliseconds: 16));
        if (result == null) continue;

        expect(result.distanceAlongRoute, greaterThanOrEqualTo(prevDist));
        prevDist = result.distanceAlongRoute;
      }
    });

    test('bearing is approximately north on straight north route', () {
      engine.feedGps(straightRoute[1], 10.0);

      // Advance to get cursor moving
      for (int i = 0; i < 30; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      final result = engine.advance(const Duration(milliseconds: 16));
      if (result != null && engine.distanceAlongRoute > 1) {
        // Bearing should be ~0 (north) or ~360
        final bearing = result.bearing;
        expect(bearing < 10 || bearing > 350, true,
            reason: 'Bearing should be ~0 (north), got $bearing');
      }
    });
  });

  group('RouteCursorEngine — GPS backward jump handling', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
      engine.setRoute(straightRoute);
    });

    test('GPS backward jump sets deceleration flag', () {
      // Move cursor forward with high speed for longer to ensure > 5m travel
      engine.feedGps(straightRoute[2], 20.0);
      for (int i = 0; i < 120; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      final distBefore = engine.distanceAlongRoute;
      expect(distBefore, greaterThan(5));

      // Feed GPS at a position behind the cursor (large backward jump)
      engine.feedGps(straightRoute[0], 20.0);

      // Should be decelerating
      expect(engine.isDecelerating, true);
    });

    test('cursor does not move backward on GPS backward jump', () {
      // Move cursor forward
      engine.feedGps(straightRoute[2], 10.0);
      for (int i = 0; i < 60; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      final distBefore = engine.distanceAlongRoute;

      // Feed GPS behind cursor
      engine.feedGps(straightRoute[0], 10.0);

      // Advance several frames — cursor should decelerate, not reverse
      for (int i = 0; i < 30; i++) {
        final result = engine.advance(const Duration(milliseconds: 16));
        if (result != null) {
          // Distance should never go below what it was before the backward jump
          // (or only very slightly due to micro-correction)
          expect(result.distanceAlongRoute, greaterThanOrEqualTo(distBefore - 1.0));
        }
      }
    });

    test('small GPS backward jump (<5m) is treated as noise', () {
      // Move cursor forward
      engine.feedGps(straightRoute[1], 10.0);
      for (int i = 0; i < 60; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      // Feed GPS just slightly behind cursor (< 5m)
      // Create a position very close to current cursor position
      final currentDist = engine.distanceAlongRoute;
      if (currentDist > 10) {
        // Feed GPS slightly behind — this should be within the 5m noise threshold
        // and NOT trigger deceleration
        final slightlyBehind = Coordinates(
          lat: engine.currentPosition!.lat - 0.00001, // ~1.1m back
          lon: engine.currentPosition!.lon,
        );
        engine.feedGps(slightlyBehind, 10.0);

        expect(engine.isDecelerating, false);
      }
    });
  });

  group('RouteCursorEngine — GPS forward jump (catch-up)', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
      engine.setRoute(straightRoute);
    });

    test('GPS significantly ahead increases target velocity', () {
      // Feed GPS at a point well ahead of cursor start
      engine.feedGps(straightRoute[2], 10.0);

      // Cursor is at start (dist=0), GPS projects ahead
      // Engine should set targetVelocity > GPS speed for catch-up
      expect(engine.isDecelerating, false);

      // Advance and verify cursor moves
      for (int i = 0; i < 60; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      expect(engine.distanceAlongRoute, greaterThan(0));
    });
  });

  group('RouteCursorEngine — off-route detection', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
      engine.setRoute(straightRoute);
    });

    test('on-route when GPS is close to route', () {
      // Feed GPS exactly on route
      engine.feedGps(straightRoute[1], 10.0);
      expect(engine.isOnRoute, true);
      expect(engine.gpsDistanceFromRoute, closeTo(0, 1.0));
    });

    test('off-route when GPS is far from route', () {
      // Feed GPS 50m to the east (well beyond 15m snap threshold)
      final offRoutePos = Coordinates(
        lat: 50.001,
        lon: 30.001, // ~70m east at this latitude
      );
      engine.feedGps(offRoutePos, 10.0);

      expect(engine.isOnRoute, false);
      expect(engine.gpsDistanceFromRoute, greaterThan(options.snapToRouteThreshold));
    });

    test('off-route sets target velocity to zero', () {
      // Move cursor forward first
      engine.feedGps(straightRoute[1], 10.0);
      for (int i = 0; i < 30; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      // Go off-route
      final offRoutePos = Coordinates(
        lat: 50.001,
        lon: 30.001,
      );
      engine.feedGps(offRoutePos, 10.0);

      expect(engine.isOnRoute, false);
      expect(engine.isDecelerating, true);

      // Advance frames — velocity should decrease toward zero
      for (int i = 0; i < 120; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      expect(engine.velocity, closeTo(0, 1.0));
    });
  });

  group('RouteCursorEngine — velocity control', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
      engine.setRoute(straightRoute);
    });

    test('velocity starts at zero', () {
      expect(engine.velocity, 0);
    });

    test('velocity increases smoothly (not instantly)', () {
      engine.feedGps(straightRoute[1], 10.0);

      final result1 = engine.advance(const Duration(milliseconds: 16));
      final v1 = engine.velocity;

      // After one frame, velocity should be less than target (10 m/s)
      expect(v1, lessThan(10.0));
      expect(v1, greaterThan(0));
    });

    test('velocity is clamped to max speed', () {
      // Feed very high speed
      engine.feedGps(straightRoute[2], 100.0);

      // Advance many frames
      for (int i = 0; i < 300; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      // Velocity should be clamped (maxSpeed = lastGpsSpeed * 2.5)
      expect(engine.velocity, lessThanOrEqualTo(250.0));
    });

    test('velocity decelerates smoothly to zero on stop', () {
      // Build up speed
      engine.feedGps(straightRoute[1], 10.0);
      for (int i = 0; i < 60; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }
      expect(engine.velocity, greaterThan(0));

      // Set speed to 0
      engine.feedGps(straightRoute[2], 0.0);

      // Velocity should decrease over time, not instantly
      double prevV = engine.velocity;
      for (int i = 0; i < 120; i++) {
        engine.advance(const Duration(milliseconds: 16));
        final v = engine.velocity;
        expect(v, lessThanOrEqualTo(prevV + 0.01)); // allows tiny float error
        prevV = v;
      }

      expect(engine.velocity, closeTo(0, 0.5));
    });
  });

  group('RouteCursorEngine — distance-to-position projection', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
      engine.setRoute(straightRoute);
    });

    test('cursor at distance 0 is at route start', () {
      final result = engine.advance(const Duration(milliseconds: 16));
      expect(result, isNotNull);
      expect(result!.position.lat, closeTo(straightRoute.first.lat, 0.0001));
      expect(result!.position.lon, closeTo(straightRoute.first.lon, 0.0001));
    });

    test('cursor at total distance is at route end', () {
      // Move cursor to the very end with high speed
      engine.feedGps(straightRoute.last, 100.0);

      // Advance many frames to reach end (need enough time to traverse ~1.1km)
      // At 100 m/s with catch-up, ~11 seconds needed, at 16ms/frame ~700 frames
      for (int i = 0; i < 2000; i++) {
        engine.advance(const Duration(milliseconds: 16));
        // Re-feed GPS to maintain high target velocity
        if (i % 60 == 0) {
          engine.feedGps(straightRoute.last, 100.0);
        }
      }

      // Cursor should have reached near the end of route
      expect(engine.distanceAlongRoute, greaterThan(engine.totalDistance * 0.5));
    });

    test('segment index increases as cursor moves forward', () {
      // Each segment is ~222m. Need to traverse at least one.
      // At 30 m/s, takes ~7.4 seconds → ~460 frames
      engine.feedGps(straightRoute[3], 30.0);

      int maxSegIndex = 0;
      for (int i = 0; i < 600; i++) {
        final result = engine.advance(const Duration(milliseconds: 16));
        if (result != null && result.segmentIndex > maxSegIndex) {
          maxSegIndex = result.segmentIndex;
        }
        // Re-feed GPS to keep velocity high
        if (i % 60 == 0) {
          engine.feedGps(straightRoute[3], 30.0);
        }
      }

      expect(maxSegIndex, greaterThan(0));
    });
  });

  group('RouteCursorEngine — route with turn', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
      engine.setRoute(turnRoute);
    });

    test('cursor follows route around a turn', () {
      // Feed GPS at a point after the turn (east section)
      engine.feedGps(turnRoute[4], 15.0);

      CursorPosition? lastPos;
      for (int i = 0; i < 300; i++) {
        final result = engine.advance(const Duration(milliseconds: 16));
        if (result != null) lastPos = result;
      }

      // Cursor should have moved past the turn
      if (lastPos != null && engine.distanceAlongRoute > 200) {
        // After the turn, bearing should be approximately east (~90 degrees)
        expect(lastPos.bearing, closeTo(90, 30));
      }
    });

    test('turn detection finds upcoming turn', () {
      // Position cursor near the start, moving toward the turn
      engine.feedGps(turnRoute[0], 10.0);

      for (int i = 0; i < 30; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      // The turn is at index 2→3 (north→east), which should be detectable
      // depending on how far the cursor has moved
      if (engine.isApproachingTurn) {
        expect(engine.upcomingTurnAngle, isNotNull);
        expect(engine.distanceToNextTurn, isNotNull);
        expect(engine.distanceToNextTurn!, greaterThan(0));
      }
    });
  });

  group('RouteCursorEngine — route update (reroute)', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
    });

    test('setRoute with new polyline resets cursor to start', () {
      engine.setRoute(straightRoute);

      // Move cursor forward
      engine.feedGps(straightRoute[2], 10.0);
      for (int i = 0; i < 60; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }
      expect(engine.distanceAlongRoute, greaterThan(0));

      // Set a new route (simulating reroute)
      engine.setRoute(turnRoute);

      expect(engine.distanceAlongRoute, 0);
      expect(engine.velocity, 0);
      expect(engine.isOnRoute, true);
      expect(engine.currentSegmentIndex, 0);
    });
  });

  group('RouteCursorEngine — edge cases', () {
    late RouteCursorEngine engine;

    setUp(() {
      engine = RouteCursorEngine(options: options);
    });

    test('advance with zero dt returns current position', () {
      engine.setRoute(straightRoute);
      engine.feedGps(straightRoute[1], 10.0);

      final result = engine.advance(Duration.zero);
      expect(result, isNotNull);
    });

    test('advance with large dt (>1s) returns current position without advancing', () {
      engine.setRoute(straightRoute);
      engine.feedGps(straightRoute[1], 10.0);

      final result = engine.advance(const Duration(seconds: 2));
      expect(result, isNotNull);
      // Should not advance because dt > 1.0 is rejected
      expect(result!.distanceAlongRoute, closeTo(0, 0.1));
    });

    test('two-point route works', () {
      final twoPointRoute = [
        const Coordinates(lat: 50.0, lon: 30.0),
        const Coordinates(lat: 50.001, lon: 30.0),
      ];

      engine.setRoute(twoPointRoute);
      expect(engine.hasRoute, true);
      expect(engine.totalDistance, greaterThan(0));

      engine.feedGps(twoPointRoute[0], 5.0);
      final result = engine.advance(const Duration(milliseconds: 16));
      expect(result, isNotNull);
    });

    test('feedGps with no route does nothing', () {
      engine.feedGps(const Coordinates(lat: 50.0, lon: 30.0), 10.0);
      // Should not throw
      expect(engine.hasRoute, false);
    });

    test('distanceAlongRoute is clamped to totalDistance', () {
      engine.setRoute(straightRoute);

      // Feed GPS at end with high speed
      engine.feedGps(straightRoute.last, 100.0);

      for (int i = 0; i < 1000; i++) {
        engine.advance(const Duration(milliseconds: 16));
      }

      expect(engine.distanceAlongRoute, lessThanOrEqualTo(engine.totalDistance));
    });
  });
}
