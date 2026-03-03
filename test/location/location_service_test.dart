import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/location/location_service.dart';

void main() {
  group('LocationServiceHealth', () {
    test('isHealthy returns true when tracking and not stale', () {
      const health = LocationServiceHealth(
        isTracking: true,
        isStale: false,
        locationsReceived: 10,
        locationsFiltered: 2,
        streamRestarts: 0,
      );

      expect(health.isHealthy, isTrue);
    });

    test('isHealthy returns false when not tracking', () {
      const health = LocationServiceHealth(
        isTracking: false,
        isStale: false,
        locationsReceived: 10,
        locationsFiltered: 2,
        streamRestarts: 0,
      );

      expect(health.isHealthy, isFalse);
    });

    test('isHealthy returns false when stale', () {
      const health = LocationServiceHealth(
        isTracking: true,
        isStale: true,
        locationsReceived: 10,
        locationsFiltered: 2,
        streamRestarts: 0,
      );

      expect(health.isHealthy, isFalse);
    });

    test('filterRate calculates correctly', () {
      const health = LocationServiceHealth(
        isTracking: true,
        isStale: false,
        locationsReceived: 80,
        locationsFiltered: 20,
        streamRestarts: 0,
      );

      // 20 filtered out of 100 total = 0.2
      expect(health.filterRate, closeTo(0.2, 0.001));
    });

    test('filterRate returns 0 when no locations', () {
      const health = LocationServiceHealth(
        isTracking: true,
        isStale: false,
        locationsReceived: 0,
        locationsFiltered: 0,
        streamRestarts: 0,
      );

      expect(health.filterRate, equals(0));
    });

    test('toString includes all fields', () {
      const health = LocationServiceHealth(
        isTracking: true,
        isStale: false,
        timeSinceLastUpdate: Duration(seconds: 5),
        locationsReceived: 100,
        locationsFiltered: 10,
        streamRestarts: 2,
        filterEstimatedAccuracy: 5.5,
      );

      final str = health.toString();
      expect(str, contains('isTracking: true'));
      expect(str, contains('isStale: false'));
      expect(str, contains('received: 100'));
      expect(str, contains('filtered: 10'));
      expect(str, contains('restarts: 2'));
    });
  });

  group('LocationService', () {
    late LocationService service;

    setUp(() {
      service = LocationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is not tracking', () {
      expect(service.isTracking, isFalse);
    });

    test('lastLocation is null initially', () {
      expect(service.lastLocation, isNull);
    });

    test('checkHealth returns valid health object', () {
      final health = service.checkHealth();

      expect(health.isTracking, isFalse);
      expect(health.locationsReceived, equals(0));
      expect(health.locationsFiltered, equals(0));
      expect(health.streamRestarts, equals(0));
    });

    test('resetMetrics clears counters', () {
      // We can't easily trigger location updates in a unit test,
      // but we can verify the method exists and doesn't throw
      service.resetMetrics();

      final health = service.checkHealth();
      expect(health.locationsReceived, equals(0));
      expect(health.locationsFiltered, equals(0));
      expect(health.streamRestarts, equals(0));
    });

    test('dispose stops tracking and closes stream', () {
      service.dispose();
      // After dispose, service should be stopped
      expect(service.isTracking, isFalse);
    });

    test('callbacks can be set and cleared', () {
      var problemCalled = false;
      var recoveredCalled = false;

      service.onStreamProblem = (reason) => problemCalled = true;
      service.onStreamRecovered = () => recoveredCalled = true;

      // Clear callbacks
      service.onStreamProblem = null;
      service.onStreamRecovered = null;

      // Verify they were cleared (no exception when calling null)
      expect(service.onStreamProblem, isNull);
      expect(service.onStreamRecovered, isNull);
    });
  });
}
