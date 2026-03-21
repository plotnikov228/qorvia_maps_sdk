import 'package:flutter/foundation.dart';

/// Response from tile URL API endpoint.
///
/// When `autoTheme: true` (default), response contains only `tile_url`:
/// ```json
/// {
///   "request_id": "fa5a84f7-ba63-4535-9fe0-4f964c5a03c1",
///   "status": "ok",
///   "tile_url": "https://tile.../yandex/style.json"
/// }
/// ```
///
/// When `autoTheme: false`, response contains both day and night URLs:
/// ```json
/// {
///   "request_id": "fa5a84f7-ba63-4535-9fe0-4f964c5a03c1",
///   "status": "ok",
///   "tile_url": "https://tile.../yandex/style.json",
///   "night_tile_url": "https://tile.../yandex-dark/style.json",
///   "is_night_mode": false,
///   "is_style_json": false
/// }
/// ```
///
/// Note: `night_tile_url` may be `null` if night theme is unavailable.
class TileUrlResponse {
  /// Unique request identifier for debugging.
  final String? requestId;

  /// Response status ("ok" on success).
  final String status;

  /// Map style URL for MapLibre (day theme when autoTheme=false).
  final String tileUrl;

  /// Night map style URL for MapLibre.
  ///
  /// Only available when `autoTheme: false`.
  /// May be `null` if night theme is unavailable for this configuration.
  final String? nightTileUrl;

  /// Server's recommendation for whether to use night mode.
  ///
  /// Based on user's location and time. Only available when `autoTheme: false`.
  final bool? isNightMode;

  /// Whether the tile_url points to a style.json file.
  ///
  /// Only available when `autoTheme: false`.
  final bool? isStyleJson;

  const TileUrlResponse({
    this.requestId,
    required this.status,
    required this.tileUrl,
    this.nightTileUrl,
    this.isNightMode,
    this.isStyleJson,
  });

  factory TileUrlResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('[TileUrlResponse.fromJson] Parsing response: $json');

    final tileUrl = json['tile_url'] as String?;
    if (tileUrl == null || tileUrl.isEmpty) {
      debugPrint('[TileUrlResponse.fromJson] ERROR: tile_url is null or empty');
      throw FormatException('tile_url is required in response');
    }

    final nightTileUrl = json['night_tile_url'] as String?;
    final isNightMode = json['is_night_mode'] as bool?;
    final isStyleJson = json['is_style_json'] as bool?;

    debugPrint('[TileUrlResponse.fromJson] Parsed: '
        'tileUrl=$tileUrl, '
        'nightTileUrl=${nightTileUrl ?? "null"}, '
        'isNightMode=${isNightMode ?? "null"}, '
        'isStyleJson=${isStyleJson ?? "null"}');

    return TileUrlResponse(
      requestId: json['request_id'] as String?,
      status: json['status'] as String? ?? 'unknown',
      tileUrl: tileUrl,
      nightTileUrl: nightTileUrl,
      isNightMode: isNightMode,
      isStyleJson: isStyleJson,
    );
  }

  Map<String, dynamic> toJson() => {
        if (requestId != null) 'request_id': requestId,
        'status': status,
        'tile_url': tileUrl,
        if (nightTileUrl != null) 'night_tile_url': nightTileUrl,
        if (isNightMode != null) 'is_night_mode': isNightMode,
        if (isStyleJson != null) 'is_style_json': isStyleJson,
      };

  /// Whether night theme is available.
  bool get hasNightTheme => nightTileUrl != null && nightTileUrl!.isNotEmpty;

  @override
  String toString() => 'TileUrlResponse('
      'requestId: $requestId, '
      'status: $status, '
      'tileUrl: $tileUrl, '
      'nightTileUrl: $nightTileUrl, '
      'isNightMode: $isNightMode, '
      'isStyleJson: $isStyleJson)';
}
