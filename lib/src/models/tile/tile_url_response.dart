import 'package:flutter/foundation.dart';

/// Response from tile URL API endpoint.
///
/// Example response:
/// ```json
/// {
///   "request_id": "fa5a84f7-ba63-4535-9fe0-4f964c5a03c1",
///   "status": "ok",
///   "tile_url": "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json"
/// }
/// ```
class TileUrlResponse {
  /// Unique request identifier for debugging.
  final String? requestId;

  /// Response status ("ok" on success).
  final String status;

  /// Map style URL for MapLibre.
  final String tileUrl;

  const TileUrlResponse({
    this.requestId,
    required this.status,
    required this.tileUrl,
  });

  factory TileUrlResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('[TileUrlResponse.fromJson] Parsing response: $json');

    final tileUrl = json['tile_url'] as String?;
    if (tileUrl == null || tileUrl.isEmpty) {
      debugPrint('[TileUrlResponse.fromJson] ERROR: tile_url is null or empty');
      throw FormatException('tile_url is required in response');
    }

    return TileUrlResponse(
      requestId: json['request_id'] as String?,
      status: json['status'] as String? ?? 'unknown',
      tileUrl: tileUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        if (requestId != null) 'request_id': requestId,
        'status': status,
        'tile_url': tileUrl,
      };

  @override
  String toString() =>
      'TileUrlResponse(requestId: $requestId, status: $status, tileUrl: $tileUrl)';
}
