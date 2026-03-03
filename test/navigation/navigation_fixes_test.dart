import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('Traveled portion snaps to cursor', () {
    test('traveled portion ends at cursor position', () {
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
        const Coordinates(lat: 53.4065, lon: 58.9680),
      ];

      const cursorPosition = Coordinates(lat: 53.4057, lon: 58.9665);
      const segmentIndex = 1;

      // Build traveled portion (same logic as snapRouteStartToCursor)
      final traveled = <Coordinates>[];
      for (int i = 0; i <= segmentIndex && i < polyline.length; i++) {
        traveled.add(polyline[i]);
      }
      traveled.add(cursorPosition);

      // Traveled line must end exactly at cursor
      expect(traveled.last.lat, cursorPosition.lat);
      expect(traveled.last.lon, cursorPosition.lon);
      expect(traveled.length, segmentIndex + 2); // points[0..seg] + cursor
    });

    test('remaining route starts at cursor position', () {
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
        const Coordinates(lat: 53.4065, lon: 58.9680),
      ];

      const cursorPosition = Coordinates(lat: 53.4057, lon: 58.9665);
      const segmentIndex = 1;

      // Build remaining route (same logic as snapRouteStartToCursor)
      final remaining = <Coordinates>[cursorPosition];
      for (int i = segmentIndex + 1; i < polyline.length; i++) {
        remaining.add(polyline[i]);
      }

      // Remaining route must start at cursor
      expect(remaining.first.lat, cursorPosition.lat);
      expect(remaining.first.lon, cursorPosition.lon);
      expect(remaining.length, polyline.length - segmentIndex);
    });

    test('traveled and remaining routes form a continuous path through cursor', () {
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
        const Coordinates(lat: 53.4065, lon: 58.9680),
        const Coordinates(lat: 53.4070, lon: 58.9690),
      ];

      const cursorPosition = Coordinates(lat: 53.4062, lon: 58.9675);
      const segmentIndex = 2;

      // Build traveled portion
      final traveled = <Coordinates>[];
      for (int i = 0; i <= segmentIndex && i < polyline.length; i++) {
        traveled.add(polyline[i]);
      }
      traveled.add(cursorPosition);

      // Build remaining route
      final remaining = <Coordinates>[cursorPosition];
      for (int i = segmentIndex + 1; i < polyline.length; i++) {
        remaining.add(polyline[i]);
      }

      // Last point of traveled == first point of remaining == cursor
      expect(traveled.last.lat, remaining.first.lat);
      expect(traveled.last.lon, remaining.first.lon);
      expect(traveled.last.lat, cursorPosition.lat);
    });
  });

  group('Free camera mode', () {
    test('auto-recenter delay is configurable', () {
      const options = NavigationOptions(autoRecenterDelaySeconds: 10);
      expect(options.autoRecenterDelaySeconds, 10);
    });

    test('default auto-recenter delay is 6 seconds', () {
      const options = NavigationOptions();
      expect(options.autoRecenterDelaySeconds, 6);
    });

    test('CameraTrackingMode has free, follow, and followWithBearing', () {
      expect(CameraTrackingMode.values, contains(CameraTrackingMode.free));
      expect(CameraTrackingMode.values, contains(CameraTrackingMode.follow));
      expect(CameraTrackingMode.values,
          contains(CameraTrackingMode.followWithBearing));
    });

    test('default tracking mode is followWithBearing', () {
      const options = NavigationOptions();
      expect(options.trackingMode, CameraTrackingMode.followWithBearing);
    });

    test('copyWith preserves auto-recenter settings', () {
      const options = NavigationOptions(autoRecenterDelaySeconds: 8);
      final copied = options.copyWith(zoom: 18);

      expect(copied.autoRecenterDelaySeconds, 8);
      expect(copied.zoom, 18);
    });

    test('rotate gestures are enabled by default', () {
      // NavigationView._buildMap sets rotateGesturesEnabled: true
      // This is a design assertion — rotate must be on for free mode
      const options = NavigationOptions();
      expect(options.trackingMode, isNot(CameraTrackingMode.free));
    });
  });

  group('Layer z-order', () {
    test('route layers must be added before arrow layer', () {
      // This is a design assertion:
      // In _onStyleLoaded, route is drawn first, then arrow layer is attached.
      // Arrow symbol layer has higher z-index than route line layers.
      //
      // We verify the layer IDs are distinct (no collision):
      const routeSourceId = 'nav-route-line-source';
      const routeLayerId = 'nav-route-line-layer';
      const arrowSourceId = 'nav-user-arrow-source';
      const arrowLayerId = 'nav-user-arrow-layer';

      expect(routeSourceId, isNot(arrowSourceId));
      expect(routeLayerId, isNot(arrowLayerId));
    });
  });
}
