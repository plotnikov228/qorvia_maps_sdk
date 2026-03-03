import 'package:equatable/equatable.dart';
import '../coordinates.dart';
import 'route_step.dart';
import '../../utils/polyline_decoder.dart';

/// Response from the routing API.
class RouteResponse extends Equatable {
  /// Request identifier for tracking.
  final String requestId;

  /// Total distance in meters.
  final int distanceMeters;

  /// Total duration in seconds.
  final int durationSeconds;

  /// Encoded polyline string (Google format).
  final String polyline;

  /// Decoded polyline as list of coordinates.
  final List<Coordinates>? decodedPolyline;

  /// Step-by-step navigation instructions.
  final List<RouteStep>? steps;

  /// Provider that served this request.
  final String provider;

  /// Units consumed by this request.
  final int units;

  const RouteResponse({
    required this.requestId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
    this.decodedPolyline,
    this.steps,
    required this.provider,
    required this.units,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      requestId: json['request_id'] as String,
      distanceMeters: json['distance_meters'] as int,
      durationSeconds: json['duration_seconds'] as int,
      polyline: json['polyline'] as String,
      steps: json['steps'] != null
          ? (json['steps'] as List)
              .map((e) => RouteStep.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      provider: json['provider'] as String,
      units: json['units'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'distance_meters': distanceMeters,
        'duration_seconds': durationSeconds,
        'polyline': polyline,
        if (steps != null) 'steps': steps!.map((e) => e.toJson()).toList(),
        'provider': provider,
        'units': units,
      };

  /// Returns a copy with decoded polyline.
  RouteResponse withDecodedPolyline(List<Coordinates> decoded) {
    return RouteResponse(
      requestId: requestId,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      polyline: polyline,
      decodedPolyline: decoded,
      steps: steps,
      provider: provider,
      units: units,
    );
  }

  /// Returns a copy with smoothed polyline.
  ///
  /// [iterations] - number of Chaikin smoothing passes (1-3 recommended).
  /// [tension] - controls smoothing intensity (0.0-0.5, default 0.25).
  RouteResponse withSmoothedPolyline({
    int iterations = 2,
    double tension = 0.25,
  }) {
    final decoded = decodedPolyline ?? PolylineDecoder.decode(polyline);
    final smoothed = PolylineDecoder.smooth(
      decoded,
      iterations: iterations,
      tension: tension,
    );
    return withDecodedPolyline(smoothed);
  }

  /// Returns a copy with adaptively smoothed polyline.
  ///
  /// Only smooths corners where turn angle exceeds [minAngleDegrees].
  /// [smoothRadius] - curve radius in meters at corners.
  RouteResponse withAdaptiveSmoothing({
    double minAngleDegrees = 30,
    double smoothRadius = 15,
    int pointsPerCorner = 5,
  }) {
    final decoded = decodedPolyline ?? PolylineDecoder.decode(polyline);
    final smoothed = PolylineDecoder.smoothAdaptive(
      decoded,
      minAngleDegrees: minAngleDegrees,
      smoothRadius: smoothRadius,
      pointsPerCorner: pointsPerCorner,
    );
    return withDecodedPolyline(smoothed);
  }

  /// Formatted distance string (e.g., "2.4 km" or "450 m").
  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} км';
    }
    return '$distanceMeters м';
  }

  /// Formatted duration string (e.g., "15 мин" or "1 ч 30 мин").
  String get formattedDuration {
    if (durationSeconds >= 3600) {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      return '$hours ч $minutes мин';
    }
    return '${durationSeconds ~/ 60} мин';
  }

  @override
  List<Object?> get props => [
        requestId,
        distanceMeters,
        durationSeconds,
        polyline,
        steps,
        provider,
        units,
      ];
}
