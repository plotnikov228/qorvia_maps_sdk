import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('Coordinates', () {
    test('creates valid coordinates', () {
      final coords = Coordinates(lat: 55.7539, lon: 37.6208);
      expect(coords.lat, 55.7539);
      expect(coords.lon, 37.6208);
    });

    test('converts to/from JSON', () {
      final coords = Coordinates(lat: 55.7539, lon: 37.6208);
      final json = coords.toJson();
      final restored = Coordinates.fromJson(json);
      expect(restored, coords);
    });

    test('calculates distance between points', () {
      final moscow = Coordinates(lat: 55.7539, lon: 37.6208);
      final spb = Coordinates(lat: 59.9343, lon: 30.3351);
      final distance = moscow.distanceTo(spb);
      // Distance should be approximately 634 km
      expect(distance, greaterThan(630000));
      expect(distance, lessThan(640000));
    });
  });

  group('PolylineDecoder', () {
    test('decodes simple polyline', () {
      // Encoded polyline for a simple path
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final decoded = PolylineDecoder.decode(encoded);
      expect(decoded.length, greaterThan(0));
    });

    test('encodes and decodes back to same coordinates', () {
      final original = [
        Coordinates(lat: 38.5, lon: -120.2),
        Coordinates(lat: 40.7, lon: -120.95),
        Coordinates(lat: 43.252, lon: -126.453),
      ];
      final encoded = PolylineDecoder.encode(original);
      final decoded = PolylineDecoder.decode(encoded);

      expect(decoded.length, original.length);
      for (int i = 0; i < original.length; i++) {
        expect((decoded[i].lat - original[i].lat).abs(), lessThan(0.00001));
        expect((decoded[i].lon - original[i].lon).abs(), lessThan(0.00001));
      }
    });
  });

  group('RouteStep', () {
    test('parses from JSON', () {
      final json = {
        'instruction': 'Turn right',
        'distance_meters': 100,
        'duration_seconds': 30,
        'maneuver': 'turn-right',
        'name': 'Main Street',
      };
      final step = RouteStep.fromJson(json);
      expect(step.instruction, 'Turn right');
      expect(step.distanceMeters, 100);
      expect(step.maneuver, 'turn-right');
    });
  });

  group('TransportMode', () {
    test('converts from string', () {
      expect(TransportMode.fromString('car'), TransportMode.car);
      expect(TransportMode.fromString('bike'), TransportMode.bike);
      expect(TransportMode.fromString('foot'), TransportMode.foot);
      expect(TransportMode.fromString('truck'), TransportMode.truck);
      expect(TransportMode.fromString('invalid'), TransportMode.car);
    });
  });
}
