import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';
import 'package:qorvia_maps_sdk/src/offline/tiles/offline_region.dart';
import 'package:qorvia_maps_sdk/src/offline/package/models/offline_package.dart';
import 'package:qorvia_maps_sdk/src/offline/package/models/package_content.dart';

void main() {
  group('PackageStatus', () {
    test('has all expected values', () {
      expect(PackageStatus.values, hasLength(6));
      expect(PackageStatus.values, contains(PackageStatus.pending));
      expect(PackageStatus.values, contains(PackageStatus.downloading));
      expect(PackageStatus.values, contains(PackageStatus.paused));
      expect(PackageStatus.values, contains(PackageStatus.completed));
      expect(PackageStatus.values, contains(PackageStatus.partiallyComplete));
      expect(PackageStatus.values, contains(PackageStatus.failed));
    });

    test('canDownload returns true for downloadable statuses', () {
      expect(PackageStatus.pending.canDownload, isTrue);
      expect(PackageStatus.paused.canDownload, isTrue);
      expect(PackageStatus.failed.canDownload, isTrue);
      expect(PackageStatus.partiallyComplete.canDownload, isTrue);
    });

    test('canDownload returns false for non-downloadable statuses', () {
      expect(PackageStatus.downloading.canDownload, isFalse);
      expect(PackageStatus.completed.canDownload, isFalse);
    });

    test('hasUsableContent returns true for usable statuses', () {
      expect(PackageStatus.completed.hasUsableContent, isTrue);
      expect(PackageStatus.partiallyComplete.hasUsableContent, isTrue);
    });

    test('hasUsableContent returns false for non-usable statuses', () {
      expect(PackageStatus.pending.hasUsableContent, isFalse);
      expect(PackageStatus.downloading.hasUsableContent, isFalse);
      expect(PackageStatus.paused.hasUsableContent, isFalse);
      expect(PackageStatus.failed.hasUsableContent, isFalse);
    });

    test('toStorageString and fromString roundtrip', () {
      for (final status in PackageStatus.values) {
        final stored = status.toStorageString();
        final restored = PackageStatusX.fromString(stored);
        expect(restored, status);
      }
    });
  });

  group('OfflinePackage', () {
    final testBounds = OfflineBounds(
      southwest: const Coordinates(lat: 55.5, lon: 37.3),
      northeast: const Coordinates(lat: 56.0, lon: 38.0),
    );

    final testContents = <PackageContentType, PackageContent>{
      PackageContentType.tiles: PackageContent.ready(
        type: PackageContentType.tiles,
        filePath: '/path/tiles.mbtiles',
        sizeBytes: 50000000,
      ),
      PackageContentType.routing: PackageContent.ready(
        type: PackageContentType.routing,
        filePath: '/path/routing.ghz',
        sizeBytes: 30000000,
      ),
    };

    OfflinePackage createTestPackage({
      PackageStatus status = PackageStatus.completed,
      Map<PackageContentType, PackageContent>? contents,
      int? totalSizeBytes,
      int? downloadedSizeBytes,
    }) {
      return OfflinePackage(
        id: 'test-package-id',
        name: 'Test Package',
        bounds: testBounds,
        minZoom: 10,
        maxZoom: 16,
        status: status,
        contents: contents ?? testContents,
        totalSizeBytes: totalSizeBytes ?? 80000000,
        downloadedSizeBytes: downloadedSizeBytes ?? 80000000,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );
    }

    test('creates with required fields', () {
      final package = createTestPackage();

      expect(package.id, 'test-package-id');
      expect(package.name, 'Test Package');
      expect(package.bounds, testBounds);
      expect(package.minZoom, 10);
      expect(package.maxZoom, 16);
      expect(package.status, PackageStatus.completed);
    });

    group('create factory', () {
      test('creates pending package', () {
        final package = OfflinePackage.create(
          id: 'new-id',
          name: 'New Package',
          bounds: testBounds,
          minZoom: 10,
          maxZoom: 16,
          contentTypes: {PackageContentType.tiles, PackageContentType.routing},
        );

        expect(package.id, 'new-id');
        expect(package.name, 'New Package');
        expect(package.status, PackageStatus.pending);
        expect(package.contents.length, 2);
        expect(package.contents[PackageContentType.tiles], isNotNull);
        expect(package.contents[PackageContentType.routing], isNotNull);
        expect(
            package.contents[PackageContentType.tiles]!.status, ContentStatus.notDownloaded);
      });

      test('uses provided content sizes', () {
        final package = OfflinePackage.create(
          id: 'id',
          name: 'Name',
          bounds: testBounds,
          minZoom: 10,
          maxZoom: 16,
          contentTypes: {PackageContentType.tiles},
          contentSizes: {PackageContentType.tiles: 50000000},
        );

        expect(package.totalSizeBytes, 50000000);
        expect(package.contents[PackageContentType.tiles]!.sizeBytes, 50000000);
      });
    });

    group('content access', () {
      test('hasContent returns correct values', () {
        final package = createTestPackage();

        expect(package.hasContent(PackageContentType.tiles), isTrue);
        expect(package.hasContent(PackageContentType.routing), isTrue);
        expect(package.hasContent(PackageContentType.geocoding), isFalse);
      });

      test('getContentStatus returns correct status', () {
        final package = createTestPackage();

        expect(package.getContentStatus(PackageContentType.tiles), ContentStatus.ready);
        expect(package.getContentStatus(PackageContentType.geocoding), isNull);
      });

      test('contentTypes returns set of all types', () {
        final package = createTestPackage();

        expect(package.contentTypes, {PackageContentType.tiles, PackageContentType.routing});
      });

      test('readyContentTypes returns only ready content', () {
        final contents = <PackageContentType, PackageContent>{
          PackageContentType.tiles: PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path',
            sizeBytes: 1000,
          ),
          PackageContentType.routing: PackageContent.notDownloaded(
            type: PackageContentType.routing,
          ),
        };
        final package = createTestPackage(contents: contents);

        expect(package.readyContentTypes, {PackageContentType.tiles});
      });

      test('pendingContentTypes returns content that can download', () {
        final contents = <PackageContentType, PackageContent>{
          PackageContentType.tiles: PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path',
            sizeBytes: 1000,
          ),
          PackageContentType.routing: PackageContent.notDownloaded(
            type: PackageContentType.routing,
          ),
        };
        final package =
            createTestPackage(status: PackageStatus.partiallyComplete, contents: contents);

        expect(package.pendingContentTypes, {PackageContentType.routing});
      });

      test('failedContentTypes returns failed content', () {
        final contents = <PackageContentType, PackageContent>{
          PackageContentType.tiles: PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path',
            sizeBytes: 1000,
          ),
          PackageContentType.routing: PackageContent.failed(
            type: PackageContentType.routing,
            errorMessage: 'Error',
          ),
        };
        final package =
            createTestPackage(status: PackageStatus.partiallyComplete, contents: contents);

        expect(package.failedContentTypes, {PackageContentType.routing});
      });
    });

    group('progress', () {
      test('overallProgress calculates correctly', () {
        final package = createTestPackage(
          totalSizeBytes: 1000,
          downloadedSizeBytes: 500,
        );

        expect(package.overallProgress, 0.5);
      });

      test('overallProgress returns 0 when totalSize is 0', () {
        final package = createTestPackage(
          totalSizeBytes: 0,
          downloadedSizeBytes: 0,
        );

        expect(package.overallProgress, 0.0);
      });

      test('progressPercentage returns formatted string', () {
        final package = createTestPackage(
          totalSizeBytes: 1000,
          downloadedSizeBytes: 333,
        );

        expect(package.progressPercentage, '33.3%');
      });

      test('readyContentCount counts ready content', () {
        final package = createTestPackage();

        expect(package.readyContentCount, 2);
      });

      test('totalContentCount returns total content types', () {
        final package = createTestPackage();

        expect(package.totalContentCount, 2);
      });
    });

    group('status checks', () {
      test('isComplete returns true for completed status', () {
        final package = createTestPackage(status: PackageStatus.completed);
        expect(package.isComplete, isTrue);
      });

      test('isDownloading returns true for downloading status', () {
        final package = createTestPackage(status: PackageStatus.downloading);
        expect(package.isDownloading, isTrue);
      });

      test('canDownload reflects status', () {
        expect(createTestPackage(status: PackageStatus.pending).canDownload, isTrue);
        expect(createTestPackage(status: PackageStatus.completed).canDownload, isFalse);
      });

      test('hasUsableContent reflects status', () {
        expect(createTestPackage(status: PackageStatus.completed).hasUsableContent, isTrue);
        expect(createTestPackage(status: PackageStatus.pending).hasUsableContent, isFalse);
      });

      test('isPreset returns true when serverRegionId is set', () {
        final package = OfflinePackage(
          id: 'id',
          name: 'name',
          bounds: testBounds,
          minZoom: 10,
          maxZoom: 16,
          status: PackageStatus.completed,
          contents: testContents,
          totalSizeBytes: 1000,
          downloadedSizeBytes: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          serverRegionId: 'moscow',
        );

        expect(package.isPreset, isTrue);
      });

      test('content readiness checks work correctly', () {
        final package = createTestPackage();

        expect(package.hasTilesReady, isTrue);
        expect(package.hasRoutingReady, isTrue);
        expect(package.hasGeocodingReady, isFalse);
        expect(package.hasReverseGeocodingReady, isFalse);
      });
    });

    group('size formatting', () {
      test('totalSizeFormatted returns human-readable size', () {
        final package = createTestPackage(totalSizeBytes: 52428800);
        expect(package.totalSizeFormatted, '50.0 MB');
      });

      test('downloadedSizeFormatted returns human-readable size', () {
        final package = createTestPackage(downloadedSizeBytes: 10485760);
        expect(package.downloadedSizeFormatted, '10.0 MB');
      });
    });

    group('location checks', () {
      test('containsLocation returns true for location inside bounds', () {
        final package = createTestPackage();

        expect(package.containsLocation(const Coordinates(lat: 55.7, lon: 37.6)), isTrue);
      });

      test('containsLocation returns false for location outside bounds', () {
        final package = createTestPackage();

        expect(package.containsLocation(const Coordinates(lat: 50.0, lon: 30.0)), isFalse);
      });

      test('coversRoute returns true when both points inside', () {
        final package = createTestPackage();

        expect(
          package.coversRoute(
            const Coordinates(lat: 55.6, lon: 37.5),
            const Coordinates(lat: 55.9, lon: 37.8),
          ),
          isTrue,
        );
      });

      test('coversRoute returns false when one point outside', () {
        final package = createTestPackage();

        expect(
          package.coversRoute(
            const Coordinates(lat: 55.6, lon: 37.5),
            const Coordinates(lat: 50.0, lon: 30.0),
          ),
          isFalse,
        );
      });
    });

    group('toOfflineRegion', () {
      test('converts to OfflineRegion correctly', () {
        final package = createTestPackage();
        final region = package.toOfflineRegion();

        expect(region.id, package.id);
        expect(region.name, package.name);
        expect(region.bounds, package.bounds);
        expect(region.minZoom, package.minZoom);
        expect(region.maxZoom, package.maxZoom);
        expect(region.status, OfflineRegionStatus.completed);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = createTestPackage();
        final updated = original.copyWith(
          status: PackageStatus.downloading,
          downloadedSizeBytes: 40000000,
        );

        expect(updated.id, original.id);
        expect(updated.name, original.name);
        expect(updated.status, PackageStatus.downloading);
        expect(updated.downloadedSizeBytes, 40000000);
      });
    });

    group('copyWithContent', () {
      test('updates single content and recalculates status', () {
        final original = createTestPackage(
          status: PackageStatus.downloading,
          contents: {
            PackageContentType.tiles: PackageContent.notDownloaded(
              type: PackageContentType.tiles,
            ),
          },
        );

        final updated = original.copyWithContent(
          PackageContentType.tiles,
          PackageContent.ready(
            type: PackageContentType.tiles,
            filePath: '/path',
            sizeBytes: 1000,
          ),
        );

        expect(updated.contents[PackageContentType.tiles]!.isReady, isTrue);
        expect(updated.status, PackageStatus.completed);
      });
    });

    group('equality', () {
      test('packages with same id are equal', () {
        final package1 = createTestPackage();
        final package2 = createTestPackage();

        expect(package1, equals(package2));
        expect(package1.hashCode, equals(package2.hashCode));
      });

      test('packages with different ids are not equal', () {
        final package1 = createTestPackage();
        final package2 = OfflinePackage(
          id: 'different-id',
          name: 'Test Package',
          bounds: testBounds,
          minZoom: 10,
          maxZoom: 16,
          status: PackageStatus.completed,
          contents: testContents,
          totalSizeBytes: 80000000,
          downloadedSizeBytes: 80000000,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        expect(package1, isNot(equals(package2)));
      });
    });

    test('toString provides useful info', () {
      final package = createTestPackage();
      final str = package.toString();

      expect(str, contains('test-package-id'));
      expect(str, contains('Test Package'));
      expect(str, contains('completed'));
    });
  });

  group('CreatePackageParams', () {
    final testBounds = OfflineBounds(
      southwest: const Coordinates(lat: 55.5, lon: 37.3),
      northeast: const Coordinates(lat: 56.0, lon: 38.0),
    );

    test('creates with required fields', () {
      final params = CreatePackageParams(
        name: 'Test',
        bounds: testBounds,
        contentTypes: {PackageContentType.tiles},
      );

      expect(params.name, 'Test');
      expect(params.bounds, testBounds);
      expect(params.minZoom, 0);
      expect(params.maxZoom, 16);
      expect(params.contentTypes, {PackageContentType.tiles});
    });

    test('full factory creates all content types', () {
      final params = CreatePackageParams.full(
        name: 'Full',
        bounds: testBounds,
      );

      expect(params.contentTypes, PackageContentType.values.toSet());
    });

    test('tilesOnly factory creates only tiles', () {
      final params = CreatePackageParams.tilesOnly(
        name: 'Tiles',
        bounds: testBounds,
      );

      expect(params.contentTypes, {PackageContentType.tiles});
    });

    test('withRouting factory creates tiles and routing', () {
      final params = CreatePackageParams.withRouting(
        name: 'Routing',
        bounds: testBounds,
      );

      expect(params.contentTypes, {PackageContentType.tiles, PackageContentType.routing});
    });

    group('validate', () {
      test('throws for empty name', () {
        final params = CreatePackageParams(
          name: '  ',
          bounds: testBounds,
          contentTypes: {PackageContentType.tiles},
        );

        expect(() => params.validate(), throwsArgumentError);
      });

      test('throws for empty content types', () {
        final params = CreatePackageParams(
          name: 'Test',
          bounds: testBounds,
          contentTypes: {},
        );

        expect(() => params.validate(), throwsArgumentError);
      });

      test('throws for invalid zoom range', () {
        final params = CreatePackageParams(
          name: 'Test',
          bounds: testBounds,
          minZoom: 20,
          maxZoom: 10,
          contentTypes: {PackageContentType.tiles},
        );

        expect(() => params.validate(), throwsArgumentError);
      });

      test('passes for valid params', () {
        final params = CreatePackageParams(
          name: 'Valid',
          bounds: testBounds,
          contentTypes: {PackageContentType.tiles},
        );

        expect(() => params.validate(), returnsNormally);
      });
    });

    test('estimateTileCount returns positive number', () {
      final params = CreatePackageParams(
        name: 'Test',
        bounds: testBounds,
        minZoom: 10,
        maxZoom: 12,
        contentTypes: {PackageContentType.tiles},
      );

      expect(params.estimateTileCount(), greaterThan(0));
    });

    test('estimateDownloadSize returns positive number for tiles', () {
      final params = CreatePackageParams(
        name: 'Test',
        bounds: testBounds,
        contentTypes: {PackageContentType.tiles},
      );

      expect(params.estimateDownloadSize(), greaterThan(0));
    });

    test('estimatedSizeFormatted returns human-readable string', () {
      final params = CreatePackageParams(
        name: 'Test',
        bounds: testBounds,
        contentTypes: {PackageContentType.tiles},
      );

      expect(params.estimatedSizeFormatted, matches(RegExp(r'\d+\.?\d*\s*(B|KB|MB|GB)')));
    });

    test('toString provides useful info', () {
      final params = CreatePackageParams(
        name: 'Test',
        bounds: testBounds,
        contentTypes: {PackageContentType.tiles},
      );

      final str = params.toString();
      expect(str, contains('Test'));
      expect(str, contains('tiles'));
    });
  });

  group('AvailablePackage', () {
    test('creates with required fields', () {
      final package = AvailablePackage(
        id: 'moscow',
        name: 'Moscow Region',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        availableContent: {PackageContentType.tiles, PackageContentType.routing},
        estimatedSizeBytes: 100000000,
        version: '1.0',
      );

      expect(package.id, 'moscow');
      expect(package.name, 'Moscow Region');
      expect(package.estimatedSizeBytes, 100000000);
      expect(package.version, '1.0');
    });

    test('estimatedSizeFormatted returns human-readable size', () {
      final package = AvailablePackage(
        id: 'test',
        name: 'Test',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        availableContent: {PackageContentType.tiles},
        estimatedSizeBytes: 104857600, // 100 MB
        version: '1.0',
      );

      expect(package.estimatedSizeFormatted, '100.0 MB');
    });

    test('toString provides useful info', () {
      final package = AvailablePackage(
        id: 'test',
        name: 'Test Package',
        bounds: OfflineBounds(
          southwest: const Coordinates(lat: 55.5, lon: 37.3),
          northeast: const Coordinates(lat: 56.0, lon: 38.0),
        ),
        availableContent: {PackageContentType.tiles},
        estimatedSizeBytes: 1000,
        version: '1.0',
      );

      final str = package.toString();
      expect(str, contains('test'));
      expect(str, contains('Test Package'));
    });
  });
}
