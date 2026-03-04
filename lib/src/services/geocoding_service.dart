import 'package:flutter/foundation.dart';

import '../client/http_client.dart';
import '../models/geocode/geocode_response.dart';
import '../models/geocode/geocode_result.dart';

/// Service for forward geocoding (address to coordinates).
class GeocodingService {
  final QorviaMapsHttpClient _client;

  GeocodingService(this._client);

  /// Converts an address to coordinates.
  ///
  /// [query] - Search query (1-500 characters).
  /// [limit] - Maximum number of results (1-20, default: 5).
  /// [language] - Language for results (default: 'en').
  /// [countryCodes] - Filter by country codes (e.g., ['ru', 'kz']).
  /// [userLat] - User's latitude for location-biased results.
  /// [userLon] - User's longitude for location-biased results.
  /// [radiusKm] - Search radius in kilometers (default: 50).
  /// [biasLocation] - Whether to prioritize results near user location.
  ///
  /// Returns [GeocodeResponse] with list of results.
  /// Throws [QorviaMapsException] on error.
  Future<GeocodeResponse> geocode({
    required String query,
    int limit = 5,
    String language = 'en',
    List<String>? countryCodes,
    double? userLat,
    double? userLon,
    double? radiusKm,
    bool? biasLocation,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'limit': limit,
      'language': language,
    };

    if (countryCodes != null && countryCodes.isNotEmpty) {
      queryParams['country_codes'] = countryCodes.join(',');
    }

    // Add user location parameters for location-biased search
    if (userLat != null && userLon != null) {
      queryParams['user_lat'] = userLat;
      queryParams['user_lon'] = userLon;

      if (radiusKm != null) {
        queryParams['radius_km'] = radiusKm;
      }

      if (biasLocation != null) {
        queryParams['bias_location'] = biasLocation;
      }

      debugPrint(
        '[GeocodingService.geocode] searching with location bias: '
        'lat=$userLat, lon=$userLon, radius=${radiusKm ?? "default"}, bias=${biasLocation ?? "default"}',
      );
    } else {
      debugPrint('[GeocodingService.geocode] searching without location bias');
    }

    final data = await _client.get('/v1/mobile/geocode', queryParameters: queryParams);
    return GeocodeResponse.fromJson(data);
  }

  /// Searches for a single best match.
  ///
  /// [userLat], [userLon], [radiusKm], [biasLocation] - location bias params.
  ///
  /// Returns the first result or null if not found.
  Future<GeocodeResult?> search(
    String query, {
    String language = 'en',
    List<String>? countryCodes,
    double? userLat,
    double? userLon,
    double? radiusKm,
    bool? biasLocation,
  }) async {
    final response = await geocode(
      query: query,
      limit: 1,
      language: language,
      countryCodes: countryCodes,
      userLat: userLat,
      userLon: userLon,
      radiusKm: radiusKm,
      biasLocation: biasLocation,
    );
    return response.firstResult;
  }
}
