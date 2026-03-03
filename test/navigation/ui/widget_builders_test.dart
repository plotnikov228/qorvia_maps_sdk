import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/navigation_options.dart';
import 'package:qorvia_maps_sdk/src/navigation/ui/widget_builders.dart';
import 'package:qorvia_maps_sdk/src/navigation/ui/widget_data.dart';

void main() {
  group('WidgetConfig', () {
    test('creates with default values', () {
      const config = WidgetConfig();

      expect(config.alignment, Alignment.center);
      expect(config.padding, EdgeInsets.zero);
      expect(config.enabled, true);
    });

    test('creates with custom values', () {
      const config = WidgetConfig(
        alignment: Alignment.bottomLeft,
        padding: EdgeInsets.all(16),
        enabled: false,
      );

      expect(config.alignment, Alignment.bottomLeft);
      expect(config.padding, const EdgeInsets.all(16));
      expect(config.enabled, false);
    });

    test('copyWith preserves unchanged values', () {
      const original = WidgetConfig(
        alignment: Alignment.topRight,
        padding: EdgeInsets.only(top: 8),
        enabled: true,
      );

      final copy = original.copyWith(enabled: false);

      expect(copy.alignment, Alignment.topRight);
      expect(copy.padding, const EdgeInsets.only(top: 8));
      expect(copy.enabled, false);
    });

    test('copyWith replaces all values', () {
      const original = WidgetConfig();

      final copy = original.copyWith(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.all(24),
        enabled: false,
      );

      expect(copy.alignment, Alignment.bottomRight);
      expect(copy.padding, const EdgeInsets.all(24));
      expect(copy.enabled, false);
    });

    test('toString returns readable format', () {
      const config = WidgetConfig(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        enabled: true,
      );

      final str = config.toString();
      expect(str, contains('alignment'));
      expect(str, contains('padding'));
      expect(str, contains('enabled'));
    });
  });

  group('NavigationWidgetsConfig', () {
    test('creates with default values', () {
      const config = NavigationWidgetsConfig();

      // All widgets enabled by default
      expect(config.speedWidgetConfig.enabled, true);
      expect(config.etaWidgetConfig.enabled, true);
      expect(config.turnWidgetConfig.enabled, true);
      expect(config.recenterWidgetConfig.enabled, true);

      // No custom builders by default
      expect(config.speedWidgetBuilder, isNull);
      expect(config.etaWidgetBuilder, isNull);
      expect(config.turnWidgetBuilder, isNull);
      expect(config.recenterWidgetBuilder, isNull);
    });

    test('default speed widget config is top-right (Yandex Navigator style)', () {
      const config = NavigationWidgetsConfig();

      expect(config.speedWidgetConfig.alignment, Alignment.topRight);
    });

    test('default eta widget config is bottom-center', () {
      const config = NavigationWidgetsConfig();

      expect(config.etaWidgetConfig.alignment, Alignment.bottomCenter);
    });

    test('default turn widget config is top-left (Yandex Navigator style)', () {
      const config = NavigationWidgetsConfig();

      expect(config.turnWidgetConfig.alignment, Alignment.topLeft);
    });

    test('default colors are Yandex Navigator style', () {
      const config = NavigationWidgetsConfig();

      // Turn panel: blue background, white text
      expect(config.colors.turnPanelBackground, const Color(0xFF2979FF));
      expect(config.colors.turnPanelText, Colors.white);

      // Speed: white background, dark text
      expect(config.colors.speedBackground, Colors.white);
      expect(config.colors.speedText, const Color(0xFF333333));
      expect(config.colors.speedOverLimit, const Color(0xFFE53935));
      expect(config.colors.speedLimitBorder, const Color(0xFFE53935));
    });

    test('default recenter widget config is bottom-right', () {
      const config = NavigationWidgetsConfig();

      expect(config.recenterWidgetConfig.alignment, Alignment.bottomRight);
    });

    test('creates with custom builder', () {
      Widget customSpeed(SpeedWidgetData data) => const Text('Custom');

      final config = NavigationWidgetsConfig(
        speedWidgetBuilder: customSpeed,
      );

      expect(config.speedWidgetBuilder, isNotNull);
      expect(config.speedWidgetBuilder, customSpeed);
    });

    test('creates with disabled widget', () {
      const config = NavigationWidgetsConfig(
        etaWidgetConfig: WidgetConfig(enabled: false),
      );

      expect(config.etaWidgetConfig.enabled, false);
      expect(config.speedWidgetConfig.enabled, true);
    });

    test('creates with custom positioning', () {
      const config = NavigationWidgetsConfig(
        turnWidgetConfig: WidgetConfig(
          alignment: Alignment.topLeft,
          padding: EdgeInsets.only(left: 20, top: 40),
        ),
      );

      expect(config.turnWidgetConfig.alignment, Alignment.topLeft);
      expect(
          config.turnWidgetConfig.padding, const EdgeInsets.only(left: 20, top: 40));
    });

    test('copyWith preserves unchanged values', () {
      Widget customSpeed(SpeedWidgetData data) => const Text('Speed');

      final original = NavigationWidgetsConfig(
        speedWidgetBuilder: customSpeed,
        etaWidgetConfig: const WidgetConfig(enabled: false),
      );

      final copy = original.copyWith(
        turnWidgetConfig: const WidgetConfig(alignment: Alignment.center),
      );

      expect(copy.speedWidgetBuilder, customSpeed);
      expect(copy.etaWidgetConfig.enabled, false);
      expect(copy.turnWidgetConfig.alignment, Alignment.center);
    });

    test('copyWith replaces builders correctly', () {
      Widget oldBuilder(SpeedWidgetData data) => const Text('Old');
      Widget newBuilder(SpeedWidgetData data) => const Text('New');

      final original = NavigationWidgetsConfig(
        speedWidgetBuilder: oldBuilder,
      );

      final copy = original.copyWith(
        speedWidgetBuilder: newBuilder,
      );

      expect(copy.speedWidgetBuilder, newBuilder);
    });

    test('toString returns readable format', () {
      const config = NavigationWidgetsConfig(
        speedWidgetConfig: WidgetConfig(enabled: true),
        etaWidgetConfig: WidgetConfig(enabled: false),
      );

      final str = config.toString();
      expect(str, contains('speed'));
      expect(str, contains('eta'));
      expect(str, contains('turn'));
      expect(str, contains('recenter'));
    });
  });

  group('NavigationWidgetColors', () {
    test('creates with default values', () {
      const colors = NavigationWidgetColors();

      expect(colors.turnPanelBackground, const Color(0xFF2979FF));
      expect(colors.turnPanelText, Colors.white);
      expect(colors.speedBackground, Colors.white);
      expect(colors.speedText, const Color(0xFF333333));
      expect(colors.speedOverLimit, const Color(0xFFE53935));
      expect(colors.speedLimitBorder, const Color(0xFFE53935));
    });

    test('creates with custom values', () {
      const colors = NavigationWidgetColors(
        turnPanelBackground: Colors.green,
        turnPanelText: Colors.black,
        speedBackground: Colors.grey,
        speedText: Colors.blue,
        speedOverLimit: Colors.orange,
        speedLimitBorder: Colors.purple,
      );

      expect(colors.turnPanelBackground, Colors.green);
      expect(colors.turnPanelText, Colors.black);
      expect(colors.speedBackground, Colors.grey);
      expect(colors.speedText, Colors.blue);
      expect(colors.speedOverLimit, Colors.orange);
      expect(colors.speedLimitBorder, Colors.purple);
    });

    test('copyWith preserves unchanged values', () {
      const original = NavigationWidgetColors(
        turnPanelBackground: Colors.blue,
        speedText: Colors.red,
      );

      final copy = original.copyWith(turnPanelText: Colors.yellow);

      expect(copy.turnPanelBackground, Colors.blue);
      expect(copy.turnPanelText, Colors.yellow);
      expect(copy.speedText, Colors.red);
    });

    test('copyWith replaces all values', () {
      const original = NavigationWidgetColors();

      final copy = original.copyWith(
        turnPanelBackground: Colors.green,
        turnPanelText: Colors.black,
        speedBackground: Colors.grey,
        speedText: Colors.blue,
        speedOverLimit: Colors.orange,
        speedLimitBorder: Colors.purple,
      );

      expect(copy.turnPanelBackground, Colors.green);
      expect(copy.turnPanelText, Colors.black);
      expect(copy.speedBackground, Colors.grey);
      expect(copy.speedText, Colors.blue);
      expect(copy.speedOverLimit, Colors.orange);
      expect(copy.speedLimitBorder, Colors.purple);
    });

    test('toString returns readable format', () {
      const colors = NavigationWidgetColors();

      final str = colors.toString();
      expect(str, contains('turnBg'));
      expect(str, contains('speedBg'));
    });
  });

  group('NavigationWidgetsConfig colors integration', () {
    test('config includes colors', () {
      const colors = NavigationWidgetColors(
        turnPanelBackground: Colors.purple,
      );

      const config = NavigationWidgetsConfig(colors: colors);

      expect(config.colors.turnPanelBackground, Colors.purple);
    });

    test('copyWith preserves colors', () {
      const colors = NavigationWidgetColors(
        turnPanelBackground: Colors.orange,
      );

      const original = NavigationWidgetsConfig(colors: colors);

      final copy = original.copyWith(
        speedWidgetConfig: const WidgetConfig(enabled: false),
      );

      expect(copy.colors.turnPanelBackground, Colors.orange);
    });

    test('copyWith replaces colors', () {
      const original = NavigationWidgetsConfig();

      final copy = original.copyWith(
        colors: const NavigationWidgetColors(
          speedOverLimit: Colors.pink,
        ),
      );

      expect(copy.colors.speedOverLimit, Colors.pink);
    });
  });

  group('Builder typedef tests', () {
    test('SpeedWidgetBuilder signature works', () {
      SpeedWidgetBuilder builder = (SpeedWidgetData data) {
        return Text('${data.currentSpeedKmh.round()} km/h');
      };

      const testData = SpeedWidgetData(
        currentSpeedKmh: 60.0,
        speedLimit: 80.0,
        isOverLimit: false,
      );

      final widget = builder(testData);
      expect(widget, isA<Text>());
    });

    test('EtaWidgetBuilder signature works', () {
      EtaWidgetBuilder builder = (EtaWidgetData data, VoidCallback? onClose) {
        return Column(
          children: [
            Text(data.formattedEta),
            if (onClose != null)
              TextButton(onPressed: onClose, child: const Text('Close')),
          ],
        );
      };

      final testData = EtaWidgetData(
        formattedEta: '15:00',
        formattedDuration: '30 min',
        formattedDistance: '20 km',
        durationRemaining: const Duration(minutes: 30),
        distanceRemaining: 20000,
        estimatedArrival: DateTime.now(),
        progress: 0.5,
      );

      final widget = builder(testData, () {});
      expect(widget, isA<Column>());
    });

    test('TurnWidgetBuilder signature works', () {
      TurnWidgetBuilder builder = (TurnWidgetData data) {
        return Row(
          children: [
            Text(data.maneuver),
            Text(data.instruction),
          ],
        );
      };

      const testData = TurnWidgetData(
        instruction: 'Turn right',
        maneuver: 'turn-right',
        formattedDistance: '100 m',
        distanceToManeuver: 100.0,
        hasManeuver: true,
        stepIndex: 0,
      );

      final widget = builder(testData);
      expect(widget, isA<Row>());
    });

    test('RecenterWidgetBuilder signature works', () {
      RecenterWidgetBuilder builder =
          (RecenterWidgetData data, VoidCallback onPressed) {
        return FloatingActionButton(
          onPressed: data.isVisible ? onPressed : null,
          child: const Icon(Icons.my_location),
        );
      };

      const testData = RecenterWidgetData(
        currentMode: CameraTrackingMode.free,
        isVisible: true,
      );

      final widget = builder(testData, () {});
      expect(widget, isA<FloatingActionButton>());
    });
  });
}
