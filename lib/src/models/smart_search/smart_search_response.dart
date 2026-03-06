import 'package:equatable/equatable.dart';

import 'smart_search_result.dart';

/// Response from the smart search API.
///
/// Contains AI-classified search results with automatic routing
/// to address or place providers.
class SmartSearchResponse extends Equatable {
  /// Request identifier for tracking.
  final String requestId;

  /// Provider used for the search (e.g., "google_places", "nominatim").
  final String provider;

  /// Query type: 'place' or 'address'.
  final String queryType;

  /// List of search results.
  final List<SmartSearchResult> results;

  const SmartSearchResponse({
    required this.requestId,
    required this.provider,
    required this.queryType,
    required this.results,
  });

  /// Classification of the query (alias for queryType, uppercase).
  String get classifiedAs => queryType.toUpperCase();

  /// Units consumed by this request (deprecated, always returns 1).
  int get units => 1;

  factory SmartSearchResponse.fromJson(Map<String, dynamic> json) {
    return SmartSearchResponse(
      requestId: json['request_id'] as String,
      provider: json['provider'] as String,
      queryType: json['query_type'] as String,
      results: (json['results'] as List)
          .map((e) => SmartSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'provider': provider,
        'query_type': queryType,
        'results': results.map((e) => e.toJson()).toList(),
      };

  /// Returns the first result or null if empty.
  SmartSearchResult? get firstResult =>
      results.isNotEmpty ? results.first : null;

  /// Returns true if no results were found.
  bool get isEmpty => results.isEmpty;

  /// Returns true if results were found.
  bool get isNotEmpty => results.isNotEmpty;

  /// Returns true if the query was classified as an address search.
  bool get isAddressSearch => classifiedAs == 'ADDRESS';

  /// Returns true if the query was classified as a place search.
  bool get isPlaceSearch => classifiedAs == 'PLACE';

  @override
  List<Object?> get props => [requestId, provider, queryType, results];
}
