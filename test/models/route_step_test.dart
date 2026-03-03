import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/models/route/route_step.dart';

void main() {
  group('RouteStep', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'instruction': 'Поверните налево на ул. Ленина',
          'voice_instruction':
              'Приготовьтесь повернуть налево через двести метров на улицу Ленина',
          'voice_instruction_short': 'Через 200 м налево',
          'next_maneuver_hint': 'а затем через 50 метров направо',
          'verbal_distance': 'двести метров',
          'distance_meters': 200,
          'duration_seconds': 15,
          'maneuver': 'turn',
          'name': 'ул. Ленина',
          'speed_limit': 60,
        };

        final step = RouteStep.fromJson(json);

        expect(step.instruction, 'Поверните налево на ул. Ленина');
        expect(
          step.voiceInstruction,
          'Приготовьтесь повернуть налево через двести метров на улицу Ленина',
        );
        expect(step.voiceInstructionShort, 'Через 200 м налево');
        expect(step.nextManeuverHint, 'а затем через 50 метров направо');
        expect(step.verbalDistance, 'двести метров');
        expect(step.distanceMeters, 200);
        expect(step.durationSeconds, 15);
        expect(step.maneuver, 'turn');
        expect(step.name, 'ул. Ленина');
        expect(step.speedLimit, 60);
      });

      test('handles missing optional fields (backward compatibility)', () {
        // Old API format without new voice fields
        final json = {
          'instruction': 'Turn left',
          'distance_meters': 100,
          'duration_seconds': 10,
          'maneuver': 'turn-left',
        };

        final step = RouteStep.fromJson(json);

        expect(step.instruction, 'Turn left');
        expect(step.voiceInstruction, isNull);
        expect(step.voiceInstructionShort, isNull);
        expect(step.nextManeuverHint, isNull);
        expect(step.verbalDistance, isNull);
        expect(step.distanceMeters, 100);
        expect(step.durationSeconds, 10);
        expect(step.maneuver, 'turn-left');
        expect(step.name, isNull);
        expect(step.speedLimit, isNull);
      });

      test('parses speed_limit when present', () {
        final json = {
          'instruction': 'Go straight',
          'distance_meters': 500,
          'duration_seconds': 30,
          'maneuver': 'straight',
          'speed_limit': 90,
        };

        final step = RouteStep.fromJson(json);

        expect(step.speedLimit, 90);
      });

      test('handles null speed_limit (OSM data missing)', () {
        final json = {
          'instruction': 'Go straight',
          'distance_meters': 500,
          'duration_seconds': 30,
          'maneuver': 'straight',
          'speed_limit': null,
        };

        final step = RouteStep.fromJson(json);

        expect(step.speedLimit, isNull);
      });

      test('handles partial new fields', () {
        final json = {
          'instruction': 'Go straight',
          'voice_instruction': 'Continue straight for 500 meters',
          'distance_meters': 500,
          'duration_seconds': 30,
          'maneuver': 'straight',
          'name': 'Main Street',
        };

        final step = RouteStep.fromJson(json);

        expect(step.instruction, 'Go straight');
        expect(step.voiceInstruction, 'Continue straight for 500 meters');
        expect(step.voiceInstructionShort, isNull);
        expect(step.nextManeuverHint, isNull);
        expect(step.verbalDistance, isNull);
        expect(step.name, 'Main Street');
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        const step = RouteStep(
          instruction: 'Поверните налево',
          voiceInstruction: 'Приготовьтесь повернуть налево',
          voiceInstructionShort: 'Налево',
          nextManeuverHint: 'затем направо',
          verbalDistance: 'сто метров',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'turn-left',
          name: 'ул. Пушкина',
          speedLimit: 60,
        );

        final json = step.toJson();

        expect(json['instruction'], 'Поверните налево');
        expect(json['voice_instruction'], 'Приготовьтесь повернуть налево');
        expect(json['voice_instruction_short'], 'Налево');
        expect(json['next_maneuver_hint'], 'затем направо');
        expect(json['verbal_distance'], 'сто метров');
        expect(json['distance_meters'], 100);
        expect(json['duration_seconds'], 10);
        expect(json['maneuver'], 'turn-left');
        expect(json['name'], 'ул. Пушкина');
        expect(json['speed_limit'], 60);
      });

      test('excludes null optional fields', () {
        const step = RouteStep(
          instruction: 'Depart',
          distanceMeters: 50,
          durationSeconds: 5,
          maneuver: 'depart',
        );

        final json = step.toJson();

        expect(json.containsKey('voice_instruction'), isFalse);
        expect(json.containsKey('voice_instruction_short'), isFalse);
        expect(json.containsKey('next_maneuver_hint'), isFalse);
        expect(json.containsKey('verbal_distance'), isFalse);
        expect(json.containsKey('name'), isFalse);
        expect(json.containsKey('speed_limit'), isFalse);
      });
    });

    group('equality', () {
      test('two steps with same values are equal', () {
        const step1 = RouteStep(
          instruction: 'Turn right',
          voiceInstruction: 'Turn right in 100 meters',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'turn-right',
          speedLimit: 50,
        );

        const step2 = RouteStep(
          instruction: 'Turn right',
          voiceInstruction: 'Turn right in 100 meters',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'turn-right',
          speedLimit: 50,
        );

        expect(step1, equals(step2));
        expect(step1.hashCode, equals(step2.hashCode));
      });

      test('steps with different voice instructions are not equal', () {
        const step1 = RouteStep(
          instruction: 'Turn right',
          voiceInstruction: 'Turn right now',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'turn-right',
        );

        const step2 = RouteStep(
          instruction: 'Turn right',
          voiceInstruction: 'Turn right in 100 meters',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'turn-right',
        );

        expect(step1, isNot(equals(step2)));
      });

      test('steps with different speed limits are not equal', () {
        const step1 = RouteStep(
          instruction: 'Go straight',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'straight',
          speedLimit: 60,
        );

        const step2 = RouteStep(
          instruction: 'Go straight',
          distanceMeters: 100,
          durationSeconds: 10,
          maneuver: 'straight',
          speedLimit: 90,
        );

        expect(step1, isNot(equals(step2)));
      });
    });

    group('roundtrip', () {
      test('fromJson -> toJson preserves all data', () {
        final originalJson = {
          'instruction': 'Arrive at destination',
          'voice_instruction': 'You have arrived at your destination',
          'voice_instruction_short': 'Arrived',
          'next_maneuver_hint': null,
          'verbal_distance': 'zero meters',
          'distance_meters': 0,
          'duration_seconds': 0,
          'maneuver': 'arrive',
          'name': 'Destination',
        };

        final step = RouteStep.fromJson(originalJson);
        final resultJson = step.toJson();

        expect(resultJson['instruction'], originalJson['instruction']);
        expect(resultJson['voice_instruction'], originalJson['voice_instruction']);
        expect(resultJson['voice_instruction_short'], originalJson['voice_instruction_short']);
        expect(resultJson['verbal_distance'], originalJson['verbal_distance']);
        expect(resultJson['distance_meters'], originalJson['distance_meters']);
        expect(resultJson['duration_seconds'], originalJson['duration_seconds']);
        expect(resultJson['maneuver'], originalJson['maneuver']);
        expect(resultJson['name'], originalJson['name']);
        // next_maneuver_hint was null, so it should not be in output
        expect(resultJson.containsKey('next_maneuver_hint'), isFalse);
      });
    });
  });
}
