import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/map/qorvia_map_controller.dart';
import 'package:qorvia_maps_sdk/src/map/camera/camera_position.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QorviaMapController camera position throttle', () {
    late QorviaMapController controller;

    setUp(() {
      controller = QorviaMapController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('first camera update triggers notifyListeners', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.updateCameraPosition(
        CameraPosition(
          center: const Coordinates(lat: 55.0, lon: 37.0),
          zoom: 14,
          bearing: 0,
          tilt: 0,
        ),
      );

      expect(notifyCount, 1);
      expect(controller.cameraPosition, isNotNull);
    });

    test('rapid camera updates are throttled', () {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // First update should pass
      controller.updateCameraPosition(
        CameraPosition(
          center: const Coordinates(lat: 55.0, lon: 37.0),
          zoom: 14,
          bearing: 0,
          tilt: 0,
        ),
      );
      expect(notifyCount, 1);

      // Rapid successive updates should be throttled
      for (var i = 0; i < 10; i++) {
        controller.updateCameraPosition(
          CameraPosition(
            center: Coordinates(lat: 55.0 + i * 0.001, lon: 37.0),
            zoom: 14,
            bearing: 0,
            tilt: 0,
          ),
        );
      }

      // Only 1 notification (from first call) due to throttle
      expect(notifyCount, 1);

      // Camera position should still be updated internally
      expect(controller.cameraPosition, isNotNull);
    });

    test('camera updates allowed after throttle interval', () async {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.updateCameraPosition(
        CameraPosition(
          center: const Coordinates(lat: 55.0, lon: 37.0),
          zoom: 14,
          bearing: 0,
          tilt: 0,
        ),
      );
      expect(notifyCount, 1);

      // Wait for throttle interval to pass
      await Future.delayed(const Duration(milliseconds: 110));

      controller.updateCameraPosition(
        CameraPosition(
          center: const Coordinates(lat: 56.0, lon: 38.0),
          zoom: 14,
          bearing: 0,
          tilt: 0,
        ),
      );

      // Second notification should occur after throttle
      expect(notifyCount, 2);
    });

    test('cameraPosition getter returns latest position', () {
      // Even when throttled, the position should be updated

      controller.updateCameraPosition(
        CameraPosition(
          center: const Coordinates(lat: 55.0, lon: 37.0),
          zoom: 14,
          bearing: 0,
          tilt: 0,
        ),
      );

      // Throttled update
      controller.updateCameraPosition(
        CameraPosition(
          center: const Coordinates(lat: 56.0, lon: 38.0),
          zoom: 15,
          bearing: 45,
          tilt: 30,
        ),
      );

      // Should return the latest position
      final position = controller.cameraPosition;
      expect(position?.center.lat, 56.0);
      expect(position?.center.lon, 38.0);
      expect(position?.zoom, 15);
      expect(position?.bearing, 45);
      expect(position?.tilt, 30);
    });

    test('throttle simulates ~10 notifications per second', () async {
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // Simulate 1 second of camera updates at 60 FPS
      const totalUpdates = 60;
      const intervalMs = 1000 ~/ totalUpdates;

      for (var i = 0; i < totalUpdates; i++) {
        controller.updateCameraPosition(
          CameraPosition(
            center: Coordinates(lat: 55.0 + i * 0.001, lon: 37.0),
            zoom: 14,
            bearing: 0,
            tilt: 0,
          ),
        );
        await Future.delayed(Duration(milliseconds: intervalMs));
      }

      // With 100ms throttle, we should get ~10 notifications per second
      // Allow some variance due to timing
      expect(notifyCount, greaterThanOrEqualTo(8));
      expect(notifyCount, lessThanOrEqualTo(12));
    });
  });

  group('CameraPosition', () {
    test('creates with all parameters', () {
      final position = CameraPosition(
        center: const Coordinates(lat: 55.7558, lon: 37.6173),
        zoom: 14.5,
        bearing: 45.0,
        tilt: 30.0,
      );

      expect(position.center.lat, 55.7558);
      expect(position.center.lon, 37.6173);
      expect(position.zoom, 14.5);
      expect(position.bearing, 45.0);
      expect(position.tilt, 30.0);
    });

    test('copyWith updates specified fields', () {
      final original = CameraPosition(
        center: const Coordinates(lat: 55.0, lon: 37.0),
        zoom: 14,
        bearing: 0,
        tilt: 0,
      );

      final updated = original.copyWith(zoom: 16, bearing: 90);

      expect(updated.center.lat, 55.0); // Unchanged
      expect(updated.center.lon, 37.0); // Unchanged
      expect(updated.zoom, 16); // Changed
      expect(updated.bearing, 90); // Changed
      expect(updated.tilt, 0); // Unchanged
    });

    test('equality check works correctly', () {
      final pos1 = CameraPosition(
        center: const Coordinates(lat: 55.0, lon: 37.0),
        zoom: 14,
        bearing: 0,
        tilt: 0,
      );

      final pos2 = CameraPosition(
        center: const Coordinates(lat: 55.0, lon: 37.0),
        zoom: 14,
        bearing: 0,
        tilt: 0,
      );

      final pos3 = CameraPosition(
        center: const Coordinates(lat: 56.0, lon: 38.0),
        zoom: 14,
        bearing: 0,
        tilt: 0,
      );

      expect(pos1, equals(pos2));
      expect(pos1, isNot(equals(pos3)));
    });
  });
}
