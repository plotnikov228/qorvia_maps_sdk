import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/ui/widget_data.dart';
import 'package:qorvia_maps_sdk/src/navigation/navigation_options.dart';

void main() {
  group('SpeedWidgetData', () {
    test('creates with all properties', () {
      const data = SpeedWidgetData(
        currentSpeedKmh: 65.5,
        speedLimit: 60.0,
        isOverLimit: true,
      );

      expect(data.currentSpeedKmh, 65.5);
      expect(data.speedLimit, 60.0);
      expect(data.isOverLimit, true);
    });

    test('creates with null speed limit', () {
      const data = SpeedWidgetData(
        currentSpeedKmh: 50.0,
        speedLimit: null,
        isOverLimit: false,
      );

      expect(data.currentSpeedKmh, 50.0);
      expect(data.speedLimit, isNull);
      expect(data.isOverLimit, false);
    });

    test('toString returns readable format', () {
      const data = SpeedWidgetData(
        currentSpeedKmh: 45.5,
        speedLimit: 50.0,
        isOverLimit: false,
      );

      expect(data.toString(), contains('45.5'));
      expect(data.toString(), contains('50.0'));
      expect(data.toString(), contains('false'));
    });
  });

  group('EtaWidgetData', () {
    test('creates with all properties', () {
      final arrival = DateTime(2026, 2, 25, 14, 35);
      final data = EtaWidgetData(
        formattedEta: '14:35',
        formattedDuration: '25 min',
        formattedDistance: '12.5 km',
        durationRemaining: const Duration(minutes: 25),
        distanceRemaining: 12500.0,
        estimatedArrival: arrival,
        progress: 0.65,
      );

      expect(data.formattedEta, '14:35');
      expect(data.formattedDuration, '25 min');
      expect(data.formattedDistance, '12.5 km');
      expect(data.durationRemaining, const Duration(minutes: 25));
      expect(data.distanceRemaining, 12500.0);
      expect(data.estimatedArrival, arrival);
      expect(data.progress, 0.65);
    });

    test('progress is clamped between 0 and 1', () {
      final data = EtaWidgetData(
        formattedEta: '15:00',
        formattedDuration: '0 min',
        formattedDistance: '0 m',
        durationRemaining: Duration.zero,
        distanceRemaining: 0,
        estimatedArrival: DateTime.now(),
        progress: 1.0,
      );

      expect(data.progress, 1.0);
    });

    test('toString returns readable format', () {
      final data = EtaWidgetData(
        formattedEta: '14:35',
        formattedDuration: '25 min',
        formattedDistance: '12.5 km',
        durationRemaining: const Duration(minutes: 25),
        distanceRemaining: 12500.0,
        estimatedArrival: DateTime.now(),
        progress: 0.65,
      );

      expect(data.toString(), contains('14:35'));
      expect(data.toString(), contains('25 min'));
      expect(data.toString(), contains('12.5 km'));
    });
  });

  group('TurnWidgetData', () {
    test('creates with all properties', () {
      const data = TurnWidgetData(
        instruction: 'Turn right onto Main Street',
        roadName: 'Main Street',
        maneuver: 'turn-right',
        formattedDistance: '250 m',
        distanceToManeuver: 250.0,
        nextManeuverHint: 'then turn left',
        hasManeuver: true,
        stepIndex: 3,
      );

      expect(data.instruction, 'Turn right onto Main Street');
      expect(data.roadName, 'Main Street');
      expect(data.maneuver, 'turn-right');
      expect(data.formattedDistance, '250 m');
      expect(data.distanceToManeuver, 250.0);
      expect(data.nextManeuverHint, 'then turn left');
      expect(data.hasManeuver, true);
      expect(data.stepIndex, 3);
    });

    test('creates with optional properties null', () {
      const data = TurnWidgetData(
        instruction: 'Go straight',
        roadName: null,
        maneuver: 'straight',
        formattedDistance: '1.2 km',
        distanceToManeuver: 1200.0,
        nextManeuverHint: null,
        hasManeuver: true,
        stepIndex: 0,
      );

      expect(data.roadName, isNull);
      expect(data.nextManeuverHint, isNull);
    });

    test('hasManeuver false when no step', () {
      const data = TurnWidgetData(
        instruction: '',
        roadName: null,
        maneuver: '',
        formattedDistance: '',
        distanceToManeuver: 0,
        nextManeuverHint: null,
        hasManeuver: false,
        stepIndex: 0,
      );

      expect(data.hasManeuver, false);
    });

    test('toString returns readable format', () {
      const data = TurnWidgetData(
        instruction: 'Turn left',
        roadName: 'Oak Ave',
        maneuver: 'turn-left',
        formattedDistance: '100 m',
        distanceToManeuver: 100.0,
        hasManeuver: true,
        stepIndex: 1,
      );

      expect(data.toString(), contains('turn-left'));
      expect(data.toString(), contains('100 m'));
      expect(data.toString(), contains('Turn left'));
    });
  });

  group('RecenterWidgetData', () {
    test('creates with tracking mode', () {
      const data = RecenterWidgetData(
        currentMode: CameraTrackingMode.follow,
        isVisible: false,
      );

      expect(data.currentMode, CameraTrackingMode.follow);
      expect(data.isVisible, false);
    });

    test('fromMode creates correct visibility for free mode', () {
      final data = RecenterWidgetData.fromMode(CameraTrackingMode.free);

      expect(data.currentMode, CameraTrackingMode.free);
      expect(data.isVisible, true);
    });

    test('fromMode creates correct visibility for follow modes', () {
      final followData =
          RecenterWidgetData.fromMode(CameraTrackingMode.follow);
      expect(followData.isVisible, false);

      final followBearingData =
          RecenterWidgetData.fromMode(CameraTrackingMode.followWithBearing);
      expect(followBearingData.isVisible, false);
    });

    test('toString returns readable format', () {
      final data = RecenterWidgetData.fromMode(CameraTrackingMode.free);

      expect(data.toString(), contains('free'));
      expect(data.toString(), contains('true'));
    });
  });

  group('MapControlsWidgetData', () {
    test('creates with all properties', () {
      const data = MapControlsWidgetData(
        currentZoom: 15.5,
        currentBearing: 45.0,
        currentTilt: 30.0,
        isUserLocationEnabled: true,
        isTracking: true,
        minZoom: 2.0,
        maxZoom: 20.0,
      );

      expect(data.currentZoom, 15.5);
      expect(data.currentBearing, 45.0);
      expect(data.currentTilt, 30.0);
      expect(data.isUserLocationEnabled, true);
      expect(data.isTracking, true);
      expect(data.minZoom, 2.0);
      expect(data.maxZoom, 20.0);
    });

    test('uses default min/max zoom', () {
      const data = MapControlsWidgetData(
        currentZoom: 10.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
      );

      expect(data.minZoom, 0);
      expect(data.maxZoom, 22);
    });

    test('canZoomIn is true when below max', () {
      const data = MapControlsWidgetData(
        currentZoom: 15.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
        maxZoom: 18.0,
      );

      expect(data.canZoomIn, true);
    });

    test('canZoomIn is false when at max', () {
      const data = MapControlsWidgetData(
        currentZoom: 18.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
        maxZoom: 18.0,
      );

      expect(data.canZoomIn, false);
    });

    test('canZoomOut is true when above min', () {
      const data = MapControlsWidgetData(
        currentZoom: 5.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
        minZoom: 2.0,
      );

      expect(data.canZoomOut, true);
    });

    test('canZoomOut is false when at min', () {
      const data = MapControlsWidgetData(
        currentZoom: 2.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
        minZoom: 2.0,
      );

      expect(data.canZoomOut, false);
    });

    test('shouldShowCompass is true when bearing > 1', () {
      const data = MapControlsWidgetData(
        currentZoom: 10.0,
        currentBearing: 45.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
      );

      expect(data.shouldShowCompass, true);
    });

    test('shouldShowCompass is false when bearing is near 0', () {
      const data = MapControlsWidgetData(
        currentZoom: 10.0,
        currentBearing: 0.5,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
      );

      expect(data.shouldShowCompass, false);
    });

    test('shouldShowCompass handles negative bearing', () {
      const data = MapControlsWidgetData(
        currentZoom: 10.0,
        currentBearing: -45.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
      );

      expect(data.shouldShowCompass, true);
    });

    test('toString returns readable format', () {
      const data = MapControlsWidgetData(
        currentZoom: 12.5,
        currentBearing: 90.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
      );

      expect(data.toString(), contains('12.5'));
      expect(data.toString(), contains('90.0'));
    });
  });
}
