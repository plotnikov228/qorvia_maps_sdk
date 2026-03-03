import 'package:flutter/foundation.dart';
import '../../qorvia_maps_sdk.dart';
import '../client/http_client.dart';

/// Service for route calculation.
class RoutingService {
  final QorviaMapsHttpClient _client;
  final SdkConfig _config;

  RoutingService(this._client, this._config);

  /// Calculates a route between two points with optional waypoints.
  ///
  /// [from] - Starting point coordinates.
  /// [to] - Destination point coordinates.
  /// [waypoints] - Optional intermediate waypoints (max 20).
  /// [mode] - Transport mode (default: car).
  /// [alternatives] - Include alternative routes (default: false).
  /// [steps] - Include step-by-step instructions (default: true).
  /// [language] - Language for instructions: 'en', 'ru' (default: 'en').
  ///
  /// The route passes through waypoints in order:
  /// ```
  /// origin → waypoint[0] → waypoint[1] → ... → destination
  /// ```
  ///
  /// Returns [RouteResponse] with route details.
  /// Throws [QorviaMapsException] on error.
  /// Throws [ArgumentError] if waypoints exceed 20.
  ///
  /// Example:
  /// ```dart
  /// final route = await routingService.getRoute(
  ///   from: Coordinates(lat: 55.7558, lon: 37.6173),
  ///   to: Coordinates(lat: 55.7000, lon: 37.5000),
  ///   waypoints: [
  ///     Coordinates(lat: 55.7400, lon: 37.5800),
  ///     Coordinates(lat: 55.7200, lon: 37.5500),
  ///   ],
  /// );
  /// ```
  Future<RouteResponse> getRoute({
    required Coordinates from,
    required Coordinates to,
    List<Coordinates>? waypoints,
    TransportMode mode = TransportMode.car,
    bool alternatives = false,
    bool steps = true,
    String language = 'en',
  }) async {
    debugPrint('[RoutingService] getRoute START');
    debugPrint('[RoutingService] from: ${from.lat}, ${from.lon}');
    debugPrint('[RoutingService] to: ${to.lat}, ${to.lon}');
    debugPrint('[RoutingService] waypoints: ${waypoints?.length ?? 0}');
    debugPrint('[RoutingService] mode: ${mode.value}, steps: $steps, lang: $language');

    final request = RouteRequest(
      from: from,
      to: to,
      waypoints: waypoints,
      mode: mode,
      alternatives: alternatives,
      steps: steps,
      language: language,
    );

    debugPrint('[RoutingService] Request JSON: ${request.toJson()}');

    final data = await _client.post('/v1/mobile/route', data: request.toJson());

    debugPrint('[RoutingService] Response has steps: ${data['steps'] != null}');
    if (data['steps'] != null) {
      debugPrint('[RoutingService] Steps count: ${(data['steps'] as List).length}');
    }

    final response = RouteResponse.fromJson(data);
    debugPrint('[RoutingService] getRoute END - distance: ${response.distanceMeters}m');

    return _withDecodedPolyline(response);
  }

  /// Calculates a route using a request object.
  Future<RouteResponse> getRouteFromRequest(RouteRequest request) async {
    final data = await _client.post('/v1/mobile/route', data: request.toJson());

    final response = RouteResponse.fromJson(data);

    return _withDecodedPolyline(response);
  }

  RouteResponse _withDecodedPolyline(RouteResponse response) {
    final decodedPolyline = PolylineDecoder.decode(
      response.polyline,
      precision: _config.polylinePrecision,
    );

    if (!_config.routeSmoothingEnabled) {
      return response.withDecodedPolyline(decodedPolyline);
    }

    final smoothed = PolylineDecoder.smoothAdaptive(
      decodedPolyline,
      minAngleDegrees: _config.routeSmoothingMinAngleDegrees,
      smoothRadius: _config.routeSmoothingRadius,
      pointsPerCorner: _config.routeSmoothingPointsPerCorner,
    );

    return response.withDecodedPolyline(smoothed);
  }
}
