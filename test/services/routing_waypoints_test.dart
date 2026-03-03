import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';
import 'package:qorvia_maps_sdk/src/models/route/route_request.dart';
import 'package:qorvia_maps_sdk/src/models/route/route_step.dart';

void main() {
  group('Waypoints Support', () {
    group('RouteRequest', () {
      test('creates request without waypoints (backward compatibility)', () {
        final request = RouteRequest(
          from: const Coordinates(lat: 55.7558, lon: 37.6173),
          to: const Coordinates(lat: 55.7000, lon: 37.5000),
        );

        expect(request.waypoints, isNull);
        expect(request.from.lat, 55.7558);
        expect(request.to.lat, 55.7000);
      });

      test('creates request with waypoints', () {
        final request = RouteRequest(
          from: const Coordinates(lat: 55.7558, lon: 37.6173),
          to: const Coordinates(lat: 55.7000, lon: 37.5000),
          waypoints: [
            const Coordinates(lat: 55.7400, lon: 37.5800),
            const Coordinates(lat: 55.7200, lon: 37.5500),
          ],
        );

        expect(request.waypoints, isNotNull);
        expect(request.waypoints!.length, 2);
        expect(request.waypoints![0].lat, 55.7400);
        expect(request.waypoints![1].lat, 55.7200);
      });

      test('accepts maximum 20 waypoints', () {
        final waypoints = List.generate(
          20,
          (i) => Coordinates(lat: 55.0 + i * 0.01, lon: 37.0 + i * 0.01),
        );

        // Should not throw
        final request = RouteRequest(
          from: const Coordinates(lat: 55.0, lon: 37.0),
          to: const Coordinates(lat: 56.0, lon: 38.0),
          waypoints: waypoints,
        );

        expect(request.waypoints!.length, 20);
      });

      test('throws ArgumentError when waypoints exceed 20', () {
        final waypoints = List.generate(
          21,
          (i) => Coordinates(lat: 55.0 + i * 0.01, lon: 37.0 + i * 0.01),
        );

        expect(
          () => RouteRequest(
            from: const Coordinates(lat: 55.0, lon: 37.0),
            to: const Coordinates(lat: 56.0, lon: 38.0),
            waypoints: waypoints,
          ),
          throwsArgumentError,
        );
      });

      test('accepts empty waypoints list', () {
        final request = RouteRequest(
          from: const Coordinates(lat: 55.7558, lon: 37.6173),
          to: const Coordinates(lat: 55.7000, lon: 37.5000),
          waypoints: [],
        );

        expect(request.waypoints, isNotNull);
        expect(request.waypoints!.isEmpty, isTrue);
      });

      group('toJson', () {
        test('excludes waypoints when null', () {
          final request = RouteRequest(
            from: const Coordinates(lat: 55.7558, lon: 37.6173),
            to: const Coordinates(lat: 55.7000, lon: 37.5000),
          );

          final json = request.toJson();

          expect(json.containsKey('waypoints'), isFalse);
        });

        test('excludes waypoints when empty', () {
          final request = RouteRequest(
            from: const Coordinates(lat: 55.7558, lon: 37.6173),
            to: const Coordinates(lat: 55.7000, lon: 37.5000),
            waypoints: [],
          );

          final json = request.toJson();

          expect(json.containsKey('waypoints'), isFalse);
        });

        test('includes waypoints array when present', () {
          final request = RouteRequest(
            from: const Coordinates(lat: 55.7558, lon: 37.6173),
            to: const Coordinates(lat: 55.7000, lon: 37.5000),
            waypoints: [
              const Coordinates(lat: 55.7400, lon: 37.5800),
              const Coordinates(lat: 55.7200, lon: 37.5500),
            ],
          );

          final json = request.toJson();

          expect(json.containsKey('waypoints'), isTrue);
          expect(json['waypoints'], isA<List>());
          expect((json['waypoints'] as List).length, 2);
          expect((json['waypoints'] as List)[0]['lat'], 55.7400);
          expect((json['waypoints'] as List)[0]['lon'], 37.5800);
        });
      });
    });

    group('RouteStep leg/waypoint fields', () {
      test('parses leg_index from JSON', () {
        final json = {
          'instruction': 'Go straight',
          'distance_meters': 500,
          'duration_seconds': 30,
          'maneuver': 'straight',
          'leg_index': 0,
        };

        final step = RouteStep.fromJson(json);

        expect(step.legIndex, 0);
        expect(step.waypointIndex, isNull);
      });

      test('parses waypoint_index from JSON', () {
        final json = {
          'instruction': 'You have reached waypoint 1',
          'distance_meters': 0,
          'duration_seconds': 0,
          'maneuver': 'arrive',
          'leg_index': 0,
          'waypoint_index': 0,
        };

        final step = RouteStep.fromJson(json);

        expect(step.legIndex, 0);
        expect(step.waypointIndex, 0);
      });

      test('handles missing leg/waypoint fields (backward compatibility)', () {
        final json = {
          'instruction': 'Turn left',
          'distance_meters': 100,
          'duration_seconds': 10,
          'maneuver': 'turn-left',
        };

        final step = RouteStep.fromJson(json);

        expect(step.legIndex, isNull);
        expect(step.waypointIndex, isNull);
      });

      test('serializes leg_index to JSON when present', () {
        const step = RouteStep(
          instruction: 'Go straight',
          distanceMeters: 500,
          durationSeconds: 30,
          maneuver: 'straight',
          legIndex: 1,
        );

        final json = step.toJson();

        expect(json['leg_index'], 1);
        expect(json.containsKey('waypoint_index'), isFalse);
      });

      test('serializes waypoint_index to JSON when present', () {
        const step = RouteStep(
          instruction: 'Arrived at waypoint',
          distanceMeters: 0,
          durationSeconds: 0,
          maneuver: 'arrive',
          legIndex: 0,
          waypointIndex: 0,
        );

        final json = step.toJson();

        expect(json['leg_index'], 0);
        expect(json['waypoint_index'], 0);
      });

      test('excludes null leg/waypoint fields from JSON', () {
        const step = RouteStep(
          instruction: 'Depart',
          distanceMeters: 50,
          durationSeconds: 5,
          maneuver: 'depart',
        );

        final json = step.toJson();

        expect(json.containsKey('leg_index'), isFalse);
        expect(json.containsKey('waypoint_index'), isFalse);
      });

      test('equality includes leg/waypoint fields', () {
        const step1 = RouteStep(
          instruction: 'Go',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'straight',
          legIndex: 0,
          waypointIndex: null,
        );

        const step2 = RouteStep(
          instruction: 'Go',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'straight',
          legIndex: 1,
          waypointIndex: null,
        );

        expect(step1, isNot(equals(step2)));
      });
    });

    group('Full route with waypoints scenario', () {
      test('parses route response with multiple legs', () {
        // Simulate API response for route: origin → wp1 → wp2 → destination
        final stepsJson = [
          // Leg 0: origin → wp1
          {
            'instruction': 'Depart',
            'distance_meters': 500,
            'duration_seconds': 60,
            'maneuver': 'depart',
            'leg_index': 0,
          },
          {
            'instruction': 'Turn right',
            'distance_meters': 300,
            'duration_seconds': 40,
            'maneuver': 'turn-right',
            'leg_index': 0,
          },
          {
            'instruction': 'Arrived at waypoint',
            'distance_meters': 0,
            'duration_seconds': 0,
            'maneuver': 'arrive',
            'leg_index': 0,
            'waypoint_index': 0,
          },
          // Leg 1: wp1 → wp2
          {
            'instruction': 'Continue',
            'distance_meters': 400,
            'duration_seconds': 50,
            'maneuver': 'depart',
            'leg_index': 1,
          },
          {
            'instruction': 'Arrived at waypoint',
            'distance_meters': 0,
            'duration_seconds': 0,
            'maneuver': 'arrive',
            'leg_index': 1,
            'waypoint_index': 1,
          },
          // Leg 2: wp2 → destination
          {
            'instruction': 'Go straight',
            'distance_meters': 600,
            'duration_seconds': 70,
            'maneuver': 'depart',
            'leg_index': 2,
          },
          {
            'instruction': 'You have arrived',
            'distance_meters': 0,
            'duration_seconds': 0,
            'maneuver': 'arrive',
            'leg_index': 2,
          },
        ];

        final steps =
            stepsJson.map((j) => RouteStep.fromJson(j)).toList();

        // Verify leg indices
        expect(steps[0].legIndex, 0);
        expect(steps[1].legIndex, 0);
        expect(steps[2].legIndex, 0);
        expect(steps[3].legIndex, 1);
        expect(steps[4].legIndex, 1);
        expect(steps[5].legIndex, 2);
        expect(steps[6].legIndex, 2);

        // Verify waypoint indices
        expect(steps[2].waypointIndex, 0); // First waypoint reached
        expect(steps[4].waypointIndex, 1); // Second waypoint reached
        expect(steps[6].waypointIndex, isNull); // Final destination, no waypoint

        // Count waypoints reached
        final waypointsReached =
            steps.where((s) => s.waypointIndex != null).length;
        expect(waypointsReached, 2);
      });
    });

    group('kMaxWaypoints constant', () {
      test('kMaxWaypoints equals 20', () {
        expect(kMaxWaypoints, 20);
      });
    });
  });
}
