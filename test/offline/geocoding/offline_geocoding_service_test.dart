import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';
import 'package:qorvia_maps_sdk/src/offline/geocoding/offline_geocoding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineGeocodingService', () {
    late OfflineGeocodingService service;
    late Directory tempDir;
    late File testDbFile;

    setUp(() async {
      service = OfflineGeocodingService();

      // Create a temp directory and a valid SQLite file for testing
      tempDir = await Directory.systemTemp.createTemp('geocoding_test_');
      testDbFile = File('${tempDir.path}/test.db');

      // Write SQLite header (first 16 bytes)
      // "SQLite format 3\x00"
      await testDbFile.writeAsBytes([
        0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // "SQLite f"
        0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // "ormat 3\0"
      ]);
    });

    tearDown(() async {
      service.dispose();
      await tempDir.delete(recursive: true);
    });

    test('creates with optional logger', () {
      final logs = <String>[];
      final serviceWithLogger = OfflineGeocodingService(
        logger: (msg) => logs.add(msg),
      );

      expect(serviceWithLogger, isNotNull);
      serviceWithLogger.dispose();
    });

    group('Database Management', () {
      test('loadDatabase succeeds with valid SQLite file', () async {
        await service.loadDatabase('test-region', testDbFile.path);

        expect(service.isDatabaseLoaded('test-region'), isTrue);
      });

      test('loadDatabase throws for non-existent file', () async {
        expect(
          () => service.loadDatabase('test', '/nonexistent/path.db'),
          throwsA(isA<OfflineGeocodingException>()),
        );
      });

      test('loadDatabase throws for invalid SQLite file', () async {
        final invalidFile = File('${tempDir.path}/invalid.db');
        await invalidFile.writeAsString('Not a SQLite database');

        expect(
          () => service.loadDatabase('test', invalidFile.path),
          throwsA(isA<OfflineGeocodingException>()),
        );
      });

      test('unloadDatabase removes database from loaded map', () async {
        await service.loadDatabase('test-region', testDbFile.path);
        expect(service.isDatabaseLoaded('test-region'), isTrue);

        service.unloadDatabase('test-region');

        expect(service.isDatabaseLoaded('test-region'), isFalse);
      });

      test('isDatabaseLoaded returns false for unloaded database', () {
        expect(service.isDatabaseLoaded('not-loaded'), isFalse);
      });

      test('getLoadedDatabases returns list of loaded regions', () async {
        await service.loadDatabase('region1', testDbFile.path);

        // Create another valid test file
        final testDbFile2 = File('${tempDir.path}/test2.db');
        await testDbFile2.writeAsBytes([
          0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66,
          0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00,
        ]);
        await service.loadDatabase('region2', testDbFile2.path);

        final databases = service.getLoadedDatabases();

        expect(databases, contains('region1'));
        expect(databases, contains('region2'));
        expect(databases, hasLength(2));
      });

      test('getDatabaseInfo returns info for loaded database', () async {
        await service.loadDatabase('test-region', testDbFile.path);

        final info = service.getDatabaseInfo('test-region');

        expect(info, isNotNull);
        expect(info!.regionId, 'test-region');
        expect(info.path, testDbFile.path);
        expect(info.loadedAt, isA<DateTime>());
      });

      test('getDatabaseInfo returns null for unloaded database', () {
        final info = service.getDatabaseInfo('not-loaded');

        expect(info, isNull);
      });
    });

    group('Forward Geocoding', () {
      setUp(() async {
        await service.loadDatabase('test-region', testDbFile.path);
      });

      test('geocode throws when database not loaded', () async {
        expect(
          () => service.geocode(
            regionId: 'not-loaded',
            query: 'test query',
          ),
          throwsA(isA<OfflineGeocodingException>()),
        );
      });

      test('geocode returns empty results for empty query', () async {
        final response = await service.geocode(
          regionId: 'test-region',
          query: '   ',
        );

        expect(response.results, isEmpty);
        expect(response.provider, 'offline');
        expect(response.units, 0);
      });

      test('geocode returns response with correct structure', () async {
        final response = await service.geocode(
          regionId: 'test-region',
          query: 'test address',
          limit: 10,
          userLat: 55.7558,
          userLon: 37.6173,
        );

        expect(response.requestId, isNotEmpty);
        expect(response.provider, 'offline');
        expect(response.units, 0);
        // Note: actual search returns empty for now (placeholder implementation)
        expect(response.results, isEmpty);
      });

      test('search returns single result or null', () async {
        final result = await service.search(
          'test-region',
          'test query',
        );

        // Placeholder implementation returns empty, so firstResult is null
        expect(result, isNull);
      });
    });

    group('Reverse Geocoding', () {
      setUp(() async {
        await service.loadDatabase('test-region', testDbFile.path);
      });

      test('reverse throws when database not loaded', () async {
        expect(
          () => service.reverse(
            regionId: 'not-loaded',
            coordinates: const Coordinates(lat: 55.7558, lon: 37.6173),
          ),
          throwsA(isA<OfflineGeocodingException>()),
        );
      });

      test('reverse returns response with correct structure', () async {
        final response = await service.reverse(
          regionId: 'test-region',
          coordinates: const Coordinates(lat: 55.7558, lon: 37.6173),
          radiusMeters: 50,
        );

        expect(response.requestId, isNotEmpty);
        expect(response.coordinates.lat, 55.7558);
        expect(response.coordinates.lon, 37.6173);
        expect(response.provider, 'offline');
        expect(response.units, 0);
        // Note: placeholder implementation returns empty displayName
        expect(response.displayName, '');
      });
    });

    group('dispose', () {
      test('dispose clears all loaded databases', () async {
        await service.loadDatabase('region1', testDbFile.path);

        service.dispose();

        expect(service.getLoadedDatabases(), isEmpty);
      });
    });
  });

  group('OfflineDatabaseInfo', () {
    test('creates with required fields', () {
      final loadedAt = DateTime.now();
      final info = OfflineDatabaseInfo(
        regionId: 'test',
        path: '/path/to/db',
        loadedAt: loadedAt,
      );

      expect(info.regionId, 'test');
      expect(info.path, '/path/to/db');
      expect(info.loadedAt, loadedAt);
    });

    test('toString provides useful info', () {
      final info = OfflineDatabaseInfo(
        regionId: 'test-region',
        path: '/path/to/db.db',
        loadedAt: DateTime.now(),
      );

      expect(info.toString(), contains('test-region'));
      expect(info.toString(), contains('/path/to/db.db'));
    });
  });

  group('OfflineGeocodingException', () {
    test('creates with message', () {
      const exception = OfflineGeocodingException('Test error');

      expect(exception.message, 'Test error');
    });

    test('toString includes message', () {
      const exception = OfflineGeocodingException('Test error');

      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('OfflineGeocodingException'));
    });
  });
}
