/// Represents the progress of an offline region download.
class DownloadProgress {
  /// ID of the region being downloaded.
  final String regionId;

  /// Number of tiles downloaded so far.
  final int completedTiles;

  /// Total number of tiles to download.
  final int totalTiles;

  /// Number of bytes downloaded.
  final int downloadedBytes;

  /// Whether the download is complete.
  final bool isComplete;

  /// Whether the download encountered an error.
  final bool hasError;

  /// Error message if [hasError] is true.
  final String? errorMessage;

  const DownloadProgress({
    required this.regionId,
    required this.completedTiles,
    required this.totalTiles,
    required this.downloadedBytes,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
  });

  /// Creates a progress update for an ongoing download.
  factory DownloadProgress.update({
    required String regionId,
    required int completedTiles,
    required int totalTiles,
    required int downloadedBytes,
  }) {
    return DownloadProgress(
      regionId: regionId,
      completedTiles: completedTiles,
      totalTiles: totalTiles,
      downloadedBytes: downloadedBytes,
      isComplete: completedTiles >= totalTiles && totalTiles > 0,
    );
  }

  /// Creates a progress indicating download completion.
  factory DownloadProgress.completed({
    required String regionId,
    required int totalTiles,
    required int downloadedBytes,
  }) {
    return DownloadProgress(
      regionId: regionId,
      completedTiles: totalTiles,
      totalTiles: totalTiles,
      downloadedBytes: downloadedBytes,
      isComplete: true,
    );
  }

  /// Creates a progress indicating download failure.
  factory DownloadProgress.error({
    required String regionId,
    required String message,
    int completedTiles = 0,
    int totalTiles = 0,
    int downloadedBytes = 0,
  }) {
    return DownloadProgress(
      regionId: regionId,
      completedTiles: completedTiles,
      totalTiles: totalTiles,
      downloadedBytes: downloadedBytes,
      isComplete: false,
      hasError: true,
      errorMessage: message,
    );
  }

  /// Creates initial progress when download starts.
  factory DownloadProgress.started({
    required String regionId,
    int totalTiles = 0,
  }) {
    return DownloadProgress(
      regionId: regionId,
      completedTiles: 0,
      totalTiles: totalTiles,
      downloadedBytes: 0,
    );
  }

  /// Download progress as a percentage (0.0 to 1.0).
  double get progress {
    if (totalTiles == 0) return 0.0;
    return completedTiles / totalTiles;
  }

  /// Download progress as an integer percentage (0 to 100).
  int get progressPercent => (progress * 100).round();

  /// Remaining tiles to download.
  int get remainingTiles => totalTiles - completedTiles;

  /// Human-readable size string.
  String get sizeFormatted {
    if (downloadedBytes < 1024) return '$downloadedBytes B';
    if (downloadedBytes < 1024 * 1024) {
      return '${(downloadedBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (downloadedBytes < 1024 * 1024 * 1024) {
      return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(downloadedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  String toString() =>
      'DownloadProgress(region: $regionId, $completedTiles/$totalTiles tiles, '
      '$progressPercent%, $sizeFormatted'
      '${isComplete ? ', complete' : ''}'
      '${hasError ? ', error: $errorMessage' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadProgress &&
          runtimeType == other.runtimeType &&
          regionId == other.regionId &&
          completedTiles == other.completedTiles &&
          totalTiles == other.totalTiles &&
          downloadedBytes == other.downloadedBytes &&
          isComplete == other.isComplete &&
          hasError == other.hasError;

  @override
  int get hashCode => Object.hash(
        regionId,
        completedTiles,
        totalTiles,
        downloadedBytes,
        isComplete,
        hasError,
      );
}

/// Event types for download state changes.
enum DownloadEventType {
  /// Download has started.
  started,

  /// Progress update during download.
  progress,

  /// Download was paused.
  paused,

  /// Download was resumed.
  resumed,

  /// Download completed successfully.
  completed,

  /// Download failed with an error.
  failed,

  /// Download was cancelled.
  cancelled,
}

/// Event emitted during offline region download.
class DownloadEvent {
  /// Type of the event.
  final DownloadEventType type;

  /// Current progress information.
  final DownloadProgress progress;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  DownloadEvent({
    required this.type,
    required this.progress,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory DownloadEvent.started(String regionId) {
    return DownloadEvent(
      type: DownloadEventType.started,
      progress: DownloadProgress.started(regionId: regionId),
    );
  }

  factory DownloadEvent.progress(DownloadProgress progress) {
    return DownloadEvent(
      type: DownloadEventType.progress,
      progress: progress,
    );
  }

  factory DownloadEvent.completed(DownloadProgress progress) {
    return DownloadEvent(
      type: DownloadEventType.completed,
      progress: progress,
    );
  }

  factory DownloadEvent.failed(String regionId, String error) {
    return DownloadEvent(
      type: DownloadEventType.failed,
      progress: DownloadProgress.error(regionId: regionId, message: error),
    );
  }

  factory DownloadEvent.paused(DownloadProgress progress) {
    return DownloadEvent(
      type: DownloadEventType.paused,
      progress: progress,
    );
  }

  factory DownloadEvent.cancelled(String regionId) {
    return DownloadEvent(
      type: DownloadEventType.cancelled,
      progress: DownloadProgress(
        regionId: regionId,
        completedTiles: 0,
        totalTiles: 0,
        downloadedBytes: 0,
      ),
    );
  }

  @override
  String toString() => 'DownloadEvent($type, $progress)';
}
