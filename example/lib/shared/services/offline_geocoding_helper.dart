import 'dart:developer' as developer;

import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

/// Helper for geocoding operations.
/// Currently uses online geocoding only.
class GeocodingHelper {
  GeocodingHelper._();

  /// Reverse geocodes coordinates to address.
  /// Returns response or null if failed.
  static Future<ReverseResponse?> reverse({
    required Coordinates coordinates,
    String? language,
  }) async {
    // Check connectivity
    if (!QorviaMapsSDK.isOnline) {
      _log('No internet connection for reverse geocoding');
      return null;
    }

    try {
      final client = QorviaMapsSDK.instance.client;
      final response = await client.reverse(
        coordinates: coordinates,
        language: language ?? 'ru',
      );
      _log('Reverse geocode', {'displayName': response.displayName});
      return response;
    } catch (e) {
      _log('Reverse geocode failed', {'error': e.toString()});
      return null;
    }
  }

  /// Forward geocodes a query to coordinates.
  static Future<GeocodeResponse?> geocode({
    required String query,
    int limit = 5,
    double? userLat,
    double? userLon,
    String? language,
  }) async {
    // Check connectivity
    if (!QorviaMapsSDK.isOnline) {
      _log('No internet connection for geocoding');
      return null;
    }

    try {
      final client = QorviaMapsSDK.instance.client;
      final response = await client.geocode(
        query: query,
        limit: limit,
        userLat: userLat,
        userLon: userLon,
        language: language ?? 'ru',
      );
      _log('Geocode', {'query': query, 'results': response.results.length});
      return response;
    } catch (e) {
      _log('Geocode failed', {'error': e.toString()});
      return null;
    }
  }

  static void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[GeocodingHelper] $message$dataStr');
  }
}

/// @Deprecated('Offline geocoding not yet available. Use GeocodingHelper instead.')
typedef OfflineGeocodingHelper = GeocodingHelper;
