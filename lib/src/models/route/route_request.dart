import 'package:flutter/foundation.dart';

import '../coordinates.dart';
import '../../config/transport_mode.dart';

/// Maximum number of waypoints allowed per route request.
const int kMaxWaypoints = 20;

/// Request parameters for route calculation.
class RouteRequest {
  /// Starting point coordinates.
  final Coordinates from;

  /// Destination point coordinates.
  final Coordinates to;

  /// Optional intermediate waypoints (max 20).
  ///
  /// The route will pass through these points in order:
  /// origin → waypoint[0] → waypoint[1] → ... → destination
  final List<Coordinates>? waypoints;

  /// Transport mode.
  final TransportMode mode;

  /// Whether to include alternative routes.
  final bool alternatives;

  /// Whether to include step-by-step instructions.
  final bool steps;

  /// Language for instructions ('en', 'ru').
  final String language;

  /// Creates a route request.
  ///
  /// Throws [ArgumentError] if waypoints exceed [kMaxWaypoints].
  RouteRequest({
    required this.from,
    required this.to,
    this.waypoints,
    this.mode = TransportMode.car,
    this.alternatives = false,
    this.steps = true,
    this.language = 'en',
  }) {
    if (waypoints != null && waypoints!.length > kMaxWaypoints) {
      debugPrint('[RouteRequest] ERROR: waypoints count ${waypoints!.length} exceeds max $kMaxWaypoints');
      throw ArgumentError('Maximum $kMaxWaypoints waypoints allowed, got ${waypoints!.length}');
    }
    if (waypoints != null) {
      debugPrint('[RouteRequest] Created with ${waypoints!.length} waypoints');
    }
  }

  Map<String, dynamic> toJson() => {
        'from': from.toJson(),
        'to': to.toJson(),
        if (waypoints != null && waypoints!.isNotEmpty)
          'waypoints': waypoints!.map((c) => c.toJson()).toList(),
        'mode': mode.value,
        'alternatives': alternatives,
        'steps': steps,
        'language': language,
      };
}
