import '../../offline/tiles/offline_region.dart';

/// Represents a predefined tile region available on the server.
///
/// These are preset geographic regions that users can download
/// for offline use without needing to specify custom bounds.
class TileRegion {
  /// Unique identifier for this region on the server.
  final String id;

  /// Human-readable name for the region.
  final String name;

  /// Optional description of the region.
  final String? description;

  /// Geographic bounds of the region.
  final OfflineBounds bounds;

  /// Minimum zoom level available for this region.
  final int minZoom;

  /// Maximum zoom level available for this region.
  final int maxZoom;

  /// Estimated size of the region in megabytes.
  final double sizeMb;

  /// Estimated number of tiles in the region.
  final int tilesCount;

  const TileRegion({
    required this.id,
    required this.name,
    this.description,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.sizeMb,
    required this.tilesCount,
  });

  /// Creates a TileRegion from JSON data.
  /// Supports both server format (bbox) and internal format (bounds).
  factory TileRegion.fromJson(Map<String, dynamic> json) {
    // Handle server format with bbox (east/north/south/west)
    final bboxJson = json['bbox'] as Map<String, dynamic>?;
    final boundsJson = json['bounds'] as Map<String, dynamic>?;

    late final OfflineBounds bounds;
    if (bboxJson != null) {
      // Server format: bbox with east/north/south/west
      bounds = OfflineBounds.fromCoordinates(
        swLat: (bboxJson['south'] as num).toDouble(),
        swLon: (bboxJson['west'] as num).toDouble(),
        neLat: (bboxJson['north'] as num).toDouble(),
        neLon: (bboxJson['east'] as num).toDouble(),
      );
    } else if (boundsJson != null) {
      // Internal format: bounds with sw_lat/sw_lon/ne_lat/ne_lon
      bounds = OfflineBounds.fromCoordinates(
        swLat: (boundsJson['sw_lat'] as num).toDouble(),
        swLon: (boundsJson['sw_lon'] as num).toDouble(),
        neLat: (boundsJson['ne_lat'] as num).toDouble(),
        neLon: (boundsJson['ne_lon'] as num).toDouble(),
      );
    } else {
      throw ArgumentError('TileRegion.fromJson: missing bbox or bounds');
    }

    return TileRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      bounds: bounds,
      minZoom: json['min_zoom'] as int? ?? 0,
      maxZoom: json['max_zoom'] as int? ?? 16,
      sizeMb: (json['estimated_size_mb'] as num? ?? json['size_mb'] as num).toDouble(),
      tilesCount: json['tiles_count'] as int,
    );
  }

  /// Converts this region to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'bounds': {
          'sw_lat': bounds.southwest.lat,
          'sw_lon': bounds.southwest.lon,
          'ne_lat': bounds.northeast.lat,
          'ne_lon': bounds.northeast.lon,
        },
        'min_zoom': minZoom,
        'max_zoom': maxZoom,
        'size_mb': sizeMb,
        'tiles_count': tilesCount,
      };

  /// Human-readable size string.
  String get sizeFormatted {
    if (sizeMb < 1) return '${(sizeMb * 1024).toStringAsFixed(0)} KB';
    if (sizeMb < 1024) return '${sizeMb.toStringAsFixed(1)} MB';
    return '${(sizeMb / 1024).toStringAsFixed(2)} GB';
  }

  @override
  String toString() =>
      'TileRegion(id: $id, name: $name, zoom: $minZoom-$maxZoom, size: $sizeFormatted)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileRegion && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
