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
  ///
  /// Returns [GeocodeResponse] with list of results.
  /// Throws [QorviaMapsException] on error.
  Future<GeocodeResponse> geocode({
    required String query,
    int limit = 5,
    String language = 'en',
    List<String>? countryCodes,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'limit': limit,
      'language': language,
    };

    if (countryCodes != null && countryCodes.isNotEmpty) {
      queryParams['country_codes'] = countryCodes.join(',');
    }

    final data = await _client.get('/v1/mobile/geocode', queryParameters: queryParams);
    return GeocodeResponse.fromJson(data);
  }

  /// Searches for a single best match.
  ///
  /// Returns the first result or null if not found.
  Future<GeocodeResult?> search(
    String query, {
    String language = 'en',
    List<String>? countryCodes,
  }) async {
    final response = await geocode(
      query: query,
      limit: 1,
      language: language,
      countryCodes: countryCodes,
    );
    return response.firstResult;
  }
}
