import 'package:equatable/equatable.dart';
import 'geocode_result.dart';

/// Response from the geocoding API.
class GeocodeResponse extends Equatable {
  /// Request identifier for tracking.
  final String requestId;

  /// List of geocoding results.
  final List<GeocodeResult> results;

  /// Provider that served this request.
  final String provider;

  /// Units consumed by this request.
  final int units;

  const GeocodeResponse({
    required this.requestId,
    required this.results,
    required this.provider,
    required this.units,
  });

  factory GeocodeResponse.fromJson(Map<String, dynamic> json) {
    return GeocodeResponse(
      requestId: json['request_id'] as String,
      results: (json['results'] as List)
          .map((e) => GeocodeResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      provider: json['provider'] as String,
      units: json['units'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'results': results.map((e) => e.toJson()).toList(),
        'provider': provider,
        'units': units,
      };

  /// Returns the first result or null if empty.
  GeocodeResult? get firstResult => results.isNotEmpty ? results.first : null;

  /// Returns true if no results were found.
  bool get isEmpty => results.isEmpty;

  /// Returns true if results were found.
  bool get isNotEmpty => results.isNotEmpty;

  @override
  List<Object?> get props => [requestId, results, provider, units];
}
