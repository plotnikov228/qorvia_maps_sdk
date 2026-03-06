import 'package:flutter/foundation.dart';

import '../client/http_client.dart';
import '../models/smart_search/smart_search_response.dart';

/// Service for AI-powered smart search.
///
/// Automatically classifies queries and routes to appropriate providers.
/// Available only on paid plans with `smart_search` permission.
class SmartSearchService {
  final QorviaMapsHttpClient _client;

  SmartSearchService(this._client);

  /// Performs AI-powered natural language search.
  ///
  /// [query] - Natural language search query (2-500 characters).
  /// [lat] - User latitude (-90 to 90).
  /// [lon] - User longitude (-180 to 180).
  /// [radiusKm] - Search radius in kilometers (1-50, default: 10).
  /// [limit] - Maximum number of results (1-20, default: 5).
  /// [language] - Response language: 'ru' or 'en' (default: 'ru').
  ///
  /// Returns [SmartSearchResponse] with classified results.
  /// Throws [QorviaMapsException] on error.
  Future<SmartSearchResponse> smartSearch({
    required String query,
    required double lat,
    required double lon,
    int? radiusKm,
    int? limit,
    String? language,
  }) async {
    debugPrint(
      '[SmartSearchService.smartSearch] START query="$query", '
      'lat=$lat, lon=$lon, radiusKm=${radiusKm ?? "default"}, '
      'limit=${limit ?? "default"}, language=${language ?? "default"}',
    );

    final requestBody = <String, dynamic>{
      'query': query,
      'lat': lat,
      'lon': lon,
    };

    if (radiusKm != null) {
      requestBody['radius_km'] = radiusKm;
    }
    if (limit != null) {
      requestBody['limit'] = limit;
    }
    if (language != null) {
      requestBody['language'] = language;
    }

    final data = await _client.post('/v1/mobile/smart-search', data: requestBody);
    final response = SmartSearchResponse.fromJson(data);

    debugPrint(
      '[SmartSearchService.smartSearch] DONE classifiedAs=${response.classifiedAs}, '
      'resultsCount=${response.results.length}, units=${response.units}',
    );

    return response;
  }
}
