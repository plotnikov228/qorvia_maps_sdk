import 'package:equatable/equatable.dart';
import '../coordinates.dart';
import 'address.dart';

/// A single geocoding result.
class GeocodeResult extends Equatable {
  /// Coordinates of the found location.
  final Coordinates coordinates;

  /// Full display name of the location.
  final String displayName;

  /// Structured address components.
  final Address address;

  /// Type of place (e.g., "place", "address", "poi").
  final String placeType;

  /// Relevance score (0-1).
  final double importance;

  /// Bounding box [minLon, minLat, maxLon, maxLat].
  final List<double>? bbox;

  const GeocodeResult({
    required this.coordinates,
    required this.displayName,
    required this.address,
    required this.placeType,
    required this.importance,
    this.bbox,
  });

  factory GeocodeResult.fromJson(Map<String, dynamic> json) {
    return GeocodeResult(
      coordinates: Coordinates(
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      ),
      displayName: json['display_name'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      placeType: json['place_type'] as String,
      importance: (json['importance'] as num).toDouble(),
      bbox: json['bbox'] != null
          ? (json['bbox'] as List).map((e) => (e as num).toDouble()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': coordinates.lat,
        'lon': coordinates.lon,
        'display_name': displayName,
        'address': address.toJson(),
        'place_type': placeType,
        'importance': importance,
        if (bbox != null) 'bbox': bbox,
      };

  @override
  List<Object?> get props => [
        coordinates,
        displayName,
        address,
        placeType,
        importance,
        bbox,
      ];
}
