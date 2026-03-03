import '../models/coordinates.dart';

/// Data from location updates.
class LocationData {
  /// Current coordinates.
  final Coordinates coordinates;

  /// Altitude in meters (null if unavailable).
  final double? altitude;

  /// Heading/bearing in degrees (0-360, null if unavailable).
  final double? heading;

  /// Speed in meters per second (null if unavailable).
  final double? speed;

  /// Accuracy of the location in meters.
  final double accuracy;

  /// Timestamp of this location fix.
  final DateTime timestamp;

  const LocationData({
    required this.coordinates,
    this.altitude,
    this.heading,
    this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  /// Returns true if heading is available and reliable.
  bool get hasHeading => heading != null && speed != null && speed! > 1.0;

  /// Returns speed in km/h.
  double? get speedKmh => speed != null ? speed! * 3.6 : null;

  /// Returns formatted speed string.
  String get formattedSpeed {
    final kmh = speedKmh;
    if (kmh == null) return '--';
    return '${kmh.round()} км/ч';
  }

  LocationData copyWith({
    Coordinates? coordinates,
    double? altitude,
    double? heading,
    double? speed,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationData(
      coordinates: coordinates ?? this.coordinates,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'LocationData(${coordinates.lat}, ${coordinates.lon}, heading: $heading, speed: $speed)';
}
