import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qorvia_maps_sdk/src/client/http_client.dart';
import 'package:qorvia_maps_sdk/src/services/tile_service.dart';
import 'package:qorvia_maps_sdk/src/models/tile/tile_url_response.dart';
import 'package:qorvia_maps_sdk/src/exceptions/qorvia_maps_exception.dart';

class MockHttpClient extends Mock implements QorviaMapsHttpClient {}

void main() {
  late MockHttpClient mockClient;
  late TileService tileService;

  setUp(() {
    mockClient = MockHttpClient();
    tileService = TileService(mockClient);
  });

  group('TileService', () {
    group('getTileUrl', () {
      test('returns TileUrlResponse on successful response', () async {
        // Arrange
        final responseData = {
          'request_id': 'test-request-123',
          'status': 'ok',
          'tile_url': 'https://example.com/style.json',
        };
        when(() => mockClient.get('/v1/mobile/tile-url'))
            .thenAnswer((_) async => responseData);

        // Act
        final result = await tileService.getTileUrl();

        // Assert
        expect(result, isA<TileUrlResponse>());
        expect(result.requestId, 'test-request-123');
        expect(result.status, 'ok');
        expect(result.tileUrl, 'https://example.com/style.json');
        verify(() => mockClient.get('/v1/mobile/tile-url')).called(1);
      });

      test('handles response without request_id', () async {
        // Arrange
        final responseData = {
          'status': 'ok',
          'tile_url': 'https://example.com/style.json',
        };
        when(() => mockClient.get('/v1/mobile/tile-url'))
            .thenAnswer((_) async => responseData);

        // Act
        final result = await tileService.getTileUrl();

        // Assert
        expect(result.requestId, isNull);
        expect(result.tileUrl, 'https://example.com/style.json');
      });

      test('throws FormatException when tile_url is missing', () async {
        // Arrange
        final responseData = {
          'request_id': 'test-123',
          'status': 'ok',
          // tile_url is missing
        };
        when(() => mockClient.get('/v1/mobile/tile-url'))
            .thenAnswer((_) async => responseData);

        // Act & Assert
        expect(
          () => tileService.getTileUrl(),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException when tile_url is empty', () async {
        // Arrange
        final responseData = {
          'request_id': 'test-123',
          'status': 'ok',
          'tile_url': '',
        };
        when(() => mockClient.get('/v1/mobile/tile-url'))
            .thenAnswer((_) async => responseData);

        // Act & Assert
        expect(
          () => tileService.getTileUrl(),
          throwsA(isA<FormatException>()),
        );
      });

      test('rethrows network exception from client', () async {
        // Arrange
        when(() => mockClient.get('/v1/mobile/tile-url'))
            .thenThrow(const NetworkException(message: 'No internet'));

        // Act & Assert
        expect(
          () => tileService.getTileUrl(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('rethrows auth exception from client', () async {
        // Arrange
        when(() => mockClient.get('/v1/mobile/tile-url'))
            .thenThrow(const AuthException(message: 'Invalid API key'));

        // Act & Assert
        expect(
          () => tileService.getTileUrl(),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });

  group('TileUrlResponse', () {
    test('fromJson parses valid response', () {
      final json = {
        'request_id': 'req-456',
        'status': 'ok',
        'tile_url': 'https://tiles.example.com/style.json',
      };

      final response = TileUrlResponse.fromJson(json);

      expect(response.requestId, 'req-456');
      expect(response.status, 'ok');
      expect(response.tileUrl, 'https://tiles.example.com/style.json');
    });

    test('toJson returns correct map', () {
      const response = TileUrlResponse(
        requestId: 'req-789',
        status: 'ok',
        tileUrl: 'https://example.com/style.json',
      );

      final json = response.toJson();

      expect(json['request_id'], 'req-789');
      expect(json['status'], 'ok');
      expect(json['tile_url'], 'https://example.com/style.json');
    });

    test('toJson omits null request_id', () {
      const response = TileUrlResponse(
        status: 'ok',
        tileUrl: 'https://example.com/style.json',
      );

      final json = response.toJson();

      expect(json.containsKey('request_id'), isFalse);
      expect(json['tile_url'], 'https://example.com/style.json');
    });

    test('toString returns readable format', () {
      const response = TileUrlResponse(
        requestId: 'test-id',
        status: 'ok',
        tileUrl: 'https://example.com/style.json',
      );

      expect(
        response.toString(),
        'TileUrlResponse(requestId: test-id, status: ok, tileUrl: https://example.com/style.json)',
      );
    });
  });
}
