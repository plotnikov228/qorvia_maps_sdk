import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/map/ui/widget_builders.dart';
import 'package:qorvia_maps_sdk/src/navigation/ui/widget_data.dart';

void main() {
  group('MapWidgetsConfig', () {
    test('creates with default values', () {
      const config = MapWidgetsConfig();

      // All widgets disabled by default
      expect(config.zoomControlsConfig.enabled, false);
      expect(config.compassConfig.enabled, false);
      expect(config.scaleConfig.enabled, false);
      expect(config.userLocationButtonConfig.enabled, false);

      // No custom builders by default
      expect(config.zoomControlsBuilder, isNull);
      expect(config.compassBuilder, isNull);
      expect(config.scaleBuilder, isNull);
      expect(config.userLocationButtonBuilder, isNull);
    });

    test('default zoom controls config is center-right', () {
      const config = MapWidgetsConfig();

      expect(config.zoomControlsConfig.alignment, Alignment.centerRight);
    });

    test('default compass config is top-right', () {
      const config = MapWidgetsConfig();

      expect(config.compassConfig.alignment, Alignment.topRight);
    });

    test('default scale config is bottom-left', () {
      const config = MapWidgetsConfig();

      expect(config.scaleConfig.alignment, Alignment.bottomLeft);
    });

    test('default user location button config is bottom-right', () {
      const config = MapWidgetsConfig();

      expect(config.userLocationButtonConfig.alignment, Alignment.bottomRight);
    });

    test('creates with enabled widget', () {
      const config = MapWidgetsConfig(
        zoomControlsConfig: WidgetConfig(enabled: true),
      );

      expect(config.zoomControlsConfig.enabled, true);
      expect(config.compassConfig.enabled, false);
    });

    test('creates with custom builder', () {
      Widget customZoom(MapControlsWidgetData data, VoidCallback onIn,
          VoidCallback onOut) {
        return const Text('Custom');
      }

      final config = MapWidgetsConfig(
        zoomControlsBuilder: customZoom,
        zoomControlsConfig: const WidgetConfig(enabled: true),
      );

      expect(config.zoomControlsBuilder, isNotNull);
      expect(config.zoomControlsBuilder, customZoom);
    });

    test('creates with custom positioning', () {
      const config = MapWidgetsConfig(
        compassConfig: WidgetConfig(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.only(left: 20, top: 40),
          enabled: true,
        ),
      );

      expect(config.compassConfig.alignment, Alignment.topLeft);
      expect(
          config.compassConfig.padding, const EdgeInsets.only(left: 20, top: 40));
      expect(config.compassConfig.enabled, true);
    });

    test('copyWith preserves unchanged values', () {
      Widget customCompass(double bearing, VoidCallback onReset) {
        return const Icon(Icons.navigation);
      }

      final original = MapWidgetsConfig(
        compassBuilder: customCompass,
        compassConfig: const WidgetConfig(enabled: true),
        scaleConfig: const WidgetConfig(enabled: true),
      );

      final copy = original.copyWith(
        zoomControlsConfig: const WidgetConfig(enabled: true),
      );

      expect(copy.compassBuilder, customCompass);
      expect(copy.compassConfig.enabled, true);
      expect(copy.scaleConfig.enabled, true);
      expect(copy.zoomControlsConfig.enabled, true);
    });

    test('copyWith replaces builders correctly', () {
      Widget oldBuilder(double bearing, VoidCallback onReset) {
        return const Text('Old');
      }

      Widget newBuilder(double bearing, VoidCallback onReset) {
        return const Text('New');
      }

      final original = MapWidgetsConfig(
        compassBuilder: oldBuilder,
      );

      final copy = original.copyWith(
        compassBuilder: newBuilder,
      );

      expect(copy.compassBuilder, newBuilder);
    });

    test('toString returns readable format', () {
      const config = MapWidgetsConfig(
        zoomControlsConfig: WidgetConfig(enabled: true),
        compassConfig: WidgetConfig(enabled: false),
      );

      final str = config.toString();
      expect(str, contains('zoom'));
      expect(str, contains('compass'));
      expect(str, contains('scale'));
      expect(str, contains('location'));
    });
  });

  group('WidgetConfig export', () {
    test('WidgetConfig is exported from map widget_builders', () {
      const config = WidgetConfig(
        alignment: Alignment.center,
        padding: EdgeInsets.all(8),
        enabled: true,
      );

      expect(config, isA<WidgetConfig>());
    });
  });

  group('Builder typedef tests', () {
    test('ZoomControlsBuilder signature works', () {
      ZoomControlsBuilder builder = (
        MapControlsWidgetData data,
        VoidCallback onZoomIn,
        VoidCallback onZoomOut,
      ) {
        return Column(
          children: [
            IconButton(
              onPressed: data.canZoomIn ? onZoomIn : null,
              icon: const Icon(Icons.add),
            ),
            Text('Zoom: ${data.currentZoom.round()}'),
            IconButton(
              onPressed: data.canZoomOut ? onZoomOut : null,
              icon: const Icon(Icons.remove),
            ),
          ],
        );
      };

      const testData = MapControlsWidgetData(
        currentZoom: 15.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: true,
        isTracking: false,
        minZoom: 2.0,
        maxZoom: 20.0,
      );

      final widget = builder(testData, () {}, () {});
      expect(widget, isA<Column>());
    });

    test('CompassBuilder signature works', () {
      CompassBuilder builder = (double bearing, VoidCallback onReset) {
        return GestureDetector(
          onTap: onReset,
          child: Transform.rotate(
            angle: -bearing * 3.14159 / 180,
            child: const Icon(Icons.navigation),
          ),
        );
      };

      final widget = builder(45.0, () {});
      expect(widget, isA<GestureDetector>());
    });

    test('ScaleBuilder signature works', () {
      ScaleBuilder builder = (double metersPerPixel, double zoom) {
        final distance = 100 * metersPerPixel;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 100, height: 2, color: Colors.black),
            Text('${distance.round()}m'),
          ],
        );
      };

      final widget = builder(10.5, 15.0);
      expect(widget, isA<Row>());
    });

    test('UserLocationButtonBuilder signature works', () {
      UserLocationButtonBuilder builder = (bool isTracking, VoidCallback onToggle) {
        return FloatingActionButton(
          mini: true,
          onPressed: onToggle,
          backgroundColor: isTracking ? Colors.blue : Colors.white,
          child: Icon(
            isTracking ? Icons.my_location : Icons.location_searching,
          ),
        );
      };

      final widget = builder(true, () {});
      expect(widget, isA<FloatingActionButton>());
    });
  });

  group('MapControlsWidgetData in builder context', () {
    test('canZoomIn/Out work correctly in builders', () {
      bool zoomInEnabled = false;
      bool zoomOutEnabled = false;

      ZoomControlsBuilder builder = (
        MapControlsWidgetData data,
        VoidCallback onZoomIn,
        VoidCallback onZoomOut,
      ) {
        zoomInEnabled = data.canZoomIn;
        zoomOutEnabled = data.canZoomOut;
        return const SizedBox();
      };

      // Test at middle zoom
      const middleData = MapControlsWidgetData(
        currentZoom: 10.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
        minZoom: 2.0,
        maxZoom: 18.0,
      );
      builder(middleData, () {}, () {});
      expect(zoomInEnabled, true);
      expect(zoomOutEnabled, true);

      // Test at max zoom
      const maxData = MapControlsWidgetData(
        currentZoom: 18.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
        minZoom: 2.0,
        maxZoom: 18.0,
      );
      builder(maxData, () {}, () {});
      expect(zoomInEnabled, false);
      expect(zoomOutEnabled, true);

      // Test at min zoom
      const minData = MapControlsWidgetData(
        currentZoom: 2.0,
        currentBearing: 0.0,
        currentTilt: 0.0,
        isUserLocationEnabled: false,
        isTracking: false,
        minZoom: 2.0,
        maxZoom: 18.0,
      );
      builder(minData, () {}, () {});
      expect(zoomInEnabled, true);
      expect(zoomOutEnabled, false);
    });

    test('shouldShowCompass works correctly in builders', () {
      bool compassVisible = false;

      CompassBuilder builder = (double bearing, VoidCallback onReset) {
        // Simulate checking visibility based on bearing
        compassVisible = bearing.abs() > 1;
        return const SizedBox();
      };

      // Test with significant bearing
      builder(45.0, () {});
      expect(compassVisible, true);

      // Test with near-zero bearing
      builder(0.5, () {});
      expect(compassVisible, false);
    });
  });
}
