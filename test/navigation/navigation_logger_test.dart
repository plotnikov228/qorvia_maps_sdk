import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  setUp(() {
    // Reset logger to defaults before each test
    NavigationLogger.reset();
  });

  tearDown(() {
    // Clean up after each test
    NavigationLogger.reset();
  });

  group('NavigationLogLevel', () {
    test('has all expected levels in correct order', () {
      expect(NavigationLogLevel.values.length, 5);
      expect(NavigationLogLevel.none.index, 0);
      expect(NavigationLogLevel.error.index, 1);
      expect(NavigationLogLevel.warn.index, 2);
      expect(NavigationLogLevel.info.index, 3);
      expect(NavigationLogLevel.debug.index, 4);
    });

    test('higher index means more verbose', () {
      expect(NavigationLogLevel.debug.index, greaterThan(NavigationLogLevel.info.index));
      expect(NavigationLogLevel.info.index, greaterThan(NavigationLogLevel.warn.index));
      expect(NavigationLogLevel.warn.index, greaterThan(NavigationLogLevel.error.index));
      expect(NavigationLogLevel.error.index, greaterThan(NavigationLogLevel.none.index));
    });
  });

  group('NavigationLogger', () {
    test('default level is info', () {
      expect(NavigationLogger.level, NavigationLogLevel.info);
    });

    test('can set level', () {
      NavigationLogger.level = NavigationLogLevel.debug;
      expect(NavigationLogger.level, NavigationLogLevel.debug);

      NavigationLogger.level = NavigationLogLevel.none;
      expect(NavigationLogger.level, NavigationLogLevel.none);
    });

    test('reset() restores defaults', () {
      NavigationLogger.level = NavigationLogLevel.debug;
      NavigationLogger.filterTags = {'test'};

      NavigationLogger.reset();

      expect(NavigationLogger.level, NavigationLogLevel.info);
      expect(NavigationLogger.filterTags, isEmpty);
    });

    test('enableVerbose() sets debug level', () {
      NavigationLogger.enableVerbose();
      expect(NavigationLogger.level, NavigationLogLevel.debug);
      expect(NavigationLogger.filterTags, isEmpty);
    });

    test('disable() sets none level', () {
      NavigationLogger.disable();
      expect(NavigationLogger.level, NavigationLogLevel.none);
    });
  });

  group('Log callback', () {
    test('onLog callback is called for matching level', () {
      final logs = <Map<String, dynamic>>[];

      NavigationLogger.level = NavigationLogLevel.debug;
      NavigationLogger.onLog = (level, tag, message, data) {
        logs.add({
          'level': level,
          'tag': tag,
          'message': message,
          'data': data,
        });
      };

      NavigationLogger.info('TestTag', 'Test message', {'key': 'value'});

      expect(logs.length, 1);
      expect(logs[0]['level'], NavigationLogLevel.info);
      expect(logs[0]['tag'], 'TestTag');
      expect(logs[0]['message'], 'Test message');
      expect(logs[0]['data'], {'key': 'value'});
    });

    test('onLog callback is not called when level is too low', () {
      final logs = <Map<String, dynamic>>[];

      NavigationLogger.level = NavigationLogLevel.error;
      NavigationLogger.onLog = (level, tag, message, data) {
        logs.add({'level': level, 'tag': tag, 'message': message});
      };

      // Debug is higher index than error, so should be filtered
      NavigationLogger.debug('TestTag', 'Debug message');
      NavigationLogger.info('TestTag', 'Info message');
      NavigationLogger.warn('TestTag', 'Warn message');

      expect(logs.length, 0);
    });

    test('error logs are always captured when level >= error', () {
      final logs = <Map<String, dynamic>>[];

      NavigationLogger.level = NavigationLogLevel.error;
      NavigationLogger.onLog = (level, tag, message, data) {
        logs.add({'level': level, 'tag': tag, 'message': message});
      };

      NavigationLogger.error('TestTag', 'Error message');

      expect(logs.length, 1);
      expect(logs[0]['level'], NavigationLogLevel.error);
    });

    test('callback receives error info when provided', () {
      final logs = <Map<String, dynamic>>[];

      NavigationLogger.level = NavigationLogLevel.error;
      NavigationLogger.onLog = (level, tag, message, data) {
        logs.add({'level': level, 'tag': tag, 'message': message, 'data': data});
      };

      final testError = Exception('Test error');
      NavigationLogger.error('TestTag', 'Error occurred', testError);

      expect(logs.length, 1);
      expect(logs[0]['data']?['error'], contains('Test error'));
    });
  });

  group('Tag filtering', () {
    test('empty filterTags logs all tags', () {
      final logs = <String>[];

      NavigationLogger.level = NavigationLogLevel.debug;
      NavigationLogger.filterTags = {};
      NavigationLogger.onLog = (level, tag, message, data) {
        logs.add(tag);
      };

      NavigationLogger.debug('Tag1', 'Message 1');
      NavigationLogger.debug('Tag2', 'Message 2');
      NavigationLogger.debug('Tag3', 'Message 3');

      expect(logs, containsAll(['Tag1', 'Tag2', 'Tag3']));
    });

    test('filterTags only logs matching tags', () {
      final logs = <String>[];

      NavigationLogger.level = NavigationLogLevel.debug;
      NavigationLogger.filterTags = {'Camera', 'Snap'};
      NavigationLogger.onLog = (level, tag, message, data) {
        logs.add(tag);
      };

      NavigationLogger.debug('Camera', 'Camera message');
      NavigationLogger.debug('Snap', 'Snap message');
      NavigationLogger.debug('Prediction', 'Prediction message'); // Filtered

      expect(logs.length, 2);
      expect(logs, containsAll(['Camera', 'Snap']));
      expect(logs, isNot(contains('Prediction')));
    });
  });

  group('NavigationOptions logging settings', () {
    test('default logLevel is info', () {
      const options = NavigationOptions();
      expect(options.logLevel, NavigationLogLevel.info);
    });

    test('can create options with custom logLevel', () {
      const options = NavigationOptions(logLevel: NavigationLogLevel.debug);
      expect(options.logLevel, NavigationLogLevel.debug);
    });

    test('copyWith can change logLevel', () {
      const original = NavigationOptions();
      final copied = original.copyWith(logLevel: NavigationLogLevel.none);

      expect(original.logLevel, NavigationLogLevel.info);
      expect(copied.logLevel, NavigationLogLevel.none);
    });

    test('copyWith preserves logLevel if not specified', () {
      const original = NavigationOptions(logLevel: NavigationLogLevel.debug);
      final copied = original.copyWith(zoom: 18);

      expect(copied.logLevel, NavigationLogLevel.debug);
    });
  });

  group('Log message formatting', () {
    test('debug messages are formatted correctly', () {
      String? capturedMessage;

      NavigationLogger.level = NavigationLogLevel.debug;
      NavigationLogger.onLog = (level, tag, message, data) {
        capturedMessage = message;
      };

      NavigationLogger.debug('Camera', 'Position updated');

      expect(capturedMessage, 'Position updated');
    });

    test('data is included in log output', () {
      Map<String, dynamic>? capturedData;

      NavigationLogger.level = NavigationLogLevel.debug;
      NavigationLogger.onLog = (level, tag, message, data) {
        capturedData = data;
      };

      NavigationLogger.debug('Camera', 'Update', {'lat': 55.75, 'lon': 37.62});

      expect(capturedData, isNotNull);
      expect(capturedData!['lat'], 55.75);
      expect(capturedData!['lon'], 37.62);
    });
  });

  group('Component-based filtering', () {
    test('all components enabled by default', () {
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), true);
      expect(NavigationLogger.isComponentEnabled('NavigationController'), true);
      expect(NavigationLogger.isComponentEnabled('Camera'), true);
      expect(NavigationLogger.isComponentEnabled('UnknownComponent'), true);
    });

    test('disableComponent disables specific component', () {
      NavigationLogger.disableComponent('VoiceGuidance');
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), false);
      expect(NavigationLogger.isComponentEnabled('NavigationController'), true);
    });

    test('enableComponent enables disabled component', () {
      NavigationLogger.disableComponent('VoiceGuidance');
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), false);

      NavigationLogger.enableComponent('VoiceGuidance');
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), true);
    });

    test('enableAllComponents clears all filters', () {
      NavigationLogger.disableComponent('VoiceGuidance');
      NavigationLogger.disableComponent('Camera');
      NavigationLogger.enableComponent('Navigation');

      NavigationLogger.enableAllComponents();

      expect(NavigationLogger.enabledComponents, isEmpty);
      expect(NavigationLogger.disabledComponents, isEmpty);
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), true);
      expect(NavigationLogger.isComponentEnabled('Camera'), true);
    });

    test('disabled component logs are filtered', () {
      final logs = <String>[];
      NavigationLogger.onLog = (level, tag, message, data) {
        logs.add(tag);
      };

      NavigationLogger.level = NavigationLogLevel.debug;
      NavigationLogger.disableComponent('DisabledComponent');

      NavigationLogger.debug('EnabledComponent', 'Message 1');
      NavigationLogger.debug('DisabledComponent', 'Message 2');

      expect(logs, contains('EnabledComponent'));
      expect(logs, isNot(contains('DisabledComponent')));
    });

    test('enabledComponents mode filters to only enabled', () {
      NavigationLogger.enableComponent('VoiceGuidance');

      // When enabledComponents is non-empty, only those are enabled
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), true);
      expect(NavigationLogger.isComponentEnabled('Camera'), false);
    });

    test('disabledComponents takes precedence over enabledComponents', () {
      NavigationLogger.enableComponent('Camera');
      NavigationLogger.disableComponent('Camera');

      expect(NavigationLogger.isComponentEnabled('Camera'), false);
    });

    test('disabledComponents getter returns disabled set', () {
      NavigationLogger.disableComponent('Camera');
      NavigationLogger.disableComponent('Location');

      expect(NavigationLogger.disabledComponents, contains('Camera'));
      expect(NavigationLogger.disabledComponents, contains('Location'));
    });

    test('enabledComponents getter returns enabled set', () {
      NavigationLogger.enableComponent('VoiceGuidance');
      NavigationLogger.enableComponent('Navigation');

      expect(NavigationLogger.enabledComponents, contains('VoiceGuidance'));
      expect(NavigationLogger.enabledComponents, contains('Navigation'));
    });
  });

  group('Logging presets', () {
    test('production sets level to warn', () {
      NavigationLogger.production();
      expect(NavigationLogger.level, NavigationLogLevel.warn);
    });

    test('debugVoiceOnly sets level to debug and enables only VoiceGuidance', () {
      NavigationLogger.debugVoiceOnly();

      expect(NavigationLogger.level, NavigationLogLevel.debug);
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), true);
      expect(NavigationLogger.isComponentEnabled('Camera'), false);
      expect(NavigationLogger.isComponentEnabled('NavigationController'), false);
    });

    test('debugNavigationOnly sets level to debug and enables only NavigationController', () {
      NavigationLogger.debugNavigationOnly();

      expect(NavigationLogger.level, NavigationLogLevel.debug);
      expect(NavigationLogger.isComponentEnabled('NavigationController'), true);
      expect(NavigationLogger.isComponentEnabled('Camera'), false);
      expect(NavigationLogger.isComponentEnabled('VoiceGuidance'), false);
    });

    test('reset clears component filters', () {
      NavigationLogger.disableComponent('Camera');
      NavigationLogger.enableComponent('VoiceGuidance');

      NavigationLogger.reset();

      expect(NavigationLogger.enabledComponents, isEmpty);
      expect(NavigationLogger.disabledComponents, isEmpty);
    });
  });
}
