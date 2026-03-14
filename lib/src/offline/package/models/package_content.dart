import '../../../navigation/navigation_logger.dart';

const _logTag = 'PackageContent';

/// Types of content that can be included in an offline package.
enum PackageContentType {
  /// Map tiles for visual rendering.
  tiles,

  /// Routing graph data for offline navigation.
  routing,

  /// Geocoding database for address search.
  geocoding,

  /// Reverse geocoding database for coordinate-to-address lookup.
  reverseGeocoding,
}

/// Extension for PackageContentType utilities.
extension PackageContentTypeX on PackageContentType {
  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case PackageContentType.tiles:
        return 'Map Tiles';
      case PackageContentType.routing:
        return 'Routing Data';
      case PackageContentType.geocoding:
        return 'Address Search';
      case PackageContentType.reverseGeocoding:
        return 'Reverse Geocoding';
    }
  }

  /// Localized display name (Russian).
  String get displayNameRu {
    switch (this) {
      case PackageContentType.tiles:
        return 'Тайлы карты';
      case PackageContentType.routing:
        return 'Данные маршрутов';
      case PackageContentType.geocoding:
        return 'Поиск адресов';
      case PackageContentType.reverseGeocoding:
        return 'Обратный геокодинг';
    }
  }

  /// File extension for this content type.
  String get fileExtension {
    switch (this) {
      case PackageContentType.tiles:
        return '.mbtiles';
      case PackageContentType.routing:
        return '.ghz';
      case PackageContentType.geocoding:
        return '.db';
      case PackageContentType.reverseGeocoding:
        return '.db';
    }
  }

  /// Converts to string for storage.
  String toStorageString() => name;

  /// Parses from storage string.
  static PackageContentType fromString(String value) {
    return PackageContentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PackageContentType.tiles,
    );
  }
}

/// Status of a single content type within a package.
enum ContentStatus {
  /// Content has not been downloaded yet.
  notDownloaded,

  /// Content is queued for download.
  queued,

  /// Content is currently being downloaded.
  downloading,

  /// Content has been downloaded and is ready for use.
  ready,

  /// Content download failed.
  failed,

  /// Content needs update (newer version available).
  updateAvailable,
}

/// Extension for ContentStatus utilities.
extension ContentStatusX on ContentStatus {
  /// Whether this status allows starting a download.
  bool get canDownload =>
      this == ContentStatus.notDownloaded ||
      this == ContentStatus.failed ||
      this == ContentStatus.updateAvailable;

  /// Whether this status indicates the content is usable.
  bool get isUsable => this == ContentStatus.ready;

  /// Whether this status indicates active download.
  bool get isDownloading =>
      this == ContentStatus.downloading || this == ContentStatus.queued;

  /// Converts to string for storage.
  String toStorageString() => name;

  /// Parses from storage string.
  static ContentStatus fromString(String value) {
    return ContentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContentStatus.notDownloaded,
    );
  }
}

/// Represents a single type of content within an offline package.
///
/// Each package can contain multiple content types (tiles, routing, geocoding).
/// This class tracks the download status and metadata for one content type.
class PackageContent {
  /// Type of this content.
  final PackageContentType type;

  /// Current download/availability status.
  final ContentStatus status;

  /// Path to the downloaded file (null if not downloaded).
  final String? filePath;

  /// Total size of the content in bytes.
  final int sizeBytes;

  /// Number of bytes downloaded so far.
  final int downloadedBytes;

  /// Version identifier for this content.
  final String? version;

  /// SHA-256 checksum for verification.
  final String? checksum;

  /// Error message if status is [ContentStatus.failed].
  final String? errorMessage;

  /// When this content was last updated.
  final DateTime? updatedAt;

  const PackageContent({
    required this.type,
    required this.status,
    this.filePath,
    this.sizeBytes = 0,
    this.downloadedBytes = 0,
    this.version,
    this.checksum,
    this.errorMessage,
    this.updatedAt,
  });

  /// Creates a content entry for content that hasn't been downloaded.
  factory PackageContent.notDownloaded({
    required PackageContentType type,
    int sizeBytes = 0,
    String? version,
    String? checksum,
  }) {
    NavigationLogger.debug(_logTag, 'Creating not downloaded content', {
      'type': type.name,
      'sizeBytes': sizeBytes,
      'version': version,
    });

    return PackageContent(
      type: type,
      status: ContentStatus.notDownloaded,
      sizeBytes: sizeBytes,
      version: version,
      checksum: checksum,
    );
  }

  /// Creates a content entry for successfully downloaded content.
  factory PackageContent.ready({
    required PackageContentType type,
    required String filePath,
    required int sizeBytes,
    String? version,
    String? checksum,
  }) {
    NavigationLogger.info(_logTag, 'Content ready', {
      'type': type.name,
      'filePath': filePath,
      'sizeBytes': sizeBytes,
      'version': version,
    });

    return PackageContent(
      type: type,
      status: ContentStatus.ready,
      filePath: filePath,
      sizeBytes: sizeBytes,
      downloadedBytes: sizeBytes,
      version: version,
      checksum: checksum,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a content entry for failed download.
  factory PackageContent.failed({
    required PackageContentType type,
    required String errorMessage,
    int downloadedBytes = 0,
    int sizeBytes = 0,
  }) {
    NavigationLogger.error(_logTag, 'Content download failed', {
      'type': type.name,
      'error': errorMessage,
      'downloadedBytes': downloadedBytes,
    });

    return PackageContent(
      type: type,
      status: ContentStatus.failed,
      sizeBytes: sizeBytes,
      downloadedBytes: downloadedBytes,
      errorMessage: errorMessage,
      updatedAt: DateTime.now(),
    );
  }

  /// Download progress as a value from 0.0 to 1.0.
  double get progress {
    if (sizeBytes == 0) return 0.0;
    return downloadedBytes / sizeBytes;
  }

  /// Download progress as a percentage (0-100).
  int get progressPercent => (progress * 100).round();

  /// Human-readable size string.
  String get sizeFormatted => _formatBytes(sizeBytes);

  /// Human-readable downloaded size string.
  String get downloadedSizeFormatted => _formatBytes(downloadedBytes);

  /// Whether this content is available for use.
  bool get isReady => status == ContentStatus.ready && filePath != null;

  /// Whether this content is being downloaded.
  bool get isDownloading => status == ContentStatus.downloading;

  /// Whether download can be started for this content.
  bool get canDownload => status.canDownload;

  /// Creates a copy with updated fields.
  PackageContent copyWith({
    PackageContentType? type,
    ContentStatus? status,
    String? filePath,
    int? sizeBytes,
    int? downloadedBytes,
    String? version,
    String? checksum,
    String? errorMessage,
    DateTime? updatedAt,
  }) {
    final newContent = PackageContent(
      type: type ?? this.type,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      version: version ?? this.version,
      checksum: checksum ?? this.checksum,
      errorMessage: errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );

    NavigationLogger.debug(_logTag, 'Content updated', {
      'type': newContent.type.name,
      'status': newContent.status.name,
      'progress': newContent.progressPercent,
    });

    return newContent;
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

  @override
  String toString() =>
      'PackageContent(type: ${type.name}, status: ${status.name}, '
      'progress: $progressPercent%, size: $sizeFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageContent &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          status == other.status &&
          filePath == other.filePath &&
          sizeBytes == other.sizeBytes &&
          downloadedBytes == other.downloadedBytes;

  @override
  int get hashCode => Object.hash(
        type,
        status,
        filePath,
        sizeBytes,
        downloadedBytes,
      );
}
