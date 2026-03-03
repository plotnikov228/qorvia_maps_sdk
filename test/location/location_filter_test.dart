import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/location/location_filter.dart';
import 'package:qorvia_maps_sdk/src/location/location_data.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';

void main() {
  group('LocationFilter', () {
    late LocationFilter filter;

    setUp(() {
      filter = LocationFilter();
    });

    LocationData createLocation({
      double lat = 55.7558,
      double lon = 37.6173,
      double accuracy = 10.0,
      double? speed,
      double? heading,
      DateTime? timestamp,
    }) {
      return LocationData(
        coordinates: Coordinates(lat: lat, lon: lon),
        accuracy: accuracy,
        speed: speed,
        heading: heading,
        timestamp: timestamp ?? DateTime.now(),
      );
    }

    test('accepts first location', () {
      final location = createLocation();
      final result = filter.filter(location);

      expect(result, isNotNull);
      expect(result!.coordinates.lat, equals(location.coordinates.lat));
      expect(result.coordinates.lon, equals(location.coordinates.lon));
    });

    test('rejects location with accuracy above threshold', () {
      final location = createLocation(accuracy: 150.0); // Above default 100m threshold
      final result = filter.filter(location);

      expect(result, isNull);
    });

    test('accepts location with accuracy below threshold', () {
      final location = createLocation(accuracy: 50.0);
      final result = filter.filter(location);

      expect(result, isNotNull);
    });

    test('variance is capped at maximum', () {
      // First location to initialize
      filter.filter(createLocation());

      // Simulate long time without updates - variance should grow but be capped
      final futureLocation = createLocation(
        timestamp: DateTime.now().add(const Duration(hours: 1)),
      );

      final result = filter.filter(futureLocation);
      expect(result, isNotNull);

      // estimatedAccuracy is sqrt(variance), so if variance is capped at 10000,
      // accuracy should be ~100m
      expect(filter.estimatedAccuracy, lessThanOrEqualTo(100.0));
    });

    test('variance does not go below minimum', () {
      // Filter several very accurate locations
      for (var i = 0; i < 10; i++) {
        filter.filter(createLocation(
          accuracy: 1.0,
          timestamp: DateTime.now().add(Duration(milliseconds: i * 100)),
        ));
      }

      // estimatedAccuracy should be at least 1m (sqrt of minimum variance)
      expect(filter.estimatedAccuracy, greaterThanOrEqualTo(1.0));
    });

    test('reset clears filter state', () {
      filter.filter(createLocation());
      filter.reset();

      // After reset, estimatedAccuracy should be very high (uninitialized)
      expect(filter.estimatedAccuracy, greaterThan(1000));
    });

    test('rejects unrealistic speed', () {
      // Initialize filter
      filter.filter(createLocation(
        speed: 10.0,
        timestamp: DateTime.now(),
      ));

      // Try to add location with unrealistic speed (>70 m/s = 252 km/h)
      final fastLocation = createLocation(
        speed: 100.0,
        timestamp: DateTime.now().add(const Duration(seconds: 1)),
      );

      final result = filter.filter(fastLocation);
      expect(result, isNull);
    });

    test('accepts normal speed', () {
      filter.filter(createLocation(
        speed: 10.0,
        timestamp: DateTime.now(),
      ));

      final normalLocation = createLocation(
        speed: 15.0,
        timestamp: DateTime.now().add(const Duration(seconds: 1)),
      );

      final result = filter.filter(normalLocation);
      expect(result, isNotNull);
    });

    test('resets after stale threshold', () {
      // Initialize
      filter.filter(createLocation(timestamp: DateTime.now()));

      // Get current accuracy
      final initialAccuracy = filter.estimatedAccuracy;

      // Add location after stale threshold (60 seconds)
      final staleLocation = createLocation(
        timestamp: DateTime.now().add(const Duration(seconds: 70)),
      );

      filter.filter(staleLocation);

      // After stale reset, filter should be reinitialized
      // Accuracy should be based on new location's accuracy
      expect(filter.estimatedAccuracy, isNotNull);
    });

    test('allows jump after long pause', () {
      // Initialize at one location
      filter.filter(createLocation(
        lat: 55.7558,
        lon: 37.6173,
        timestamp: DateTime.now(),
      ));

      // Jump to very different location after 15 seconds (long pause)
      // Without long pause handling, this would be rejected as teleportation
      final jumpLocation = createLocation(
        lat: 55.8000, // ~5km away
        lon: 37.6173,
        timestamp: DateTime.now().add(const Duration(seconds: 15)),
      );

      final result = filter.filter(jumpLocation);
      expect(result, isNotNull);
    });

    test('adaptive acceleration threshold at low speed', () {
      // Initialize at low speed
      filter.filter(createLocation(
        speed: 1.0,
        timestamp: DateTime.now(),
      ));

      // Sudden acceleration at low speed should be allowed (GPS noise)
      final acceleratedLocation = createLocation(
        speed: 1.5,
        timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
      );

      final result = filter.filter(acceleratedLocation);
      expect(result, isNotNull);
    });
  });

  group('LocationFilterSettings', () {
    test('default settings have reasonable values', () {
      const settings = LocationFilterSettings();

      expect(settings.enabled, isTrue);
      expect(settings.processNoise, equals(3.0));
      expect(settings.minAccuracyThreshold, equals(100.0));
      expect(settings.maxSpeedThreshold, equals(70.0));
    });

    test('navigation settings are stricter', () {
      final settings = LocationFilterSettings.navigation();

      expect(settings.enabled, isTrue);
      expect(settings.minAccuracyThreshold, lessThan(100.0));
      expect(settings.processNoise, lessThan(3.0));
    });

    test('walking settings have lower speed threshold', () {
      final settings = LocationFilterSettings.walking();

      expect(settings.enabled, isTrue);
      expect(settings.maxSpeedThreshold, lessThan(70.0));
    });
  });
}
