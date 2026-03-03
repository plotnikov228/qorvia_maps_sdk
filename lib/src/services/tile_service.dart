import 'package:flutter/foundation.dart';
import '../client/http_client.dart';
import '../models/tile/tile_url_response.dart';

/// Service for fetching map tile style URL.
///
/// This service retrieves the map style URL from the server based on
/// the API key and bundle ID configuration.
class TileService {
  final QorviaMapsHttpClient _client;

  TileService(this._client);

  /// Gets the map tile style URL from the server.
  ///
  /// Returns [TileUrlResponse] containing the style URL.
  /// Throws [QorviaMapsException] on error.
  ///
  /// Example:
  /// ```dart
  /// final response = await tileService.getTileUrl();
  /// print('Style URL: ${response.tileUrl}');
  /// ```
  Future<TileUrlResponse> getTileUrl() async {
    debugPrint('[TileService.getTileUrl] Fetching tile URL from server');

    try {
      final data = await _client.get('/v1/mobile/tile-url');

      debugPrint('[TileService.getTileUrl] Response received: $data');

      final response = TileUrlResponse.fromJson(data);

      debugPrint('[TileService.getTileUrl] Parsed successfully: ${response.tileUrl}');

      return response;
    } catch (error, stackTrace) {
      debugPrint('[TileService.getTileUrl] ERROR: $error');
      debugPrint('[TileService.getTileUrl] Stack: $stackTrace');
      rethrow;
    }
  }
}
