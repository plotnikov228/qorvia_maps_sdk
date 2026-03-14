import 'dart:math' as math;

import '../../../models/coordinates.dart';
import '../../../navigation/navigation_logger.dart';
import '../../tiles/offline_region.dart';
import 'package_content.dart';

const _logTag = 'OfflinePackage';

/// Status of an offline package.
enum PackageStatus {
  /// Package is created but download hasn't started.
  pending,

  /// Package content is being downloaded.
  downloading,

  /// Download is paused by user.
  paused,

  /// All requested content has been downloaded successfully.
  completed,

  /// Some content downloaded, but some failed.
  partiallyComplete,

  /// All downloads failed.
  failed,
}

/// Extension for parsing PackageStatus from string.
extension PackageStatusX on PackageStatus {
  /// Converts status to string for storage.
  String toStorageString() => name;

  /// Parses status from storage string.
  static PackageStatus fromString(String value) {
    return PackageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PackageStatus.pending,
    );
  }

  /// Whether this status allows starting a download.
  bool get canDownload =>
      this == PackageStatus.pending ||
      this == PackageStatus.paused ||
      this == PackageStatus.failed ||
      this == PackageStatus.partiallyComplete;

  /// Whether any content is available for use.
  bool get hasUsableContent =>
      this == PackageStatus.completed || this == PackageStatus.partiallyComplete;
}

/// Represents a unified offline package containing multiple content types.
///
/// A package bundles together:
/// - Map tiles for visual rendering
/// - Routing data for offline navigation
/// - Geocoding data for address search
/// - Reverse geocoding data for coordinate lookups
///
/// This allows users to download a complete offline experience for a region.
class OfflinePackage {
  /// Unique identifier for this package.
  final String id;

  /// Human-readable name for the package.
  final String name;

  /// Geographic bounds covered by this package.
  final OfflineBounds bounds;

  /// Minimum zoom level for tiles (if included).
  final double minZoom;

  /// Maximum zoom level for tiles (if included).
  final double maxZoom;

  /// Current status of the package.
  final PackageStatus status;

  /// Content types and their status/metadata.
  final Map<PackageContentType, PackageContent> contents;

  /// Total size of all content in bytes.
  final int totalSizeBytes;

  /// Total downloaded bytes across all content.
  final int downloadedSizeBytes;

  /// Error message if status is [PackageStatus.failed].
  final String? errorMessage;

  /// When the package was created.
  final DateTime createdAt;

  /// When the package was last updated.
  final DateTime updatedAt;

  /// Server region ID (for preset packages).
  final String? serverRegionId;

  /// Style URL for map tiles.
  final String? styleUrl;

  const OfflinePackage({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.status,
    required this.contents,
    required this.totalSizeBytes,
    required this.downloadedSizeBytes,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.serverRegionId,
    this.styleUrl,
  });

  /// Creates a new package in pending state.
  factory OfflinePackage.create({
    required String id,
    required String name,
    required OfflineBounds bounds,
    required double minZoom,
    required double maxZoom,
    required Set<PackageContentType> contentTypes,
    Map<PackageContentType, int>? contentSizes,
    String? serverRegionId,
    String? styleUrl,
  }) {
    NavigationLogger.info(_logTag, 'Creating package', {
      'id': id,
      'name': name,
      'bounds': bounds.toString(),
      'contentTypes': contentTypes.map((t) => t.name).toList(),
    });

    final contents = <PackageContentType, PackageContent>{};
    int totalSize = 0;

    for (final type in contentTypes) {
      final size = contentSizes?[type] ?? 0;
      contents[type] = PackageContent.notDownloaded(
        type: type,
        sizeBytes: size,
      );
      totalSize += size;
    }

    final now = DateTime.now();

    return OfflinePackage(
      id: id,
      name: name,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      status: PackageStatus.pending,
      contents: contents,
      totalSizeBytes: totalSize,
      downloadedSizeBytes: 0,
      createdAt: now,
      updatedAt: now,
      serverRegionId: serverRegionId,
      styleUrl: styleUrl,
    );
  }

  // ============ Content Access ============

  /// Checks if package includes a specific content type.
  bool hasContent(PackageContentType type) => contents.containsKey(type);

  /// Gets the status of a specific content type.
  ContentStatus? getContentStatus(PackageContentType type) =>
      contents[type]?.status;

  /// Gets the content metadata for a specific type.
  PackageContent? getContent(PackageContentType type) => contents[type];

  /// Gets all content types included in this package.
  Set<PackageContentType> get contentTypes => contents.keys.toSet();

  /// Gets all content types that are ready for use.
  Set<PackageContentType> get readyContentTypes => contents.entries
      .where((e) => e.value.isReady)
      .map((e) => e.key)
      .toSet();

  /// Gets all content types that need download.
  Set<PackageContentType> get pendingContentTypes => contents.entries
      .where((e) => e.value.canDownload)
      .map((e) => e.key)
      .toSet();

  /// Gets all content types that failed to download.
  Set<PackageContentType> get failedContentTypes => contents.entries
      .where((e) => e.value.status == ContentStatus.failed)
      .map((e) => e.key)
      .toSet();

  // ============ Progress ============

  /// Overall download progress as a value from 0.0 to 1.0.
  double get overallProgress {
    if (totalSizeBytes == 0) return 0.0;
    return downloadedSizeBytes / totalSizeBytes;
  }

  /// Overall download progress as a percentage string.
  String get progressPercentage => '${(overallProgress * 100).toStringAsFixed(1)}%';

  /// Number of content types that are ready.
  int get readyContentCount =>
      contents.values.where((c) => c.isReady).length;

  /// Total number of content types.
  int get totalContentCount => contents.length;

  // ============ Status Checks ============

  /// Whether the package is fully downloaded.
  bool get isComplete => status == PackageStatus.completed;

  /// Whether the package is currently downloading.
  bool get isDownloading => status == PackageStatus.downloading;

  /// Whether download can be started or resumed.
  bool get canDownload => status.canDownload;

  /// Whether any content is usable.
  bool get hasUsableContent => status.hasUsableContent;

  /// Whether this is a preset package from the server.
  bool get isPreset => serverRegionId != null;

  /// Whether tiles are available for offline use.
  bool get hasTilesReady =>
      contents[PackageContentType.tiles]?.isReady ?? false;

  /// Whether routing is available for offline use.
  bool get hasRoutingReady =>
      contents[PackageContentType.routing]?.isReady ?? false;

  /// Whether geocoding is available for offline use.
  bool get hasGeocodingReady =>
      contents[PackageContentType.geocoding]?.isReady ?? false;

  /// Whether reverse geocoding is available for offline use.
  bool get hasReverseGeocodingReady =>
      contents[PackageContentType.reverseGeocoding]?.isReady ?? false;

  // ============ Size Formatting ============

  /// Human-readable total size string.
  String get totalSizeFormatted => _formatBytes(totalSizeBytes);

  /// Human-readable downloaded size string.
  String get downloadedSizeFormatted => _formatBytes(downloadedSizeBytes);

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

  // ============ Location Checks ============

  /// Checks if a location is within this package's bounds.
  bool containsLocation(Coordinates location) {
    return location.lat >= bounds.southwest.lat &&
        location.lat <= bounds.northeast.lat &&
        location.lon >= bounds.southwest.lon &&
        location.lon <= bounds.northeast.lon;
  }

  /// Checks if a route (from → to) is covered by this package.
  bool coversRoute(Coordinates from, Coordinates to) {
    return containsLocation(from) && containsLocation(to);
  }

  // ============ Conversion ============

  /// Converts to legacy OfflineRegion for backward compatibility.
  ///
  /// Only includes tile-related information.
  OfflineRegion toOfflineRegion() {
    final tilesContent = contents[PackageContentType.tiles];

    return OfflineRegion(
      id: id,
      name: name,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      styleUrl: styleUrl ?? '',
      status: _packageStatusToRegionStatus(status),
      downloadedTiles: 0, // Not tracked in package
      totalTiles: 0, // Not tracked in package
      sizeBytes: tilesContent?.sizeBytes ?? 0,
      errorMessage: errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt,
      filePath: tilesContent?.filePath,
      serverRegionId: serverRegionId,
      regionType: serverRegionId != null ? 'preset' : 'custom',
    );
  }

  /// Converts package status to region status.
  OfflineRegionStatus _packageStatusToRegionStatus(PackageStatus status) {
    switch (status) {
      case PackageStatus.pending:
        return OfflineRegionStatus.pending;
      case PackageStatus.downloading:
        return OfflineRegionStatus.downloading;
      case PackageStatus.paused:
        return OfflineRegionStatus.paused;
      case PackageStatus.completed:
      case PackageStatus.partiallyComplete:
        return OfflineRegionStatus.completed;
      case PackageStatus.failed:
        return OfflineRegionStatus.failed;
    }
  }

  // ============ Copy ============

  /// Creates a copy with updated fields.
  OfflinePackage copyWith({
    String? id,
    String? name,
    OfflineBounds? bounds,
    double? minZoom,
    double? maxZoom,
    PackageStatus? status,
    Map<PackageContentType, PackageContent>? contents,
    int? totalSizeBytes,
    int? downloadedSizeBytes,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serverRegionId,
    String? styleUrl,
  }) {
    final newPackage = OfflinePackage(
      id: id ?? this.id,
      name: name ?? this.name,
      bounds: bounds ?? this.bounds,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      status: status ?? this.status,
      contents: contents ?? this.contents,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      downloadedSizeBytes: downloadedSizeBytes ?? this.downloadedSizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverRegionId: serverRegionId ?? this.serverRegionId,
      styleUrl: styleUrl ?? this.styleUrl,
    );

    NavigationLogger.debug(_logTag, 'Package updated', {
      'id': newPackage.id,
      'status': newPackage.status.name,
      'progress': newPackage.progressPercentage,
      'readyContent': newPackage.readyContentCount,
    });

    return newPackage;
  }

  /// Creates a copy with updated content for a specific type.
  OfflinePackage copyWithContent(
    PackageContentType type,
    PackageContent content,
  ) {
    final newContents = Map<PackageContentType, PackageContent>.from(contents);
    newContents[type] = content;

    // Recalculate downloaded size
    final newDownloaded =
        newContents.values.fold<int>(0, (sum, c) => sum + c.downloadedBytes);

    // Determine new status based on content statuses
    final newStatus = _calculateStatus(newContents);

    return copyWith(
      contents: newContents,
      downloadedSizeBytes: newDownloaded,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Calculates package status based on content statuses.
  PackageStatus _calculateStatus(Map<PackageContentType, PackageContent> contents) {
    if (contents.isEmpty) return PackageStatus.pending;

    final allReady = contents.values.every((c) => c.isReady);
    if (allReady) return PackageStatus.completed;

    final anyDownloading = contents.values.any((c) => c.isDownloading);
    if (anyDownloading) return PackageStatus.downloading;

    final anyFailed = contents.values.any((c) => c.status == ContentStatus.failed);
    final anyReady = contents.values.any((c) => c.isReady);

    if (anyFailed && anyReady) return PackageStatus.partiallyComplete;
    if (anyFailed) return PackageStatus.failed;

    return PackageStatus.pending;
  }

  @override
  String toString() =>
      'OfflinePackage(id: $id, name: $name, status: ${status.name}, '
      'progress: $progressPercentage, content: $readyContentCount/$totalContentCount, '
      'size: $totalSizeFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflinePackage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Parameters for creating a new offline package.
class CreatePackageParams {
  /// Human-readable name for the package.
  final String name;

  /// Geographic bounds to cover.
  final OfflineBounds bounds;

  /// Minimum zoom level for tiles (default: 0).
  final double minZoom;

  /// Maximum zoom level for tiles (default: 16).
  final double maxZoom;

  /// Content types to include in the package.
  final Set<PackageContentType> contentTypes;

  /// Map style URL (for tiles).
  final String? styleUrl;

  const CreatePackageParams({
    required this.name,
    required this.bounds,
    this.minZoom = 0,
    this.maxZoom = 16,
    required this.contentTypes,
    this.styleUrl,
  });

  /// Creates params with all content types.
  factory CreatePackageParams.full({
    required String name,
    required OfflineBounds bounds,
    double minZoom = 0,
    double maxZoom = 16,
    String? styleUrl,
  }) {
    return CreatePackageParams(
      name: name,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      contentTypes: PackageContentType.values.toSet(),
      styleUrl: styleUrl,
    );
  }

  /// Creates params with only tiles.
  factory CreatePackageParams.tilesOnly({
    required String name,
    required OfflineBounds bounds,
    double minZoom = 0,
    double maxZoom = 16,
    String? styleUrl,
  }) {
    return CreatePackageParams(
      name: name,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      contentTypes: {PackageContentType.tiles},
      styleUrl: styleUrl,
    );
  }

  /// Creates params with tiles and routing.
  factory CreatePackageParams.withRouting({
    required String name,
    required OfflineBounds bounds,
    double minZoom = 0,
    double maxZoom = 16,
    String? styleUrl,
  }) {
    return CreatePackageParams(
      name: name,
      bounds: bounds,
      minZoom: minZoom,
      maxZoom: maxZoom,
      contentTypes: {
        PackageContentType.tiles,
        PackageContentType.routing,
      },
      styleUrl: styleUrl,
    );
  }

  /// Validates the parameters.
  /// Throws [ArgumentError] if invalid.
  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Package name cannot be empty');
    }
    if (contentTypes.isEmpty) {
      throw ArgumentError('At least one content type must be specified');
    }
    if (minZoom < 0 || minZoom > 22) {
      throw ArgumentError('minZoom must be between 0 and 22');
    }
    if (maxZoom < 0 || maxZoom > 22) {
      throw ArgumentError('maxZoom must be between 0 and 22');
    }
    if (minZoom > maxZoom) {
      throw ArgumentError('minZoom cannot be greater than maxZoom');
    }
    if (bounds.southwest.lat > bounds.northeast.lat) {
      throw ArgumentError('Southwest latitude must be less than northeast');
    }
    if (bounds.southwest.lon > bounds.northeast.lon) {
      throw ArgumentError('Southwest longitude must be less than northeast');
    }
  }

  /// Estimates the number of tiles for this region.
  int estimateTileCount() {
    int totalTiles = 0;

    for (int zoom = minZoom.toInt(); zoom <= maxZoom.toInt(); zoom++) {
      final tilesPerSide = 1 << zoom;

      final minTileX = _lonToTileX(bounds.southwest.lon, zoom);
      final maxTileX = _lonToTileX(bounds.northeast.lon, zoom);
      final minTileY = _latToTileY(bounds.northeast.lat, zoom);
      final maxTileY = _latToTileY(bounds.southwest.lat, zoom);

      final tilesX = (maxTileX - minTileX + 1).clamp(1, tilesPerSide);
      final tilesY = (maxTileY - minTileY + 1).clamp(1, tilesPerSide);

      totalTiles += tilesX * tilesY;
    }

    return totalTiles;
  }

  /// Estimates total download size in bytes.
  ///
  /// Rough estimates:
  /// - Tiles: ~15KB per tile
  /// - Routing: ~5KB per km² for dense urban, ~1KB for rural
  /// - Geocoding: ~2KB per address (depends on density)
  int estimateDownloadSize() {
    int total = 0;

    if (contentTypes.contains(PackageContentType.tiles)) {
      total += estimateTileCount() * 15 * 1024; // 15KB per tile
    }

    // Calculate area in km²
    final areaKm2 = _calculateAreaKm2();

    if (contentTypes.contains(PackageContentType.routing)) {
      // Rough estimate: 3KB per km² average
      total += (areaKm2 * 3 * 1024).round();
    }

    if (contentTypes.contains(PackageContentType.geocoding)) {
      // Rough estimate: 5KB per km² average
      total += (areaKm2 * 5 * 1024).round();
    }

    if (contentTypes.contains(PackageContentType.reverseGeocoding)) {
      // Rough estimate: 2KB per km² average
      total += (areaKm2 * 2 * 1024).round();
    }

    return total;
  }

  /// Human-readable estimated size.
  String get estimatedSizeFormatted {
    final bytes = estimateDownloadSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Calculates approximate area in km².
  double _calculateAreaKm2() {
    const earthRadiusKm = 6371.0;

    final lat1 = bounds.southwest.lat * math.pi / 180;
    final lat2 = bounds.northeast.lat * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLon = (bounds.northeast.lon - bounds.southwest.lon) * math.pi / 180;

    // Approximate rectangle area
    final height = dLat * earthRadiusKm;
    final avgLat = (lat1 + lat2) / 2;
    final width = dLon * earthRadiusKm * math.cos(avgLat);

    return height.abs() * width.abs();
  }

  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    final n = 1 << zoom;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) /
            2.0 *
            n)
        .floor();
  }

  @override
  String toString() =>
      'CreatePackageParams(name: $name, bounds: $bounds, '
      'zoom: $minZoom-$maxZoom, types: ${contentTypes.map((t) => t.name).join(', ')}, '
      '~$estimatedSizeFormatted)';
}

/// Information about an available package on the server.
class AvailablePackage {
  /// Server region ID.
  final String id;

  /// Display name.
  final String name;

  /// Geographic bounds.
  final OfflineBounds bounds;

  /// Available content types.
  final Set<PackageContentType> availableContent;

  /// Estimated total size in bytes.
  final int estimatedSizeBytes;

  /// Data version.
  final String version;

  /// When the data was last updated on server.
  final DateTime? lastUpdated;

  const AvailablePackage({
    required this.id,
    required this.name,
    required this.bounds,
    required this.availableContent,
    required this.estimatedSizeBytes,
    required this.version,
    this.lastUpdated,
  });

  /// Human-readable estimated size.
  String get estimatedSizeFormatted {
    final bytes = estimatedSizeBytes;
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
      'AvailablePackage(id: $id, name: $name, '
      'content: ${availableContent.map((t) => t.name).join(', ')}, '
      'size: $estimatedSizeFormatted)';
}
