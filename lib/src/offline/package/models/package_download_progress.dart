import '../../../navigation/navigation_logger.dart';
import 'package_content.dart';

const _logTag = 'PackageDownloadProgress';

/// Progress information for a single content type download.
class ContentProgress {
  /// Type of content being downloaded.
  final PackageContentType type;

  /// Bytes downloaded so far.
  final int downloadedBytes;

  /// Total bytes to download.
  final int totalBytes;

  /// Whether this content download is complete.
  final bool isComplete;

  /// Whether this content download has failed.
  final bool hasFailed;

  /// Error message if failed.
  final String? errorMessage;

  const ContentProgress({
    required this.type,
    required this.downloadedBytes,
    required this.totalBytes,
    this.isComplete = false,
    this.hasFailed = false,
    this.errorMessage,
  });

  /// Creates progress for a content that hasn't started.
  factory ContentProgress.notStarted(PackageContentType type, int totalBytes) {
    return ContentProgress(
      type: type,
      downloadedBytes: 0,
      totalBytes: totalBytes,
    );
  }

  /// Creates progress for a completed content.
  factory ContentProgress.completed(PackageContentType type, int totalBytes) {
    return ContentProgress(
      type: type,
      downloadedBytes: totalBytes,
      totalBytes: totalBytes,
      isComplete: true,
    );
  }

  /// Creates progress for a failed content.
  factory ContentProgress.failed(
    PackageContentType type,
    String errorMessage, {
    int downloadedBytes = 0,
    int totalBytes = 0,
  }) {
    return ContentProgress(
      type: type,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      hasFailed: true,
      errorMessage: errorMessage,
    );
  }

  /// Progress as a value from 0.0 to 1.0.
  double get progress {
    if (totalBytes == 0) return 0.0;
    return downloadedBytes / totalBytes;
  }

  /// Progress as a percentage (0-100).
  int get percent => (progress * 100).round();

  /// Human-readable downloaded size.
  String get downloadedFormatted => _formatBytes(downloadedBytes);

  /// Human-readable total size.
  String get totalFormatted => _formatBytes(totalBytes);

  /// Formats bytes to human-readable string.
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  String toString() =>
      'ContentProgress(${type.name}: $percent%, '
      '$downloadedFormatted/$totalFormatted'
      '${isComplete ? ', complete' : ''}'
      '${hasFailed ? ', failed: $errorMessage' : ''})';
}

/// Aggregated download progress for an entire offline package.
///
/// Tracks progress across all content types (tiles, routing, geocoding)
/// and provides overall progress calculation.
class PackageDownloadProgress {
  /// ID of the package being downloaded.
  final String packageId;

  /// Progress for each content type.
  final Map<PackageContentType, ContentProgress> contentProgress;

  /// Content type currently being downloaded (null if none or all complete).
  final PackageContentType? currentlyDownloading;

  /// Whether all content has been downloaded.
  final bool isComplete;

  /// Whether any content has failed.
  final bool hasError;

  /// Error message if any content failed.
  final String? errorMessage;

  /// Timestamp of this progress update.
  final DateTime timestamp;

  PackageDownloadProgress({
    required this.packageId,
    required this.contentProgress,
    this.currentlyDownloading,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates initial progress when download starts.
  factory PackageDownloadProgress.started({
    required String packageId,
    required Map<PackageContentType, int> contentSizes,
  }) {
    NavigationLogger.info(_logTag, 'Package download started', {
      'packageId': packageId,
      'contentTypes': contentSizes.keys.map((e) => e.name).toList(),
      'totalSize': contentSizes.values.fold<int>(0, (a, b) => a + b),
    });

    final progress = <PackageContentType, ContentProgress>{};
    for (final entry in contentSizes.entries) {
      progress[entry.key] = ContentProgress.notStarted(entry.key, entry.value);
    }

    // First content type to download
    final firstType =
        contentSizes.keys.isNotEmpty ? contentSizes.keys.first : null;

    return PackageDownloadProgress(
      packageId: packageId,
      contentProgress: progress,
      currentlyDownloading: firstType,
    );
  }

  /// Creates progress update during download.
  factory PackageDownloadProgress.update({
    required String packageId,
    required Map<PackageContentType, ContentProgress> contentProgress,
    required PackageContentType currentlyDownloading,
  }) {
    final overall = _calculateOverallProgress(contentProgress);

    NavigationLogger.debug(_logTag, 'Package download progress', {
      'packageId': packageId,
      'currentType': currentlyDownloading.name,
      'overallProgress': (overall * 100).round(),
    });

    return PackageDownloadProgress(
      packageId: packageId,
      contentProgress: contentProgress,
      currentlyDownloading: currentlyDownloading,
    );
  }

  /// Creates progress indicating package download completion.
  factory PackageDownloadProgress.completed({
    required String packageId,
    required Map<PackageContentType, ContentProgress> contentProgress,
  }) {
    final totalBytes = contentProgress.values
        .fold<int>(0, (sum, p) => sum + p.totalBytes);

    NavigationLogger.info(_logTag, 'Package download completed', {
      'packageId': packageId,
      'contentTypes': contentProgress.keys.map((e) => e.name).toList(),
      'totalSize': totalBytes,
    });

    return PackageDownloadProgress(
      packageId: packageId,
      contentProgress: contentProgress,
      currentlyDownloading: null,
      isComplete: true,
    );
  }

  /// Creates progress indicating download failure.
  factory PackageDownloadProgress.error({
    required String packageId,
    required String errorMessage,
    required Map<PackageContentType, ContentProgress> contentProgress,
    PackageContentType? failedType,
  }) {
    NavigationLogger.error(_logTag, 'Package download failed', {
      'packageId': packageId,
      'failedType': failedType?.name,
      'error': errorMessage,
    });

    return PackageDownloadProgress(
      packageId: packageId,
      contentProgress: contentProgress,
      currentlyDownloading: null,
      hasError: true,
      errorMessage: errorMessage,
    );
  }

  /// Overall progress as a value from 0.0 to 1.0.
  ///
  /// Calculated as weighted average based on content sizes.
  double get overallProgress => _calculateOverallProgress(contentProgress);

  /// Overall progress as a percentage (0-100).
  int get overallPercent => (overallProgress * 100).round();

  /// Total bytes across all content types.
  int get totalBytes =>
      contentProgress.values.fold<int>(0, (sum, p) => sum + p.totalBytes);

  /// Total downloaded bytes across all content types.
  int get downloadedBytes =>
      contentProgress.values.fold<int>(0, (sum, p) => sum + p.downloadedBytes);

  /// Human-readable total size.
  String get totalSizeFormatted => _formatBytes(totalBytes);

  /// Human-readable downloaded size.
  String get downloadedSizeFormatted => _formatBytes(downloadedBytes);

  /// Number of completed content types.
  int get completedContentCount =>
      contentProgress.values.where((p) => p.isComplete).length;

  /// Total number of content types.
  int get totalContentCount => contentProgress.length;

  /// List of content types that have failed.
  List<PackageContentType> get failedContentTypes => contentProgress.entries
      .where((e) => e.value.hasFailed)
      .map((e) => e.key)
      .toList();

  /// List of content types that are complete.
  List<PackageContentType> get completedContentTypes => contentProgress.entries
      .where((e) => e.value.isComplete)
      .map((e) => e.key)
      .toList();

  /// Get progress for a specific content type.
  ContentProgress? getProgress(PackageContentType type) => contentProgress[type];

  /// Calculates overall progress as weighted average by size.
  static double _calculateOverallProgress(
    Map<PackageContentType, ContentProgress> progress,
  ) {
    if (progress.isEmpty) return 0.0;

    final totalBytes =
        progress.values.fold<int>(0, (sum, p) => sum + p.totalBytes);

    if (totalBytes == 0) return 0.0;

    final downloadedBytes =
        progress.values.fold<int>(0, (sum, p) => sum + p.downloadedBytes);

    return downloadedBytes / totalBytes;
  }

  /// Formats bytes to human-readable string.
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Creates a copy with updated content progress.
  PackageDownloadProgress copyWithContentProgress(
    PackageContentType type,
    ContentProgress progress,
  ) {
    final newProgress = Map<PackageContentType, ContentProgress>.from(contentProgress);
    newProgress[type] = progress;

    return PackageDownloadProgress(
      packageId: packageId,
      contentProgress: newProgress,
      currentlyDownloading: currentlyDownloading,
      isComplete: isComplete,
      hasError: hasError,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() =>
      'PackageDownloadProgress(package: $packageId, '
      'overall: $overallPercent%, '
      '$completedContentCount/$totalContentCount types, '
      '$downloadedSizeFormatted/$totalSizeFormatted'
      '${isComplete ? ', complete' : ''}'
      '${hasError ? ', error: $errorMessage' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageDownloadProgress &&
          runtimeType == other.runtimeType &&
          packageId == other.packageId &&
          overallPercent == other.overallPercent &&
          isComplete == other.isComplete &&
          hasError == other.hasError;

  @override
  int get hashCode => Object.hash(
        packageId,
        overallPercent,
        isComplete,
        hasError,
      );
}

/// Event types for package download state changes.
enum PackageDownloadEventType {
  /// Package download has started.
  started,

  /// Progress update during download.
  progress,

  /// Started downloading a new content type.
  contentStarted,

  /// Completed downloading a content type.
  contentCompleted,

  /// A content type failed to download.
  contentFailed,

  /// Download was paused.
  paused,

  /// Download was resumed.
  resumed,

  /// All content downloaded successfully.
  completed,

  /// Download failed (one or more content types failed).
  failed,

  /// Download was cancelled.
  cancelled,
}

/// Event emitted during package download.
class PackageDownloadEvent {
  /// Type of the event.
  final PackageDownloadEventType type;

  /// Current progress information.
  final PackageDownloadProgress progress;

  /// Content type this event relates to (for content-specific events).
  final PackageContentType? contentType;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  PackageDownloadEvent({
    required this.type,
    required this.progress,
    this.contentType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PackageDownloadEvent.started(PackageDownloadProgress progress) {
    return PackageDownloadEvent(
      type: PackageDownloadEventType.started,
      progress: progress,
    );
  }

  factory PackageDownloadEvent.progress(PackageDownloadProgress progress) {
    return PackageDownloadEvent(
      type: PackageDownloadEventType.progress,
      progress: progress,
    );
  }

  factory PackageDownloadEvent.contentStarted(
    PackageDownloadProgress progress,
    PackageContentType contentType,
  ) {
    return PackageDownloadEvent(
      type: PackageDownloadEventType.contentStarted,
      progress: progress,
      contentType: contentType,
    );
  }

  factory PackageDownloadEvent.contentCompleted(
    PackageDownloadProgress progress,
    PackageContentType contentType,
  ) {
    return PackageDownloadEvent(
      type: PackageDownloadEventType.contentCompleted,
      progress: progress,
      contentType: contentType,
    );
  }

  factory PackageDownloadEvent.completed(PackageDownloadProgress progress) {
    return PackageDownloadEvent(
      type: PackageDownloadEventType.completed,
      progress: progress,
    );
  }

  factory PackageDownloadEvent.failed(PackageDownloadProgress progress) {
    return PackageDownloadEvent(
      type: PackageDownloadEventType.failed,
      progress: progress,
    );
  }

  @override
  String toString() =>
      'PackageDownloadEvent($type, ${contentType?.name ?? 'package'}, '
      '${progress.overallPercent}%)';
}
