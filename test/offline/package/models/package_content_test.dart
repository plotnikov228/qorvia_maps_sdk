import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/offline/package/models/package_content.dart';

void main() {
  group('PackageContentType', () {
    test('has all expected values', () {
      expect(PackageContentType.values, hasLength(4));
      expect(PackageContentType.values, contains(PackageContentType.tiles));
      expect(PackageContentType.values, contains(PackageContentType.routing));
      expect(PackageContentType.values, contains(PackageContentType.geocoding));
      expect(
          PackageContentType.values, contains(PackageContentType.reverseGeocoding));
    });

    test('displayName returns correct names', () {
      expect(PackageContentType.tiles.displayName, 'Map Tiles');
      expect(PackageContentType.routing.displayName, 'Routing Data');
      expect(PackageContentType.geocoding.displayName, 'Address Search');
      expect(PackageContentType.reverseGeocoding.displayName, 'Reverse Geocoding');
    });

    test('displayNameRu returns Russian names', () {
      expect(PackageContentType.tiles.displayNameRu, 'Тайлы карты');
      expect(PackageContentType.routing.displayNameRu, 'Данные маршрутов');
      expect(PackageContentType.geocoding.displayNameRu, 'Поиск адресов');
      expect(PackageContentType.reverseGeocoding.displayNameRu, 'Обратный геокодинг');
    });

    test('fileExtension returns correct extensions', () {
      expect(PackageContentType.tiles.fileExtension, '.mbtiles');
      expect(PackageContentType.routing.fileExtension, '.ghz');
      expect(PackageContentType.geocoding.fileExtension, '.db');
      expect(PackageContentType.reverseGeocoding.fileExtension, '.db');
    });

    test('toStorageString and fromString roundtrip', () {
      for (final type in PackageContentType.values) {
        final stored = type.toStorageString();
        final restored = PackageContentTypeX.fromString(stored);
        expect(restored, type);
      }
    });

    test('fromString returns tiles for unknown value', () {
      expect(PackageContentTypeX.fromString('unknown'), PackageContentType.tiles);
    });
  });

  group('ContentStatus', () {
    test('has all expected values', () {
      expect(ContentStatus.values, hasLength(6));
      expect(ContentStatus.values, contains(ContentStatus.notDownloaded));
      expect(ContentStatus.values, contains(ContentStatus.queued));
      expect(ContentStatus.values, contains(ContentStatus.downloading));
      expect(ContentStatus.values, contains(ContentStatus.ready));
      expect(ContentStatus.values, contains(ContentStatus.failed));
      expect(ContentStatus.values, contains(ContentStatus.updateAvailable));
    });

    test('canDownload returns true for downloadable statuses', () {
      expect(ContentStatus.notDownloaded.canDownload, isTrue);
      expect(ContentStatus.failed.canDownload, isTrue);
      expect(ContentStatus.updateAvailable.canDownload, isTrue);
    });

    test('canDownload returns false for non-downloadable statuses', () {
      expect(ContentStatus.queued.canDownload, isFalse);
      expect(ContentStatus.downloading.canDownload, isFalse);
      expect(ContentStatus.ready.canDownload, isFalse);
    });

    test('isUsable returns true only for ready', () {
      expect(ContentStatus.ready.isUsable, isTrue);
      expect(ContentStatus.notDownloaded.isUsable, isFalse);
      expect(ContentStatus.downloading.isUsable, isFalse);
      expect(ContentStatus.failed.isUsable, isFalse);
    });

    test('isDownloading returns true for downloading and queued', () {
      expect(ContentStatus.downloading.isDownloading, isTrue);
      expect(ContentStatus.queued.isDownloading, isTrue);
      expect(ContentStatus.notDownloaded.isDownloading, isFalse);
      expect(ContentStatus.ready.isDownloading, isFalse);
    });

    test('toStorageString and fromString roundtrip', () {
      for (final status in ContentStatus.values) {
        final stored = status.toStorageString();
        final restored = ContentStatusX.fromString(stored);
        expect(restored, status);
      }
    });
  });

  group('PackageContent', () {
    test('creates with required fields', () {
      const content = PackageContent(
        type: PackageContentType.tiles,
        status: ContentStatus.notDownloaded,
      );

      expect(content.type, PackageContentType.tiles);
      expect(content.status, ContentStatus.notDownloaded);
      expect(content.filePath, isNull);
      expect(content.sizeBytes, 0);
      expect(content.downloadedBytes, 0);
    });

    test('notDownloaded factory creates correct content', () {
      final content = PackageContent.notDownloaded(
        type: PackageContentType.routing,
        sizeBytes: 1000000,
        version: '1.0',
      );

      expect(content.type, PackageContentType.routing);
      expect(content.status, ContentStatus.notDownloaded);
      expect(content.sizeBytes, 1000000);
      expect(content.version, '1.0');
      expect(content.downloadedBytes, 0);
    });

    test('ready factory creates completed content', () {
      final content = PackageContent.ready(
        type: PackageContentType.geocoding,
        filePath: '/path/to/file.db',
        sizeBytes: 2000000,
        version: '2.0',
        checksum: 'abc123',
      );

      expect(content.type, PackageContentType.geocoding);
      expect(content.status, ContentStatus.ready);
      expect(content.filePath, '/path/to/file.db');
      expect(content.sizeBytes, 2000000);
      expect(content.downloadedBytes, 2000000);
      expect(content.version, '2.0');
      expect(content.checksum, 'abc123');
      expect(content.updatedAt, isNotNull);
    });

    test('failed factory creates failed content', () {
      final content = PackageContent.failed(
        type: PackageContentType.tiles,
        errorMessage: 'Network error',
        downloadedBytes: 500000,
        sizeBytes: 1000000,
      );

      expect(content.type, PackageContentType.tiles);
      expect(content.status, ContentStatus.failed);
      expect(content.errorMessage, 'Network error');
      expect(content.downloadedBytes, 500000);
      expect(content.sizeBytes, 1000000);
    });

    group('progress', () {
      test('returns 0 when sizeBytes is 0', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.downloading,
          sizeBytes: 0,
          downloadedBytes: 0,
        );

        expect(content.progress, 0.0);
      });

      test('calculates progress correctly', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.downloading,
          sizeBytes: 1000,
          downloadedBytes: 500,
        );

        expect(content.progress, 0.5);
      });

      test('progressPercent returns integer percentage', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.downloading,
          sizeBytes: 1000,
          downloadedBytes: 333,
        );

        expect(content.progressPercent, 33);
      });
    });

    group('formatted sizes', () {
      test('formats bytes correctly', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.ready,
          sizeBytes: 500,
          downloadedBytes: 500,
        );

        expect(content.sizeFormatted, '500 B');
      });

      test('formats kilobytes correctly', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.ready,
          sizeBytes: 2048,
          downloadedBytes: 2048,
        );

        expect(content.sizeFormatted, '2.0 KB');
      });

      test('formats megabytes correctly', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.ready,
          sizeBytes: 52428800, // 50 MB
          downloadedBytes: 10485760, // 10 MB
        );

        expect(content.sizeFormatted, '50.0 MB');
        expect(content.downloadedSizeFormatted, '10.0 MB');
      });
    });

    group('status checks', () {
      test('isReady returns true when ready with filePath', () {
        final content = PackageContent.ready(
          type: PackageContentType.tiles,
          filePath: '/path/file',
          sizeBytes: 1000,
        );

        expect(content.isReady, isTrue);
      });

      test('isReady returns false when ready without filePath', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.ready,
        );

        expect(content.isReady, isFalse);
      });

      test('isDownloading returns true when downloading', () {
        const content = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.downloading,
        );

        expect(content.isDownloading, isTrue);
      });

      test('canDownload reflects status', () {
        const notDownloaded = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.notDownloaded,
        );
        const downloading = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.downloading,
        );

        expect(notDownloaded.canDownload, isTrue);
        expect(downloading.canDownload, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.downloading,
          sizeBytes: 1000,
          downloadedBytes: 500,
        );

        final updated = original.copyWith(
          status: ContentStatus.ready,
          downloadedBytes: 1000,
          filePath: '/path/file',
        );

        expect(updated.type, PackageContentType.tiles);
        expect(updated.status, ContentStatus.ready);
        expect(updated.sizeBytes, 1000);
        expect(updated.downloadedBytes, 1000);
        expect(updated.filePath, '/path/file');
      });

      test('preserves unchanged fields', () {
        const original = PackageContent(
          type: PackageContentType.routing,
          status: ContentStatus.ready,
          sizeBytes: 2000,
          downloadedBytes: 2000,
          version: '1.0',
          checksum: 'abc',
          filePath: '/path',
        );

        final updated = original.copyWith(downloadedBytes: 1500);

        expect(updated.type, original.type);
        expect(updated.status, original.status);
        expect(updated.sizeBytes, original.sizeBytes);
        expect(updated.version, original.version);
        expect(updated.checksum, original.checksum);
        expect(updated.filePath, original.filePath);
        expect(updated.downloadedBytes, 1500);
      });
    });

    group('equality', () {
      test('equal contents are equal', () {
        const content1 = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.ready,
          filePath: '/path',
          sizeBytes: 1000,
          downloadedBytes: 1000,
        );

        const content2 = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.ready,
          filePath: '/path',
          sizeBytes: 1000,
          downloadedBytes: 1000,
        );

        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('different types are not equal', () {
        const content1 = PackageContent(
          type: PackageContentType.tiles,
          status: ContentStatus.ready,
        );

        const content2 = PackageContent(
          type: PackageContentType.routing,
          status: ContentStatus.ready,
        );

        expect(content1, isNot(equals(content2)));
      });
    });

    test('toString provides useful info', () {
      const content = PackageContent(
        type: PackageContentType.tiles,
        status: ContentStatus.downloading,
        sizeBytes: 1048576,
        downloadedBytes: 524288,
      );

      final str = content.toString();
      expect(str, contains('tiles'));
      expect(str, contains('downloading'));
      expect(str, contains('50%'));
    });
  });
}
