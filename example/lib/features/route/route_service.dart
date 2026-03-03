import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../search/models/selected_point.dart';
import '../search/models/travel_mode.dart';

/// Service for managing route requests and route line display.
class RouteService {
  final QorviaMapsClient _client;

  RouteService(this._client);

  /// Requests a route between two points with optional waypoints.
  /// [includeSteps] should be true for navigation, false for preview.
  Future<RouteResponse?> requestRoute({
    required SelectedPoint from,
    required SelectedPoint to,
    required TravelMode mode,
    List<SelectedPoint>? waypoints,
    bool includeSteps = false,
  }) async {
    _log('Requesting route', {
      'from': from.label,
      'to': to.label,
      'mode': mode.name,
      'waypoints': waypoints?.length ?? 0,
      'includeSteps': includeSteps,
    });

    try {
      final waypointCoords = waypoints
          ?.where((wp) => wp.isSet)
          .map((wp) => wp.coordinates)
          .toList();

      final route = await _client.route(
        from: from.coordinates,
        to: to.coordinates,
        waypoints: waypointCoords,
        mode: mode.transportMode,
        steps: includeSteps,
        language: 'ru',
      );

      _log('Route received', {
        'distance': route.distanceMeters,
        'duration': route.durationSeconds,
        'stepsCount': route.steps?.length ?? 0,
      });

      return route;
    } catch (error) {
      _log('Route request failed', {'error': error.toString()});
      rethrow;
    }
  }

  /// Creates a RouteLine from a RouteResponse for map display.
  RouteLine createRouteLine(
    RouteResponse route, {
    String id = 'preview',
    Color color = Colors.indigoAccent,
    bool showArrows = true,
  }) {
    return RouteLine.fromCoordinates(
      id,
      route.decodedPolyline ?? const [],
      options: RouteLineOptions.primary().copyWith(
        showArrows: showArrows,
        color: color,
      ),
    );
  }

  /// Creates markers for route start and end points.
  List<Marker> createRouteMarkers(RouteResponse route) {
    final markers = <Marker>[];
    final polyline = route.decodedPolyline;

    if (polyline != null && polyline.isNotEmpty) {
      markers.add(
        Marker(
          id: 'route_start',
          position: polyline.first,
          icon: NumberedMarkerIcon.letter('A', textColor: Colors.indigoAccent)
        ),
      );
      markers.add(
        Marker(
          id: 'route_end',
          position: polyline.last,
          icon: NumberedMarkerIcon.letter('B', textColor: Colors.indigoAccent),
        ),
      );
    }

    return markers;
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[RouteService] $message$dataStr');
  }
}
