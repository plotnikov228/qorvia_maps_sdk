import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Geographic coordinates (latitude and longitude).
class Coordinates extends Equatable {
  /// Latitude in degrees (-90 to 90).
  final double lat;

  /// Longitude in degrees (-180 to 180).
  final double lon;

  /// Creates coordinates with validation.
  const Coordinates({
    required this.lat,
    required this.lon,
  })  : assert(lat >= -90 && lat <= 90, 'Latitude must be between -90 and 90'),
        assert(lon >= -180 && lon <= 180, 'Longitude must be between -180 and 180');

  /// Creates coordinates from a map with 'lat' and 'lon' keys.
  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  /// Converts coordinates to JSON map.
  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
      };

  /// Calculates approximate distance to another point in meters.
  /// Uses Haversine formula.
  double distanceTo(Coordinates other) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(other.lat - lat);
    final double dLon = _toRadians(other.lon - lon);

    final double a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(lat)) *
            math.cos(_toRadians(other.lat)) *
            math.pow(math.sin(dLon / 2), 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculates bearing to another point in degrees (0-360).
  double bearingTo(Coordinates other) {
    final double dLon = _toRadians(other.lon - lon);
    final double lat1Rad = _toRadians(lat);
    final double lat2Rad = _toRadians(other.lat);

    final double x = math.sin(dLon) * math.cos(lat2Rad);
    final double y = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final double bearing = math.atan2(x, y);
    return (_toDegrees(bearing) + 360) % 360;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;

  @override
  List<Object?> get props => [lat, lon];

  @override
  String toString() => 'Coordinates($lat, $lon)';
}
