import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/offline/package/models/package_content.dart';
import 'package:qorvia_maps_sdk/src/offline/package/models/package_download_progress.dart';

void main() {
  group('ContentProgress', () {
    test('creates with required fields', () {
      const progress = ContentProgress(
        type: PackageContentType.tiles,
        downloadedBytes: 500,
        totalBytes: 1000,
      );

      expect(progress.type, PackageContentType.tiles);
      expect(progress.downloadedBytes, 500);
      expect(progress.totalBytes, 1000);
      expect(progress.isComplete, isFalse);
      expect(progress.hasFailed, isFalse);
    });

    test('completed factory creates complete progress', () {
      final progress = ContentProgress.completed(
        PackageContentType.routing,
        2000,
      );

      expect(progress.type, PackageContentType.routing);
      expect(progress.downloadedBytes, 2000);
      expect(progress.totalBytes, 2000);
      expect(progress.isComplete, isTrue);
    });

    test('failed factory creates failed progress', () {
      final progress = ContentProgress.failed(
        PackageContentType.geocoding,
        'Network error',
      );

      expect(progress.type, PackageContentType.geocoding);
      expect(progress.hasFailed, isTrue);
      expect(progress.errorMessage, 'Network error');
    });

    group('progress', () {
      test('calculates progress correctly', () {
        const progress = ContentProgress(
          type: PackageContentType.tiles,
          downloadedBytes: 500,
          totalBytes: 1000,
        );

        expect(progress.progress, 0.5);
      });

      test('returns 0 when totalBytes is 0', () {
        const progress = ContentProgress(
          type: PackageContentType.tiles,
          downloadedBytes: 0,
          totalBytes: 0,
        );

        expect(progress.progress, 0.0);
      });

      test('returns 1.0 when complete', () {
        final progress = ContentProgress.completed(
          PackageContentType.tiles,
          1000,
        );

        expect(progress.progress, 1.0);
      });
    });

    group('percent', () {
      test('returns integer percentage', () {
        const progress = ContentProgress(
          type: PackageContentType.tiles,
          downloadedBytes: 333,
          totalBytes: 1000,
        );

        expect(progress.percent, 33);
      });
    });

    group('formatted strings', () {
      test('downloadedFormatted returns human-readable size', () {
        const progress = ContentProgress(
          type: PackageContentType.tiles,
          downloadedBytes: 1048576, // 1 MB
          totalBytes: 2097152, // 2 MB
        );

        expect(progress.downloadedFormatted, '1.0 MB');
      });

      test('totalFormatted returns human-readable size', () {
        const progress = ContentProgress(
          type: PackageContentType.tiles,
          downloadedBytes: 0,
          totalBytes: 52428800, // 50 MB
        );

        expect(progress.totalFormatted, '50.0 MB');
      });
    });

    test('toString provides useful info', () {
      const progress = ContentProgress(
        type: PackageContentType.tiles,
        downloadedBytes: 500,
        totalBytes: 1000,
      );

      final str = progress.toString();
      expect(str, contains('tiles'));
      expect(str, contains('50%'));
    });
  });

  group('PackageDownloadProgress', () {
    test('creates with required fields', () {
      final progress = PackageDownloadProgress(
        packageId: 'test-id',
        contentProgress: {},
      );

      expect(progress.packageId, 'test-id');
      expect(progress.contentProgress, isEmpty);
      expect(progress.currentlyDownloading, isNull);
      expect(progress.errorMessage, isNull);
    });

    test('started factory creates initial progress', () {
      final progress = PackageDownloadProgress.started(
        packageId: 'test-id',
        contentSizes: {
          PackageContentType.tiles: 1000,
          PackageContentType.routing: 2000,
        },
      );

      expect(progress.packageId, 'test-id');
      expect(progress.contentProgress, hasLength(2));
      expect(progress.contentProgress[PackageContentType.tiles]!.totalBytes, 1000);
      expect(progress.contentProgress[PackageContentType.routing]!.totalBytes, 2000);
    });

    test('update factory creates progress with current download', () {
      final progress = PackageDownloadProgress.update(
        packageId: 'test-id',
        contentProgress: {
          PackageContentType.tiles: const ContentProgress(
            type: PackageContentType.tiles,
            downloadedBytes: 500,
            totalBytes: 1000,
          ),
        },
        currentlyDownloading: PackageContentType.tiles,
      );

      expect(progress.currentlyDownloading, PackageContentType.tiles);
    });

    test('completed factory creates complete progress', () {
      final progress = PackageDownloadProgress.completed(
        packageId: 'test-id',
        contentProgress: {
          PackageContentType.tiles: ContentProgress.completed(PackageContentType.tiles, 1000),
        },
      );

      expect(progress.isComplete, isTrue);
    });

    test('error factory creates error progress', () {
      final progress = PackageDownloadProgress.error(
        packageId: 'test-id',
        errorMessage: 'Download failed',
        contentProgress: {},
      );

      expect(progress.hasError, isTrue);
      expect(progress.errorMessage, 'Download failed');
    });

    group('overall progress', () {
      test('calculates overall progress correctly', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: const ContentProgress(
              type: PackageContentType.tiles,
              downloadedBytes: 500,
              totalBytes: 1000,
            ),
            PackageContentType.routing: const ContentProgress(
              type: PackageContentType.routing,
              downloadedBytes: 1000,
              totalBytes: 2000,
            ),
          },
        );

        // Total: 3000, Downloaded: 1500 = 50%
        expect(progress.overallProgress, 0.5);
      });

      test('returns 0 when no content', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {},
        );

        expect(progress.overallProgress, 0.0);
      });

      test('overallPercent returns integer', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: const ContentProgress(
              type: PackageContentType.tiles,
              downloadedBytes: 333,
              totalBytes: 1000,
            ),
          },
        );

        expect(progress.overallPercent, 33);
      });
    });

    group('size calculations', () {
      test('totalSizeBytes sums all content', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: const ContentProgress(
              type: PackageContentType.tiles,
              downloadedBytes: 0,
              totalBytes: 1000,
            ),
            PackageContentType.routing: const ContentProgress(
              type: PackageContentType.routing,
              downloadedBytes: 0,
              totalBytes: 2000,
            ),
          },
        );

        expect(progress.totalBytes, 3000);
      });

      test('downloadedSizeBytes sums all downloaded', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: const ContentProgress(
              type: PackageContentType.tiles,
              downloadedBytes: 500,
              totalBytes: 1000,
            ),
            PackageContentType.routing: const ContentProgress(
              type: PackageContentType.routing,
              downloadedBytes: 1500,
              totalBytes: 2000,
            ),
          },
        );

        expect(progress.downloadedBytes, 2000);
      });

      test('formatted sizes return human-readable strings', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: const ContentProgress(
              type: PackageContentType.tiles,
              downloadedBytes: 1048576, // 1 MB
              totalBytes: 10485760, // 10 MB
            ),
          },
        );

        expect(progress.downloadedSizeFormatted, '1.0 MB');
        expect(progress.totalSizeFormatted, '10.0 MB');
      });
    });

    group('content counts', () {
      test('completedContentCount counts complete content', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: ContentProgress.completed(PackageContentType.tiles, 1000),
            PackageContentType.routing: const ContentProgress(
              type: PackageContentType.routing,
              downloadedBytes: 0,
              totalBytes: 2000,
            ),
          },
        );

        expect(progress.completedContentCount, 1);
      });

      test('totalContentCount returns total count', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: const ContentProgress(
              type: PackageContentType.tiles,
              downloadedBytes: 0,
              totalBytes: 1000,
            ),
            PackageContentType.routing: const ContentProgress(
              type: PackageContentType.routing,
              downloadedBytes: 0,
              totalBytes: 2000,
            ),
          },
        );

        expect(progress.totalContentCount, 2);
      });
    });

    group('status checks', () {
      test('isComplete returns true when using completed factory', () {
        final progress = PackageDownloadProgress.completed(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: ContentProgress.completed(PackageContentType.tiles, 1000),
            PackageContentType.routing: ContentProgress.completed(PackageContentType.routing, 2000),
          },
        );

        expect(progress.isComplete, isTrue);
      });

      test('isComplete returns false when some content not complete', () {
        final progress = PackageDownloadProgress(
          packageId: 'test-id',
          contentProgress: {
            PackageContentType.tiles: ContentProgress.completed(PackageContentType.tiles, 1000),
            PackageContentType.routing: const ContentProgress(
              type: PackageContentType.routing,
              downloadedBytes: 500,
              totalBytes: 2000,
            ),
          },
        );

        expect(progress.isComplete, isFalse);
      });

      test('hasError returns true when error message set', () {
        final progress = PackageDownloadProgress.error(
          packageId: 'test-id',
          errorMessage: 'Error',
          contentProgress: {},
        );

        expect(progress.hasError, isTrue);
      });
    });

    test('copyWithContentProgress creates new progress with updated content', () {
      final original = PackageDownloadProgress(
        packageId: 'test-id',
        contentProgress: {
          PackageContentType.tiles: const ContentProgress(
            type: PackageContentType.tiles,
            downloadedBytes: 500,
            totalBytes: 1000,
          ),
        },
      );

      final updated = original.copyWithContentProgress(
        PackageContentType.tiles,
        ContentProgress.completed(PackageContentType.tiles, 1000),
      );

      expect(updated.contentProgress[PackageContentType.tiles]!.isComplete, isTrue);
      expect(original.contentProgress[PackageContentType.tiles]!.isComplete, isFalse);
    });

    test('toString provides useful info', () {
      final progress = PackageDownloadProgress(
        packageId: 'test-id',
        contentProgress: {
          PackageContentType.tiles: const ContentProgress(
            type: PackageContentType.tiles,
            downloadedBytes: 500,
            totalBytes: 1000,
          ),
        },
        currentlyDownloading: PackageContentType.tiles,
      );

      final str = progress.toString();
      expect(str, contains('test-id'));
      expect(str, contains('50%'));
    });
  });

  group('PackageDownloadEventType', () {
    test('has all expected values', () {
      expect(PackageDownloadEventType.values, hasLength(10));
      expect(PackageDownloadEventType.values, contains(PackageDownloadEventType.started));
      expect(PackageDownloadEventType.values, contains(PackageDownloadEventType.progress));
      expect(
          PackageDownloadEventType.values, contains(PackageDownloadEventType.contentStarted));
      expect(
          PackageDownloadEventType.values, contains(PackageDownloadEventType.contentCompleted));
      expect(
          PackageDownloadEventType.values, contains(PackageDownloadEventType.contentFailed));
      expect(PackageDownloadEventType.values, contains(PackageDownloadEventType.paused));
      expect(PackageDownloadEventType.values, contains(PackageDownloadEventType.resumed));
      expect(PackageDownloadEventType.values, contains(PackageDownloadEventType.completed));
      expect(PackageDownloadEventType.values, contains(PackageDownloadEventType.failed));
      expect(PackageDownloadEventType.values, contains(PackageDownloadEventType.cancelled));
    });
  });

  group('PackageDownloadEvent', () {
    test('started factory creates correct event', () {
      final progress = PackageDownloadProgress.started(
        packageId: 'test-id',
        contentSizes: {},
      );
      final event = PackageDownloadEvent.started(progress);

      expect(event.type, PackageDownloadEventType.started);
      expect(event.progress, progress);
      expect(event.contentType, isNull);
    });

    test('progress factory creates correct event', () {
      final progress = PackageDownloadProgress(
        packageId: 'test-id',
        contentProgress: {},
      );
      final event = PackageDownloadEvent.progress(progress);

      expect(event.type, PackageDownloadEventType.progress);
    });

    test('contentStarted factory creates correct event', () {
      final progress = PackageDownloadProgress(
        packageId: 'test-id',
        contentProgress: {},
      );
      final event = PackageDownloadEvent.contentStarted(progress, PackageContentType.tiles);

      expect(event.type, PackageDownloadEventType.contentStarted);
      expect(event.contentType, PackageContentType.tiles);
    });

    test('contentCompleted factory creates correct event', () {
      final progress = PackageDownloadProgress(
        packageId: 'test-id',
        contentProgress: {},
      );
      final event = PackageDownloadEvent.contentCompleted(progress, PackageContentType.routing);

      expect(event.type, PackageDownloadEventType.contentCompleted);
      expect(event.contentType, PackageContentType.routing);
    });

    test('completed factory creates correct event', () {
      final progress = PackageDownloadProgress.completed(
        packageId: 'test-id',
        contentProgress: {},
      );
      final event = PackageDownloadEvent.completed(progress);

      expect(event.type, PackageDownloadEventType.completed);
    });

    test('failed factory creates correct event', () {
      final progress = PackageDownloadProgress.error(
        packageId: 'test-id',
        errorMessage: 'Error',
        contentProgress: {},
      );
      final event = PackageDownloadEvent.failed(progress);

      expect(event.type, PackageDownloadEventType.failed);
    });

    test('toString provides useful info', () {
      final event = PackageDownloadEvent.started(
        PackageDownloadProgress.started(
          packageId: 'test-id',
          contentSizes: {},
        ),
      );

      final str = event.toString();
      expect(str, contains('started'));
      expect(str, contains('package')); // contentType is null, shows 'package'
      expect(str, contains('0%'));
    });
  });
}
