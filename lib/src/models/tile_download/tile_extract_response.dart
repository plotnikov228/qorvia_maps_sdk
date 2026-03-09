/// Response from the tile extract API endpoint.
///
/// Contains information about the extracted mbtiles file
/// that is ready for download.
class TileExtractResponse {
  /// Status of the extract request.
  final String status;

  /// URL to download the mbtiles file.
  final String downloadUrl;

  /// Filename of the mbtiles file.
  final String filename;

  /// Size of the file in megabytes.
  final double sizeMb;

  /// Number of tiles in the file.
  final int tilesCount;

  const TileExtractResponse({
    required this.status,
    required this.downloadUrl,
    required this.filename,
    required this.sizeMb,
    required this.tilesCount,
  });

  /// Creates a TileExtractResponse from JSON data.
  factory TileExtractResponse.fromJson(Map<String, dynamic> json) {
    return TileExtractResponse(
      status: json['status'] as String,
      downloadUrl: json['download_url'] as String,
      filename: json['filename'] as String,
      sizeMb: (json['size_mb'] as num).toDouble(),
      tilesCount: json['tiles_count'] as int,
    );
  }

  /// Converts this response to JSON.
  Map<String, dynamic> toJson() => {
        'status': status,
        'download_url': downloadUrl,
        'filename': filename,
        'size_mb': sizeMb,
        'tiles_count': tilesCount,
      };

  /// Size in bytes.
  int get sizeBytes => (sizeMb * 1024 * 1024).round();

  /// Human-readable size string.
  String get sizeFormatted {
    if (sizeMb < 1) return '${(sizeMb * 1024).toStringAsFixed(0)} KB';
    if (sizeMb < 1024) return '${sizeMb.toStringAsFixed(1)} MB';
    return '${(sizeMb / 1024).toStringAsFixed(2)} GB';
  }

  @override
  String toString() =>
      'TileExtractResponse(status: $status, file: $filename, size: $sizeFormatted, tiles: $tilesCount)';
}
