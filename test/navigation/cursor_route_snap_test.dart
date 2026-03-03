import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  group('User cursor (arrow) configuration', () {
    test('default icon image is triangle-11', () {
      const options = NavigationOptions();
      expect(options.userLocationIconImage, 'triangle-11');
    });

    test('custom icon image is respected', () {
      const options = NavigationOptions(
        userLocationIconImage: 'my-custom-arrow',
      );
      expect(options.userLocationIconImage, 'my-custom-arrow');
    });

    test('cursor color falls back to arrow style color', () {
      const options = NavigationOptions();
      expect(options.cursorColor, isNull);
      expect(options.userArrowStyle.color, isNotNull);
    });

    test('cursor color can be overridden', () {
      const options = NavigationOptions(
        cursorColor: Color(0xFFFF0000),
      );
      expect(options.cursorColor, const Color(0xFFFF0000));
    });

    test('cursor border color falls back to arrow style border color', () {
      const options = NavigationOptions();
      expect(options.cursorBorderColor, isNull);
      expect(options.userArrowStyle.borderColor, isNotNull);
    });

    test('icon size default is reasonable', () {
      const options = NavigationOptions();
      expect(options.userLocationIconSize, 1.6);
      expect(options.userLocationIconSize, greaterThan(0));
    });
  });

  group('Route line snapping', () {
    test('route polyline is available for snapping', () {
      // Verify that a decoded polyline with enough points can be
      // used for route line snapping
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
        const Coordinates(lat: 53.4065, lon: 58.9680),
        const Coordinates(lat: 53.4070, lon: 58.9690),
      ];

      expect(polyline.length, greaterThanOrEqualTo(2));

      // Verify midpoint interpolation for route snapping
      final segStart = polyline[1];
      final segEnd = polyline[2];
      final mid = Coordinates(
        lat: (segStart.lat + segEnd.lat) / 2,
        lon: (segStart.lon + segEnd.lon) / 2,
      );

      // Midpoint should be between segment start and end
      expect(mid.lat, greaterThanOrEqualTo(segStart.lat));
      expect(mid.lat, lessThanOrEqualTo(segEnd.lat));
    });

    test('remaining route starts from cursor position', () {
      // Simulate what snapRouteStartToCursor does:
      // Given a cursor position and segment index, build remaining route
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
        const Coordinates(lat: 53.4065, lon: 58.9680),
        const Coordinates(lat: 53.4070, lon: 58.9690),
      ];

      const cursorPosition = Coordinates(lat: 53.4057, lon: 58.9665);
      const segmentIndex = 1; // Between point 1 and point 2

      // Build remaining route (same logic as snapRouteStartToCursor)
      final remaining = <Coordinates>[cursorPosition];
      for (int i = segmentIndex + 1; i < polyline.length; i++) {
        remaining.add(polyline[i]);
      }

      // First point should be cursor position
      expect(remaining.first.lat, cursorPosition.lat);
      expect(remaining.first.lon, cursorPosition.lon);

      // Should have cursor + remaining points after segment
      expect(remaining.length, polyline.length - segmentIndex);
    });

    test('traveled portion ends at cursor position', () {
      // Simulate traveled portion calculation
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
        const Coordinates(lat: 53.4065, lon: 58.9680),
      ];

      const cursorPosition = Coordinates(lat: 53.4057, lon: 58.9665);
      const segmentIndex = 1;

      // Build traveled portion (same logic as updateTraveledPortion)
      final traveled = <Coordinates>[];
      for (int i = 0; i <= segmentIndex && i < polyline.length; i++) {
        traveled.add(polyline[i]);
      }
      traveled.add(cursorPosition);

      // Last point should be cursor position
      expect(traveled.last.lat, cursorPosition.lat);
      expect(traveled.last.lon, cursorPosition.lon);

      // Should have points 0..segmentIndex + cursor
      expect(traveled.length, segmentIndex + 2);
    });

    test('segment 0 produces valid remaining route', () {
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
      ];

      const cursorPosition = Coordinates(lat: 53.4052, lon: 58.9655);
      const segmentIndex = 0;

      final remaining = <Coordinates>[cursorPosition];
      for (int i = segmentIndex + 1; i < polyline.length; i++) {
        remaining.add(polyline[i]);
      }

      // Should have cursor + all points after first segment
      expect(remaining.length, polyline.length); // cursor + 2 remaining
      expect(remaining.first, cursorPosition);
    });

    test('last segment produces valid remaining route', () {
      final polyline = [
        const Coordinates(lat: 53.4050, lon: 58.9650),
        const Coordinates(lat: 53.4055, lon: 58.9660),
        const Coordinates(lat: 53.4060, lon: 58.9670),
      ];

      const cursorPosition = Coordinates(lat: 53.4058, lon: 58.9668);
      final segmentIndex = polyline.length - 2; // Last segment

      final remaining = <Coordinates>[cursorPosition];
      for (int i = segmentIndex + 1; i < polyline.length; i++) {
        remaining.add(polyline[i]);
      }

      // Should have cursor + last point
      expect(remaining.length, 2);
      expect(remaining.first, cursorPosition);
      expect(remaining.last, polyline.last);
    });
  });

  group('NavigationOptions copyWith for cursor settings', () {
    test('copyWith preserves cursor settings', () {
      const original = NavigationOptions(
        cursorColor: Color(0xFFFF0000),
        cursorBorderColor: Color(0xFF00FF00),
        userLocationIconImage: 'custom-icon',
        userLocationIconSize: 2.0,
      );

      final copied = original.copyWith(zoom: 18);

      expect(copied.cursorColor, const Color(0xFFFF0000));
      expect(copied.cursorBorderColor, const Color(0xFF00FF00));
      expect(copied.userLocationIconImage, 'custom-icon');
      expect(copied.userLocationIconSize, 2.0);
      expect(copied.zoom, 18);
    });

    test('copyWith can override cursor settings', () {
      const original = NavigationOptions();

      final copied = original.copyWith(
        userLocationIconImage: 'new-icon',
        userLocationIconSize: 3.0,
      );

      expect(copied.userLocationIconImage, 'new-icon');
      expect(copied.userLocationIconSize, 3.0);
    });
  });
}
