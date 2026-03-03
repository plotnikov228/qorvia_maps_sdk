import '../client/http_client.dart';
import '../models/coordinates.dart';
import '../models/reverse/reverse_response.dart';

/// Service for reverse geocoding (coordinates to address).
class ReverseService {
  final QorviaMapsHttpClient _client;

  ReverseService(this._client);

  /// Converts coordinates to an address.
  ///
  /// [coordinates] - Location coordinates.
  /// [language] - Language for results (default: 'en').
  ///
  /// Returns [ReverseResponse] with address details.
  /// Throws [QorviaMapsException] on error.
  Future<ReverseResponse> reverse({
    required Coordinates coordinates,
    String language = 'en',
  }) async {
    final data = await _client.get('/v1/mobile/reverse', queryParameters: {
      'lat': coordinates.lat,
      'lon': coordinates.lon,
      'language': language,
    });
    return ReverseResponse.fromJson(data);
  }

  /// Converts latitude and longitude to an address.
  Future<ReverseResponse> reverseLatLon({
    required double lat,
    required double lon,
    String language = 'en',
  }) async {
    return reverse(
      coordinates: Coordinates(lat: lat, lon: lon),
      language: language,
    );
  }
}
