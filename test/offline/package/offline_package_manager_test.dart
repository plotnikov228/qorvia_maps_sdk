import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';
import 'package:qorvia_maps_sdk/src/offline/package/models/offline_package.dart';
import 'package:qorvia_maps_sdk/src/offline/package/models/package_content.dart';
import 'package:qorvia_maps_sdk/src/offline/tiles/offline_region.dart';

/// Integration tests for offline package models.
///
/// Note: Full integration tests for OfflinePackageManager require
/// real database connections and file system access. These tests
/// focus on the model behaviors and validation logic that can be
/// tested without external dependencies.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreatePackageParams Integration', () {
    test('validates all parameters together', () {
      final params = CreatePackageParams.full(
        name: 'Moscow Region',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 16,
      );

      // Should not throw
      params.validate();

      expect(params.name, 'Moscow Region');
      expect(params.contentTypes, hasLength(4));
      expect(params.minZoom, 10);
      expect(params.maxZoom, 16);
    });

    test('validates bounds correctly', () {
      // Valid bounds
      final validParams = CreatePackageParams(
        name: 'Test',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        contentTypes: {PackageContentType.tiles},
      );

      expect(() => validParams.validate(), returnsNormally);
    });

    test('estimates download size for various content types', () {
      final tilesOnly = CreatePackageParams.tilesOnly(
        name: 'Test',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 16,
      );

      final full = CreatePackageParams.full(
        name: 'Test',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 16,
      );

      final tilesOnlySize = tilesOnly.estimateDownloadSize();
      final fullSize = full.estimateDownloadSize();

      // Full should be larger than tiles only
      expect(fullSize, greaterThan(tilesOnlySize));

      // Both should be non-zero
      expect(tilesOnlySize, greaterThan(0));
      expect(fullSize, greaterThan(0));
    });

    test('tile count estimation scales with zoom levels', () {
      final smallArea = CreatePackageParams(
        name: 'Small',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.7, lon: 37.5),
          northeast: const Coordinates(lat: 55.8, lon: 37.7),
        ),
        minZoom: 10,
        maxZoom: 12,
        contentTypes: {PackageContentType.tiles},
      );

      final largeArea = CreatePackageParams(
        name: 'Large',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 16,
        contentTypes: {PackageContentType.tiles},
      );

      final smallTileCount = smallArea.estimateTileCount();
      final largeTileCount = largeArea.estimateTileCount();

      // Larger area with more zoom levels should have more tiles
      expect(largeTileCount, greaterThan(smallTileCount));
    });
  });

  group('OfflinePackage Status Transitions', () {
    test('package starts with pending status', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.pending,
        contents: {},
        totalSizeBytes: 0,
        downloadedSizeBytes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(package.status, PackageStatus.pending);
      expect(package.canDownload, isTrue);
      expect(package.isDownloading, isFalse);
      expect(package.isComplete, isFalse);
    });

    test('downloading status flags are correct', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.downloading,
        contents: {
          PackageContentType.tiles: const PackageContent(
            type: PackageContentType.tiles,
            status: ContentStatus.downloading,
            sizeBytes: 1000,
            downloadedBytes: 500,
          ),
        },
        totalSizeBytes: 1000,
        downloadedSizeBytes: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(package.isDownloading, isTrue);
      expect(package.canDownload, isFalse);
      expect(package.progressPercentage, '50.0%');
    });

    test('completed status with all content ready', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.completed,
        contents: {
          PackageContentType.tiles: PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path/to/tiles.mbtiles',
            sizeBytes: 1000,
          ),
          PackageContentType.routing: PackageContent.ready(
            type: PackageContentType.routing,
            filePath: '/path/to/routing.ghz',
            sizeBytes: 2000,
          ),
        },
        totalSizeBytes: 3000,
        downloadedSizeBytes: 3000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(package.isComplete, isTrue);
      expect(package.hasUsableContent, isTrue);
      expect(package.hasTilesReady, isTrue);
      expect(package.hasRoutingReady, isTrue);
      expect(package.hasGeocodingReady, isFalse);
    });

    test('partially complete status', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.partiallyComplete,
        contents: {
          PackageContentType.tiles: PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path/to/tiles.mbtiles',
            sizeBytes: 1000,
          ),
          PackageContentType.routing: PackageContent.failed(
            type: PackageContentType.routing,
            errorMessage: 'Network error',
          ),
        },
        totalSizeBytes: 3000,
        downloadedSizeBytes: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(package.status, PackageStatus.partiallyComplete);
      expect(package.hasUsableContent, isTrue);
      expect(package.hasTilesReady, isTrue);
      expect(package.hasRoutingReady, isFalse);
      expect(package.canDownload, isTrue); // Can retry failed content
    });

    test('failed status', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.failed,
        contents: {
          PackageContentType.tiles: PackageContent.failed(
            type: PackageContentType.tiles,
            errorMessage: 'Download failed',
          ),
        },
        totalSizeBytes: 1000,
        downloadedSizeBytes: 0,
        errorMessage: 'All content failed',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(package.status, PackageStatus.failed);
      expect(package.errorMessage, isNotNull);
      expect(package.errorMessage, 'All content failed');
      expect(package.canDownload, isTrue); // Can retry
    });
  });

  group('OfflinePackage Content Management', () {
    test('copyWithContent creates new package with updated content', () {
      final original = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.downloading,
        contents: {
          PackageContentType.tiles: const PackageContent(
            type: PackageContentType.tiles,
            status: ContentStatus.downloading,
            sizeBytes: 1000,
            downloadedBytes: 500,
          ),
        },
        totalSizeBytes: 1000,
        downloadedSizeBytes: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWithContent(
        PackageContentType.tiles,
        PackageContent.ready(
          type: PackageContentType.tiles,
          filePath: '/path/to/tiles.mbtiles',
          sizeBytes: 1000,
        ),
      );

      // Original should be unchanged
      expect(original.contents[PackageContentType.tiles]!.status,
          ContentStatus.downloading);

      // Updated should have ready content
      expect(updated.contents[PackageContentType.tiles]!.status,
          ContentStatus.ready);
      expect(updated.contents[PackageContentType.tiles]!.filePath,
          '/path/to/tiles.mbtiles');
    });

    test('getContent returns content for type', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.completed,
        contents: {
          PackageContentType.tiles: PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path/to/tiles.mbtiles',
            sizeBytes: 1000,
          ),
        },
        totalSizeBytes: 1000,
        downloadedSizeBytes: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tiles = package.getContent(PackageContentType.tiles);
      final routing = package.getContent(PackageContentType.routing);

      expect(tiles, isNotNull);
      expect(tiles!.type, PackageContentType.tiles);
      expect(routing, isNull);
    });

    test('contentTypes returns set of all content types', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.pending,
        contents: {
          PackageContentType.tiles: const PackageContent(
            type: PackageContentType.tiles,
            status: ContentStatus.notDownloaded,
          ),
          PackageContentType.routing: const PackageContent(
            type: PackageContentType.routing,
            status: ContentStatus.notDownloaded,
          ),
          PackageContentType.geocoding: const PackageContent(
            type: PackageContentType.geocoding,
            status: ContentStatus.notDownloaded,
          ),
        },
        totalSizeBytes: 0,
        downloadedSizeBytes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final types = package.contentTypes;

      expect(types, hasLength(3));
      expect(types, contains(PackageContentType.tiles));
      expect(types, contains(PackageContentType.routing));
      expect(types, contains(PackageContentType.geocoding));
    });
  });

  group('OfflinePackage Location Checks', () {
    test('containsLocation returns true for point inside bounds', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.completed,
        contents: {},
        totalSizeBytes: 0,
        downloadedSizeBytes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(package.containsLocation(const Coordinates(lat: 55.5, lon: 37.5)), isTrue);
      expect(package.containsLocation(const Coordinates(lat: 55.0, lon: 37.0)), isTrue); // On boundary
      expect(package.containsLocation(const Coordinates(lat: 56.0, lon: 38.0)), isTrue); // On boundary
    });

    test('containsLocation returns false for point outside bounds', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.completed,
        contents: {},
        totalSizeBytes: 0,
        downloadedSizeBytes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(package.containsLocation(const Coordinates(lat: 54.0, lon: 37.5)), isFalse); // South
      expect(package.containsLocation(const Coordinates(lat: 57.0, lon: 37.5)), isFalse); // North
      expect(package.containsLocation(const Coordinates(lat: 55.5, lon: 36.0)), isFalse); // West
      expect(package.containsLocation(const Coordinates(lat: 55.5, lon: 39.0)), isFalse); // East
    });

    test('coversRoute returns true when both points are inside', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.completed,
        contents: {
          PackageContentType.routing: PackageContent.ready(
            type: PackageContentType.routing,
            filePath: '/path/to/routing.ghz',
            sizeBytes: 1000,
          ),
        },
        totalSizeBytes: 1000,
        downloadedSizeBytes: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        package.coversRoute(
          const Coordinates(lat: 55.2, lon: 37.2),
          const Coordinates(lat: 55.8, lon: 37.8),
        ),
        isTrue,
      );
    });

    test('coversRoute returns false when one point is outside', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.completed,
        contents: {},
        totalSizeBytes: 0,
        downloadedSizeBytes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Origin outside
      expect(
        package.coversRoute(
          const Coordinates(lat: 54.0, lon: 37.5),
          const Coordinates(lat: 55.5, lon: 37.5),
        ),
        isFalse,
      );
      // Destination outside
      expect(
        package.coversRoute(
          const Coordinates(lat: 55.5, lon: 37.5),
          const Coordinates(lat: 57.0, lon: 37.5),
        ),
        isFalse,
      );
    });
  });

  group('OfflinePackage Conversion', () {
    test('toOfflineRegion converts to legacy format', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.completed,
        contents: {
          PackageContentType.tiles: PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path/to/tiles.mbtiles',
            sizeBytes: 1000,
          ),
        },
        totalSizeBytes: 1000,
        downloadedSizeBytes: 1000,
        styleUrl: 'https://example.com/style.json',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final region = package.toOfflineRegion();

      expect(region.id, 'test-id');
      expect(region.name, 'Test Package');
      expect(region.minZoom, 10);
      expect(region.maxZoom, 14);
      expect(region.styleUrl, 'https://example.com/style.json');
      expect(region.status, OfflineRegionStatus.completed);
    });

    test('toOfflineRegion handles incomplete package', () {
      final package = OfflinePackage(
        id: 'test-id',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        minZoom: 10,
        maxZoom: 14,
        status: PackageStatus.downloading,
        contents: {
          PackageContentType.tiles: const PackageContent(
            type: PackageContentType.tiles,
            status: ContentStatus.downloading,
            sizeBytes: 1000,
            downloadedBytes: 500,
          ),
        },
        totalSizeBytes: 1000,
        downloadedSizeBytes: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final region = package.toOfflineRegion();

      expect(region.status, OfflineRegionStatus.downloading);
      // Note: OfflineRegion.progress is based on downloadedTiles/totalTiles,
      // which are not tracked in OfflinePackage, so progress is 0
      expect(region.progress, 0.0);
    });
  });

  group('AvailablePackage', () {
    test('creates with correct fields', () {
      final available = AvailablePackage(
        id: 'server-id',
        name: 'Moscow',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        estimatedSizeBytes: 100000000, // 100 MB
        availableContent: {
          PackageContentType.tiles,
          PackageContentType.routing,
          PackageContentType.geocoding,
        },
        version: '2024.1',
      );

      expect(available.id, 'server-id');
      expect(available.name, 'Moscow');
      expect(available.estimatedSizeBytes, 100000000);
      expect(available.availableContent, hasLength(3));
      expect(available.version, '2024.1');
    });

    test('estimatedSizeFormatted returns human-readable size', () {
      final available = AvailablePackage(
        id: 'test',
        name: 'Test',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.0, lon: 37.0),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        estimatedSizeBytes: 52428800, // 50 MB
        availableContent: {PackageContentType.tiles},
        version: '1.0',
      );

      expect(available.estimatedSizeFormatted, '50.0 MB');
    });
  });
}
