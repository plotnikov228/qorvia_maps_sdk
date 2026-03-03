import 'package:equatable/equatable.dart';
import '../coordinates.dart';
import '../geocode/address.dart';

/// Response from the reverse geocoding API.
class ReverseResponse extends Equatable {
  /// Request identifier for tracking.
  final String requestId;

  /// Coordinates that were queried.
  final Coordinates coordinates;

  /// Full display name of the location.
  final String displayName;

  /// Structured address components.
  final Address address;

  /// Provider that served this request.
  final String provider;

  /// Units consumed by this request.
  final int units;

  const ReverseResponse({
    required this.requestId,
    required this.coordinates,
    required this.displayName,
    required this.address,
    required this.provider,
    required this.units,
  });

  factory ReverseResponse.fromJson(Map<String, dynamic> json) {
    return ReverseResponse(
      requestId: json['request_id'] as String,
      coordinates: Coordinates(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      ),
      displayName: json['display_name'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      provider: json['provider'] as String,
      units: json['units'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'lat': coordinates.lat,
        'lon': coordinates.lon,
        'display_name': displayName,
        'address': address.toJson(),
        'provider': provider,
        'units': units,
      };

  @override
  List<Object?> get props => [
        requestId,
        coordinates,
        displayName,
        address,
        provider,
        units,
      ];
}
