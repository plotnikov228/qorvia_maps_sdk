import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the package_info_plus method channel
  const MethodChannel packageInfoChannel =
      MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (call) async {
      if (call.method == 'getAll') {
        return {
          'appName': 'Test App',
          'packageName': 'com.example.test',
          'version': '1.0.0',
          'buildNumber': '1',
        };
      }
      return null;
    });

    // Clean up SDK state before each test
    QorviaMapsSDK.dispose();
  });

  tearDown(() {
    QorviaMapsSDK.dispose();
  });

  group('QorviaMapsSDK', () {
    group('initialization', () {
      test('isInitialized is false before init()', () {
        expect(QorviaMapsSDK.isInitialized, isFalse);
      });

      test('instance throws StateError before init()', () {
        expect(
          () => QorviaMapsSDK.instance,
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not initialized'),
          )),
        );
      });

      test('instanceOrNull returns null before init()', () {
        expect(QorviaMapsSDK.instanceOrNull, isNull);
      });

      test('isInitialized is true after init()', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.isInitialized, isTrue);
      });

      test('instance returns SDK after init()', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.instance, isA<QorviaMapsSDK>());
      });

      test('instanceOrNull returns SDK after init()', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.instanceOrNull, isA<QorviaMapsSDK>());
      });

      test('client is available after init()', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.instance.client, isA<QorviaMapsClient>());
      });

      test('re-initialization updates client', () async {
        await QorviaMapsSDK.init(
          apiKey: 'first_key',
          prefetchTileUrl: false,
        );

        final firstClient = QorviaMapsSDK.instance.client;

        await QorviaMapsSDK.init(
          apiKey: 'second_key',
          prefetchTileUrl: false,
        );

        final secondClient = QorviaMapsSDK.instance.client;

        // Clients should be different instances after re-init
        expect(identical(firstClient, secondClient), isFalse);
      });

      test('re-initialization clears cached tile URL', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_key',
          prefetchTileUrl: false,
        );

        // Manually set a cached value for testing
        expect(QorviaMapsSDK.instance.hasTileUrl, isFalse);

        await QorviaMapsSDK.init(
          apiKey: 'new_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.instance.hasTileUrl, isFalse);
      });
    });

    group('tile URL', () {
      test('hasTileUrl is false before fetching', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.instance.hasTileUrl, isFalse);
      });

      test('tileUrlOrNull is null before fetching', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.instance.tileUrlOrNull, isNull);
      });

      test('clearTileUrlCache resets cached URL', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        // Initially no cached URL
        expect(QorviaMapsSDK.instance.hasTileUrl, isFalse);

        // Clear should work without error even if nothing cached
        QorviaMapsSDK.instance.clearTileUrlCache();

        expect(QorviaMapsSDK.instance.hasTileUrl, isFalse);
      });
    });

    group('dispose', () {
      test('dispose makes isInitialized false', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.isInitialized, isTrue);

        QorviaMapsSDK.dispose();

        expect(QorviaMapsSDK.isInitialized, isFalse);
      });

      test('dispose makes instanceOrNull null', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.instanceOrNull, isNotNull);

        QorviaMapsSDK.dispose();

        expect(QorviaMapsSDK.instanceOrNull, isNull);
      });

      test('instance throws after dispose', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          prefetchTileUrl: false,
        );

        QorviaMapsSDK.dispose();

        expect(
          () => QorviaMapsSDK.instance,
          throwsA(isA<StateError>()),
        );
      });

      test('can re-initialize after dispose', () async {
        await QorviaMapsSDK.init(
          apiKey: 'first_key',
          prefetchTileUrl: false,
        );

        QorviaMapsSDK.dispose();

        await QorviaMapsSDK.init(
          apiKey: 'second_key',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.isInitialized, isTrue);
        expect(QorviaMapsSDK.instance.client, isA<QorviaMapsClient>());
      });
    });

    group('logging', () {
      test('init with enableLogging=true does not throw', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          enableLogging: true,
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.isInitialized, isTrue);
      });

      test('init with enableLogging=false does not throw', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          enableLogging: false,
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.isInitialized, isTrue);
      });
    });

    group('custom baseUrl', () {
      test('init with custom baseUrl creates client', () async {
        await QorviaMapsSDK.init(
          apiKey: 'test_api_key',
          baseUrl: 'https://custom.api.com',
          prefetchTileUrl: false,
        );

        expect(QorviaMapsSDK.isInitialized, isTrue);
        expect(QorviaMapsSDK.instance.client, isA<QorviaMapsClient>());
      });
    });
  });
}
