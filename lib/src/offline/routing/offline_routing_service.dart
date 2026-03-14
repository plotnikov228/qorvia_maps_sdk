import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../config/transport_mode.dart';
import '../../models/coordinates.dart';
import '../../models/route/route_response.dart';
import '../../models/route/route_step.dart';
import '../../utils/polyline_decoder.dart';

/// Service for offline route calculation using native routing engines.
///
/// **Note:** Offline routing data is not yet available from the server.
/// This service is planned for future releases. Currently, routing works online only.
///
/// Uses:
/// - Android: GraphHopper Java SDK
/// - iOS: Custom A* algorithm implementation
///
/// The service manages routing graphs that must be loaded before calculating routes.
/// Graphs are typically downloaded using [RoutingDataService] and stored as .ghz files.
///
/// Example:
/// ```dart
/// final routingService = OfflineRoutingService();
///
/// // Load a graph for a region
/// await routingService.loadGraph('moscow', '/path/to/moscow.ghz');
///
/// // Check if graph is ready
/// if (routingService.isGraphLoaded('moscow')) {
///   // Calculate route
///   final route = await routingService.getRoute(
///     regionId: 'moscow',
///     from: Coordinates(lat: 55.7558, lon: 37.6173),
///     to: Coordinates(lat: 55.7000, lon: 37.5000),
///   );
///   print('Route: ${route.distanceMeters}m, ${route.durationSeconds}s');
/// }
///
/// // Unload when done
/// routingService.unloadGraph('moscow');
/// ```
@Deprecated('Offline routing data not yet available. Use online routing instead.')
class OfflineRoutingService {
  /// Method channel for communicating with native routing engines.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'ru.qorviamapkit.maps_sdk/offline_routing',
  );

  /// UUID generator for request IDs.
  final Uuid _uuid = const Uuid();

  /// Logger callback.
  final void Function(String message)? _logger;

  /// Cached set of loaded graph IDs for quick checks.
  final Set<String> _loadedGraphIds = {};

  /// Creates an OfflineRoutingService.
  ///
  /// [logger] - Optional callback for debug logging.
  OfflineRoutingService({
    void Function(String message)? logger,
  }) : _logger = logger;

  void _log(String message) {
    _logger?.call('[OfflineRoutingService] $message');
    debugPrint('[OfflineRoutingService] $message');
  }

  // MARK: - Graph Management

  /// Loads a routing graph from a .ghz file.
  ///
  /// [regionId] - Unique identifier for this graph (used in route requests).
  /// [graphPath] - Absolute path to the .ghz file.
  ///
  /// Throws [OfflineRoutingException] on failure.
  ///
  /// Note: Loading a large graph can take several seconds.
  /// Consider showing a loading indicator.
  Future<void> loadGraph(String regionId, String graphPath) async {
    _log('Loading graph: $regionId from $graphPath');

    try {
      final result = await channel.invokeMethod<Map<Object?, Object?>>(
        'loadGraph',
        {
          'regionId': regionId,
          'graphPath': graphPath,
        },
      );

      if (result != null && result['success'] == true) {
        _loadedGraphIds.add(regionId);
        _log('Graph loaded successfully: $regionId');
      } else {
        throw OfflineRoutingException(
          'Failed to load graph: ${result?['error'] ?? 'Unknown error'}',
        );
      }
    } on PlatformException catch (e) {
      _log('Platform error loading graph: ${e.message}');
      throw OfflineRoutingException('Failed to load graph: ${e.message}');
    }
  }

  /// Unloads a routing graph, freeing memory.
  ///
  /// [regionId] - The region ID used when loading the graph.
  Future<void> unloadGraph(String regionId) async {
    _log('Unloading graph: $regionId');

    try {
      await channel.invokeMethod<void>(
        'unloadGraph',
        {'regionId': regionId},
      );
      _loadedGraphIds.remove(regionId);
      _log('Graph unloaded: $regionId');
    } on PlatformException catch (e) {
      _log('Error unloading graph: ${e.message}');
      // Don't throw - unload should be best-effort
    }
  }

  /// Checks if a graph is currently loaded.
  ///
  /// [regionId] - The region ID to check.
  ///
  /// Returns true if the graph is loaded and ready for routing.
  bool isGraphLoaded(String regionId) {
    return _loadedGraphIds.contains(regionId);
  }

  /// Checks if a graph is loaded by querying the native side.
  ///
  /// Use this for a definitive answer (slower than [isGraphLoaded]).
  Future<bool> isGraphLoadedNative(String regionId) async {
    try {
      final result = await channel.invokeMethod<bool>(
        'isGraphLoaded',
        {'regionId': regionId},
      );
      final isLoaded = result ?? false;

      // Sync local cache
      if (isLoaded) {
        _loadedGraphIds.add(regionId);
      } else {
        _loadedGraphIds.remove(regionId);
      }

      return isLoaded;
    } on PlatformException {
      return false;
    }
  }

  /// Gets the list of currently loaded graph region IDs.
  Future<List<String>> getLoadedGraphs() async {
    try {
      final result = await channel.invokeMethod<List<Object?>>(
        'getLoadedGraphs',
      );
      final graphs = result?.cast<String>() ?? [];
      _loadedGraphIds
        ..clear()
        ..addAll(graphs);
      return graphs;
    } on PlatformException {
      return [];
    }
  }

  /// Gets information about a loaded graph.
  ///
  /// Returns null if the graph is not loaded.
  Future<OfflineGraphInfo?> getGraphInfo(String regionId) async {
    try {
      final result = await channel.invokeMethod<Map<Object?, Object?>>(
        'getGraphInfo',
        {'regionId': regionId},
      );

      if (result == null) return null;

      return OfflineGraphInfo.fromMap(result);
    } on PlatformException {
      return null;
    }
  }

  // MARK: - Route Calculation

  /// Calculates an offline route between two points.
  ///
  /// [regionId] - The loaded graph region to use.
  /// [from] - Starting point coordinates.
  /// [to] - Destination coordinates.
  /// [waypoints] - Optional intermediate waypoints.
  /// [mode] - Transport mode (car, bike, foot).
  ///
  /// Returns a [RouteResponse] compatible with the online routing API.
  ///
  /// Throws [OfflineRoutingException] on failure.
  Future<RouteResponse> getRoute({
    required String regionId,
    required Coordinates from,
    required Coordinates to,
    List<Coordinates>? waypoints,
    TransportMode mode = TransportMode.car,
  }) async {
    if (!isGraphLoaded(regionId)) {
      throw OfflineRoutingException('Graph not loaded: $regionId');
    }

    _log('Calculating route: $from -> $to (mode: ${mode.value})');

    try {
      final waypointsJson = waypoints
          ?.map((c) => {'lat': c.lat, 'lon': c.lon})
          .toList();

      final result = await channel.invokeMethod<Map<Object?, Object?>>(
        'calculateRoute',
        {
          'regionId': regionId,
          'fromLat': from.lat,
          'fromLon': from.lon,
          'toLat': to.lat,
          'toLon': to.lon,
          'profile': _modeToProfile(mode),
          'waypoints': waypointsJson,
        },
      );

      if (result == null) {
        throw OfflineRoutingException('No result from routing engine');
      }

      if (result['success'] != true) {
        throw OfflineRoutingException(
          result['error']?.toString() ?? 'Route calculation failed',
        );
      }

      return _parseRouteResult(result);
    } on PlatformException catch (e) {
      _log('Route calculation error: ${e.message}');
      throw OfflineRoutingException('Route calculation failed: ${e.message}');
    }
  }

  /// Converts TransportMode to native profile string.
  String _modeToProfile(TransportMode mode) {
    switch (mode) {
      case TransportMode.car:
        return 'car';
      case TransportMode.truck:
        return 'car'; // Truck uses car profile in GraphHopper
      case TransportMode.bike:
        return 'bike';
      case TransportMode.foot:
        return 'foot';
    }
  }

  /// Parses the native route result into a RouteResponse.
  RouteResponse _parseRouteResult(Map<Object?, Object?> result) {
    // Extract route data
    final distanceMeters = (result['distance'] as num?)?.toDouble() ?? 0.0;
    final timeMillis = (result['time'] as num?)?.toDouble() ?? 0.0;
    final pointsRaw = result['points'] as List<Object?>? ?? [];
    final instructionsRaw = result['instructions'] as List<Object?>? ?? [];
    final bbox = result['bbox'] as List<Object?>?;

    // Parse points into coordinates
    final points = <Coordinates>[];
    for (final point in pointsRaw) {
      if (point is List && point.length >= 2) {
        points.add(Coordinates(
          lat: (point[0] as num).toDouble(),
          lon: (point[1] as num).toDouble(),
        ));
      }
    }

    // Encode as polyline
    final polyline = PolylineDecoder.encode(points);

    // Parse instructions into steps
    final steps = _parseInstructions(instructionsRaw);

    return RouteResponse(
      requestId: _uuid.v4(),
      distanceMeters: distanceMeters.round(),
      durationSeconds: (timeMillis / 1000).round(),
      polyline: polyline,
      decodedPolyline: points,
      steps: steps.isNotEmpty ? steps : null,
      provider: 'offline',
      units: 0, // Offline routes don't consume API units
    );
  }

  /// Parses native instructions into RouteStep objects.
  List<RouteStep> _parseInstructions(List<Object?> instructionsRaw) {
    final steps = <RouteStep>[];

    for (final instruction in instructionsRaw) {
      if (instruction is Map) {
        final text = instruction['text']?.toString() ?? '';
        final distance = (instruction['distance'] as num?)?.toDouble() ?? 0.0;
        final time = (instruction['time'] as num?)?.toDouble() ?? 0.0;
        final sign = instruction['sign'] as int? ?? 0;
        final streetName = instruction['streetName']?.toString();

        steps.add(RouteStep(
          instruction: text,
          distanceMeters: distance.round(),
          durationSeconds: (time / 1000).round(),
          maneuver: _signToManeuver(sign),
          name: streetName,
        ));
      }
    }

    return steps;
  }

  /// Converts GraphHopper sign to maneuver string.
  String _signToManeuver(int sign) {
    // GraphHopper sign values:
    // -3: sharp left, -2: left, -1: slight left, 0: straight
    // 1: slight right, 2: right, 3: sharp right
    // 4: finish, 5: reached via, 6: use roundabout
    switch (sign) {
      case -3:
        return Maneuvers.turnSharpLeft;
      case -2:
        return Maneuvers.turnLeft;
      case -1:
        return Maneuvers.turnSlightLeft;
      case 0:
        return Maneuvers.straight;
      case 1:
        return Maneuvers.turnSlightRight;
      case 2:
        return Maneuvers.turnRight;
      case 3:
        return Maneuvers.turnSharpRight;
      case 4:
        return Maneuvers.arrive;
      case 5:
        return Maneuvers.arrive; // Reached waypoint
      case 6:
        return Maneuvers.roundabout;
      default:
        if (sign < 0) return Maneuvers.turnLeft;
        if (sign > 0) return Maneuvers.turnRight;
        return Maneuvers.straight;
    }
  }

  /// Disposes resources.
  ///
  /// Unloads all loaded graphs.
  Future<void> dispose() async {
    _log('Disposing OfflineRoutingService');

    // Unload all graphs
    final graphIds = List<String>.from(_loadedGraphIds);
    for (final regionId in graphIds) {
      await unloadGraph(regionId);
    }

    _loadedGraphIds.clear();
  }
}

/// Information about a loaded routing graph.
class OfflineGraphInfo {
  /// Region identifier.
  final String regionId;

  /// Supported routing profiles.
  final List<String> profiles;

  /// Number of nodes in the graph.
  final int nodeCount;

  /// Number of edges in the graph.
  final int edgeCount;

  /// Geographic bounds of the graph.
  final OfflineGraphBounds bounds;

  const OfflineGraphInfo({
    required this.regionId,
    required this.profiles,
    required this.nodeCount,
    required this.edgeCount,
    required this.bounds,
  });

  factory OfflineGraphInfo.fromMap(Map<Object?, Object?> map) {
    final boundsMap = map['bounds'] as Map<Object?, Object?>?;

    return OfflineGraphInfo(
      regionId: map['regionId']?.toString() ?? '',
      profiles: (map['profiles'] as List<Object?>?)?.cast<String>() ?? [],
      nodeCount: map['nodeCount'] as int? ?? 0,
      edgeCount: map['edgeCount'] as int? ?? 0,
      bounds: boundsMap != null
          ? OfflineGraphBounds.fromMap(boundsMap)
          : const OfflineGraphBounds(
              minLat: 0,
              minLon: 0,
              maxLat: 0,
              maxLon: 0,
            ),
    );
  }

  @override
  String toString() {
    return 'OfflineGraphInfo(regionId: $regionId, nodes: $nodeCount, edges: $edgeCount)';
  }
}

/// Geographic bounds of a routing graph.
class OfflineGraphBounds {
  final double minLat;
  final double minLon;
  final double maxLat;
  final double maxLon;

  const OfflineGraphBounds({
    required this.minLat,
    required this.minLon,
    required this.maxLat,
    required this.maxLon,
  });

  factory OfflineGraphBounds.fromMap(Map<Object?, Object?> map) {
    return OfflineGraphBounds(
      minLat: (map['minLat'] as num?)?.toDouble() ?? 0.0,
      minLon: (map['minLon'] as num?)?.toDouble() ?? 0.0,
      maxLat: (map['maxLat'] as num?)?.toDouble() ?? 0.0,
      maxLon: (map['maxLon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Checks if a coordinate is within these bounds.
  bool contains(Coordinates coord) {
    return coord.lat >= minLat &&
        coord.lat <= maxLat &&
        coord.lon >= minLon &&
        coord.lon <= maxLon;
  }

  @override
  String toString() {
    return 'OfflineGraphBounds($minLat, $minLon - $maxLat, $maxLon)';
  }
}

/// Exception thrown by offline routing operations.
class OfflineRoutingException implements Exception {
  final String message;

  const OfflineRoutingException(this.message);

  @override
  String toString() => 'OfflineRoutingException: $message';
}
