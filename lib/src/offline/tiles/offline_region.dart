import 'dart:math' as math;

import '../../models/coordinates.dart';

/// Status of an offline map region.
enum OfflineRegionStatus {
  /// Region is created but download hasn't started.
  pending,

  /// Region tiles are being downloaded.
  downloading,

  /// Download is paused by user.
  paused,

  /// All tiles have been downloaded successfully.
  completed,

  /// Download failed with an error.
  failed,
}

/// Extension for parsing status from string.
extension OfflineRegionStatusX on OfflineRegionStatus {
  /// Converts status to string for storage.
  String toStorageString() => name;

  /// Parses status from storage string.
  static OfflineRegionStatus fromString(String value) {
    return OfflineRegionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OfflineRegionStatus.pending,
    );
  }
}

/// Represents geographic bounds for an offline region.
class OfflineBounds {
  /// Southwest corner of the bounds.
  final Coordinates southwest;

  /// Northeast corner of the bounds.
  final Coordinates northeast;

  const OfflineBounds({
    required this.southwest,
    required this.northeast,
  });

  /// Creates bounds from individual coordinates.
  factory OfflineBounds.fromCoordinates({
    required double swLat,
    required double swLon,
    required double neLat,
    required double neLon,
  }) {
    return OfflineBounds(
      southwest: Coordinates(lat: swLat, lon: swLon),
      northeast: Coordinates(lat: neLat, lon: neLon),
    );
  }

  /// Returns the center of the bounds.
  Coordinates get center => Coordinates(
        lat: (southwest.lat + northeast.lat) / 2,
        lon: (southwest.lon + northeast.lon) / 2,
      );

  @override
  String toString() =>
      'OfflineBounds(sw: $southwest, ne: $northeast)';
}

/// Represents an offline map region with its metadata and download status.
class OfflineRegion {
  /// Unique identifier for this region.
  final String id;

  /// Human-readable name for the region.
  final String name;

  /// Geographic bounds of the region.
  final OfflineBounds bounds;

  /// Minimum zoom level to download.
  final double minZoom;

  /// Maximum zoom level to download.
  final double maxZoom;

  /// Map style URL used for this region.
  final String styleUrl;

  /// Current download status.
  final OfflineRegionStatus status;

  /// Number of tiles downloaded so far.
  final int downloadedTiles;

  /// Total number of tiles to download.
  final int totalTiles;

  /// Size of downloaded data in bytes.
  final int sizeBytes;

  /// Error message if status is [OfflineRegionStatus.failed].
  final String? errorMessage;

  /// When the region was created.
  final DateTime createdAt;

  /// When the region was last updated.
  final DateTime updatedAt;

  /// MapLibre internal region ID (for native operations).
  /// This is set after the region is created in MapLibre.
  final int? maplibreRegionId;

  /// Path to the downloaded .mbtiles file.
  final String? filePath;

  /// ID of the region on the server (for preset regions).
  final String? serverRegionId;

  /// Type of region: 'custom' or 'preset'.
  final String regionType;

  const OfflineRegion({
    required this.id,
    required this.name,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.styleUrl,
    required this.status,
    required this.downloadedTiles,
    required this.totalTiles,
    required this.sizeBytes,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.maplibreRegionId,
    this.filePath,
    this.serverRegionId,
    this.regionType = 'custom',
  });

  /// Whether this is a preset region from the server.
  bool get isPreset => regionType == 'preset';

  /// Whether this is a custom region created by the user.
  bool get isCustom => regionType == 'custom';

  /// Download progress as a percentage (0.0 to 1.0).
  double get progress {
    if (totalTiles == 0) return 0.0;
    return downloadedTiles / totalTiles;
  }

  /// Download progress as a percentage string.
  String get progressPercentage => '${(progress * 100).toStringAsFixed(1)}%';

  /// Whether the region is fully downloaded.
  bool get isComplete => status == OfflineRegionStatus.completed;

  /// Whether the region is currently downloading.
  bool get isDownloading => status == OfflineRegionStatus.downloading;

  /// Whether the download can be started or resumed.
  bool get canDownload =>
      status == OfflineRegionStatus.pending ||
      status == OfflineRegionStatus.paused ||
      status == OfflineRegionStatus.failed;

  /// Human-readable size string.
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Creates a copy with updated fields.
  OfflineRegion copyWith({
    String? id,
    String? name,
    OfflineBounds? bounds,
    double? minZoom,
    double? maxZoom,
    String? styleUrl,
    OfflineRegionStatus? status,
    int? downloadedTiles,
    int? totalTiles,
    int? sizeBytes,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maplibreRegionId,
    String? filePath,
    String? serverRegionId,
    String? regionType,
  }) {
    return OfflineRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      bounds: bounds ?? this.bounds,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      styleUrl: styleUrl ?? this.styleUrl,
      status: status ?? this.status,
      downloadedTiles: downloadedTiles ?? this.downloadedTiles,
      totalTiles: totalTiles ?? this.totalTiles,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maplibreRegionId: maplibreRegionId ?? this.maplibreRegionId,
      filePath: filePath ?? this.filePath,
      serverRegionId: serverRegionId ?? this.serverRegionId,
      regionType: regionType ?? this.regionType,
    );
  }

  @override
  String toString() =>
      'OfflineRegion(id: $id, name: $name, status: $status, '
      'progress: $progressPercentage, size: $sizeFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineRegion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Parameters for creating a new offline region.
class CreateOfflineRegionParams {
  /// Human-readable name for the region.
  final String name;

  /// Geographic bounds to download.
  final OfflineBounds bounds;

  /// Minimum zoom level (default: 0).
  final double minZoom;

  /// Maximum zoom level (default: 16).
  final double maxZoom;

  /// Map style URL. If null, uses the current map style.
  final String? styleUrl;

  const CreateOfflineRegionParams({
    required this.name,
    required this.bounds,
    this.minZoom = 0,
    this.maxZoom = 16,
    this.styleUrl,
  });

  /// Validates the parameters.
  /// Throws [ArgumentError] if invalid.
  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Region name cannot be empty');
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

  /// Estimates the number of tiles that will be downloaded.
  ///
  /// This is an approximation based on the bounds and zoom levels.
  /// Actual tile count may vary depending on the map style and data.
  int estimateTileCount() {
    int totalTiles = 0;

    for (int zoom = minZoom.toInt(); zoom <= maxZoom.toInt(); zoom++) {
      final tilesPerSide = 1 << zoom; // 2^zoom

      // Convert lat/lon to tile coordinates
      final minTileX = _lonToTileX(bounds.southwest.lon, zoom);
      final maxTileX = _lonToTileX(bounds.northeast.lon, zoom);
      final minTileY = _latToTileY(bounds.northeast.lat, zoom); // Note: Y is inverted
      final maxTileY = _latToTileY(bounds.southwest.lat, zoom);

      final tilesX = (maxTileX - minTileX + 1).clamp(1, tilesPerSide);
      final tilesY = (maxTileY - minTileY + 1).clamp(1, tilesPerSide);

      totalTiles += tilesX * tilesY;
    }

    return totalTiles;
  }

  /// Estimates the download size in bytes.
  ///
  /// Assumes an average tile size of 15KB (typical for vector tiles).
  /// Returns estimated size in bytes.
  int estimateDownloadSize() {
    const averageTileSizeBytes = 15 * 1024; // 15KB average for vector tiles
    return estimateTileCount() * averageTileSizeBytes;
  }

  /// Returns a human-readable estimated download size.
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

  /// Converts longitude to tile X coordinate.
  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  /// Converts latitude to tile Y coordinate.
  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    final n = 1 << zoom;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
  }

  /// Creates a recommended configuration with a maximum tile limit.
  ///
  /// Automatically adjusts maxZoom if the estimated tile count exceeds the limit.
  /// Default limit is 6000 tiles (MapLibre's default).
  CreateOfflineRegionParams withTileLimit([int maxTiles = 6000]) {
    var adjustedMaxZoom = maxZoom;

    while (adjustedMaxZoom > minZoom) {
      final params = CreateOfflineRegionParams(
        name: name,
        bounds: bounds,
        minZoom: minZoom,
        maxZoom: adjustedMaxZoom,
        styleUrl: styleUrl,
      );

      if (params.estimateTileCount() <= maxTiles) {
        return params;
      }

      adjustedMaxZoom -= 1;
    }

    return this; // Return original if can't reduce further
  }

  @override
  String toString() =>
      'CreateOfflineRegionParams(name: $name, bounds: $bounds, '
      'zoom: $minZoom-$maxZoom, ~${estimateTileCount()} tiles)';
}
