/// Response from the tile estimate API endpoint.
///
/// Contains information about the estimated size and tile count
/// for a given region and zoom level range.
class TileEstimateResponse {
  /// Status of the estimate request.
  final String status;

  /// Estimated size of the region in megabytes.
  final double sizeMb;

  /// Estimated number of tiles.
  final int tilesCount;

  const TileEstimateResponse({
    required this.status,
    required this.sizeMb,
    required this.tilesCount,
  });

  /// Creates a TileEstimateResponse from JSON data.
  factory TileEstimateResponse.fromJson(Map<String, dynamic> json) {
    return TileEstimateResponse(
      status: json['status'] as String,
      sizeMb: (json['size_mb'] as num).toDouble(),
      tilesCount: json['tiles_count'] as int,
    );
  }

  /// Converts this response to JSON.
  Map<String, dynamic> toJson() => {
        'status': status,
        'size_mb': sizeMb,
        'tiles_count': tilesCount,
      };

  /// Estimated size in bytes.
  int get sizeBytes => (sizeMb * 1024 * 1024).round();

  /// Human-readable size string.
  String get sizeFormatted {
    if (sizeMb < 1) return '${(sizeMb * 1024).toStringAsFixed(0)} KB';
    if (sizeMb < 1024) return '${sizeMb.toStringAsFixed(1)} MB';
    return '${(sizeMb / 1024).toStringAsFixed(2)} GB';
  }

  @override
  String toString() =>
      'TileEstimateResponse(status: $status, size: $sizeFormatted, tiles: $tilesCount)';
}
