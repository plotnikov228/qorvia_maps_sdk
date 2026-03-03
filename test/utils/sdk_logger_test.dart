import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/utils/sdk_logger.dart';
import 'package:qorvia_maps_sdk/src/navigation/navigation_logger.dart';

void main() {
  setUp(() {
    // Reset to default state before each test
    SdkLogger.reset();
  });

  group('SdkLogger level configuration', () {
    test('default level is info', () {
      expect(SdkLogger.level, NavigationLogLevel.info);
    });

    test('can set level to debug', () {
      SdkLogger.level = NavigationLogLevel.debug;
      expect(SdkLogger.level, NavigationLogLevel.debug);
    });

    test('can set level to warn', () {
      SdkLogger.level = NavigationLogLevel.warn;
      expect(SdkLogger.level, NavigationLogLevel.warn);
    });

    test('can set level to error', () {
      SdkLogger.level = NavigationLogLevel.error;
      expect(SdkLogger.level, NavigationLogLevel.error);
    });

    test('can set level to none', () {
      SdkLogger.level = NavigationLogLevel.none;
      expect(SdkLogger.level, NavigationLogLevel.none);
    });
  });

  group('SdkLogger component filtering', () {
    test('all components enabled by default', () {
      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), true);
      expect(SdkLogger.isComponentEnabled('NavigationController'), true);
      expect(SdkLogger.isComponentEnabled('Camera'), true);
      expect(SdkLogger.isComponentEnabled('UnknownComponent'), true);
    });

    test('disableComponent disables specific component', () {
      SdkLogger.disableComponent('VoiceGuidance');
      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), false);
      expect(SdkLogger.isComponentEnabled('NavigationController'), true);
    });

    test('enableComponent enables disabled component', () {
      SdkLogger.disableComponent('VoiceGuidance');
      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), false);

      SdkLogger.enableComponent('VoiceGuidance');
      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), true);
    });

    test('enableAll clears all filters', () {
      SdkLogger.disableComponent('VoiceGuidance');
      SdkLogger.disableComponent('Camera');

      SdkLogger.enableAll();

      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), true);
      expect(SdkLogger.isComponentEnabled('Camera'), true);
    });

    test('disableAll disables known components', () {
      SdkLogger.disableAll();

      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), false);
      expect(SdkLogger.isComponentEnabled('NavigationController'), false);
      expect(SdkLogger.isComponentEnabled('Camera'), false);
      expect(SdkLogger.isComponentEnabled('Location'), false);
      expect(SdkLogger.isComponentEnabled('Route'), false);
    });

    test('can enable after disableAll', () {
      SdkLogger.disableAll();
      SdkLogger.enableComponent('VoiceGuidance');

      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), true);
      expect(SdkLogger.isComponentEnabled('Camera'), false);
    });

    test('disabledComponents returns disabled set', () {
      SdkLogger.disableComponent('Camera');
      SdkLogger.disableComponent('Location');

      expect(SdkLogger.disabledComponents, contains('Camera'));
      expect(SdkLogger.disabledComponents, contains('Location'));
    });
  });

  group('SdkLogger convenience methods', () {
    test('enableVoiceGuidance enables VoiceGuidance', () {
      SdkLogger.disableAll();
      SdkLogger.enableVoiceGuidance();
      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), true);
    });

    test('disableVoiceGuidance disables VoiceGuidance', () {
      SdkLogger.disableVoiceGuidance();
      expect(SdkLogger.isComponentEnabled('VoiceGuidance'), false);
    });

    test('enableNavigation enables NavigationController', () {
      SdkLogger.disableAll();
      SdkLogger.enableNavigation();
      expect(SdkLogger.isComponentEnabled('NavigationController'), true);
    });

    test('disableNavigation disables NavigationController', () {
      SdkLogger.disableNavigation();
      expect(SdkLogger.isComponentEnabled('NavigationController'), false);
    });

    test('enableCamera enables Camera', () {
      SdkLogger.disableAll();
      SdkLogger.enableCamera();
      expect(SdkLogger.isComponentEnabled('Camera'), true);
    });

    test('disableCamera disables Camera', () {
      SdkLogger.disableCamera();
      expect(SdkLogger.isComponentEnabled('Camera'), false);
    });

    test('enableLocation enables Location', () {
      SdkLogger.disableAll();
      SdkLogger.enableLocation();
      expect(SdkLogger.isComponentEnabled('Location'), true);
    });

    test('disableLocation disables Location', () {
      SdkLogger.disableLocation();
      expect(SdkLogger.isComponentEnabled('Location'), false);
    });
  });

  group('SdkLogger presets', () {
    test('production sets level to warn', () {
      SdkLogger.production();
      expect(SdkLogger.level, NavigationLogLevel.warn);
    });

    test('debugAll sets level to debug', () {
      SdkLogger.debugAll();
      expect(SdkLogger.level, NavigationLogLevel.debug);
    });

    test('debugVoiceOnly sets level to debug and filters', () {
      SdkLogger.debugVoiceOnly();
      expect(SdkLogger.level, NavigationLogLevel.debug);
      // After debugVoiceOnly, only VoiceGuidance should be in enabled set
      expect(SdkLogger.enabledComponents, contains('VoiceGuidance'));
    });

    test('debugNavigationOnly sets level to debug and filters', () {
      SdkLogger.debugNavigationOnly();
      expect(SdkLogger.level, NavigationLogLevel.debug);
      expect(SdkLogger.enabledComponents, contains('NavigationController'));
    });

    test('disable sets level to none', () {
      SdkLogger.disable();
      expect(SdkLogger.level, NavigationLogLevel.none);
    });

    test('reset restores default state', () {
      SdkLogger.debugAll();
      SdkLogger.disableComponent('Camera');

      SdkLogger.reset();

      expect(SdkLogger.level, NavigationLogLevel.info);
      expect(SdkLogger.disabledComponents, isEmpty);
      expect(SdkLogger.enabledComponents, isEmpty);
    });
  });

  group('SdkLogger onLog callback', () {
    test('can set onLog callback', () {
      final logs = <String>[];

      SdkLogger.onLog = (level, tag, message, data) {
        logs.add('$level:$tag:$message');
      };

      expect(SdkLogger.onLog, isNotNull);

      // Clean up
      SdkLogger.onLog = null;
    });

    test('onLog receives log calls', () {
      final logs = <Map<String, dynamic>>[];

      SdkLogger.onLog = (level, tag, message, data) {
        logs.add({
          'level': level,
          'tag': tag,
          'message': message,
          'data': data,
        });
      };

      // Trigger a log
      SdkLogger.level = NavigationLogLevel.debug;
      NavigationLogger.debug('TestComponent', 'Test message', {'key': 'value'});

      expect(logs, isNotEmpty);
      expect(logs.first['tag'], 'TestComponent');
      expect(logs.first['message'], 'Test message');

      // Clean up
      SdkLogger.onLog = null;
    });

    test('onLog respects component filtering', () {
      final logs = <String>[];

      SdkLogger.onLog = (level, tag, message, data) {
        logs.add(tag);
      };

      SdkLogger.level = NavigationLogLevel.debug;
      SdkLogger.disableComponent('DisabledComponent');

      // This should be logged
      NavigationLogger.debug('EnabledComponent', 'Message 1');

      // This should NOT be logged
      NavigationLogger.debug('DisabledComponent', 'Message 2');

      expect(logs, contains('EnabledComponent'));
      expect(logs, isNot(contains('DisabledComponent')));

      // Clean up
      SdkLogger.onLog = null;
    });
  });
}
