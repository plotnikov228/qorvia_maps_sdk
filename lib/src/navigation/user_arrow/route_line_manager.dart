import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/coordinates.dart';
import '../navigation_logger.dart';
import '../navigation_options.dart';

/// Source and layer IDs for route line.
const _kRouteSourceId = 'nav-route-line-source';
const _kRouteLayerId = 'nav-route-line-layer';
const _kRouteCasingLayerId = 'nav-route-casing-layer';
const _kTraveledSourceId = 'nav-traveled-source';
const _kTraveledLayerId = 'nav-traveled-layer';

/// Draws and manages route polyline on the map.
///
/// Features:
/// - Draws full route polyline with casing (outline)
/// - Culls already-traveled portion (dims or hides it)
/// - Throttled updates for performance
class RouteLineManager {
  MaplibreMapController? _mapController;
  final NavigationOptions options;

  bool _layerAdded = false;
  List<Coordinates>? _polyline;
  int _currentSegmentIndex = 0;
  DateTime? _lastUpdate;
  DateTime? _lastSnapUpdate;
  static const _throttleMs = 100; // Route line updates at 10fps max
  static const _snapThrottleMs = 32; // Route snap updates at ~30fps

  RouteLineManager({required this.options});

  /// Attaches the MapLibre controller.
  Future<void> attach(MaplibreMapController controller) async {
    _mapController = controller;
    NavigationLogger.info('RouteLineManager', 'Attached');
  }

  /// Detaches from the map controller.
  void detach() {
    _mapController = null;
    _layerAdded = false;
  }

  /// Draws the route polyline on the map.
  ///
  /// [belowLayerId] if provided, all route layers are inserted below
  /// this layer in the MapLibre rendering stack. Use this to keep the
  /// user arrow cursor above the route and traveled lines.
  Future<void> drawRoute(
    List<Coordinates> polyline, {
    String? belowLayerId,
  }) async {
    if (_mapController == null) return;
    _polyline = polyline;

    try {
      // Remove existing layers if any
      await _removeLayers();

      // Add route casing (outline) — wider, darker
      await _mapController!.addGeoJsonSource(
        _kRouteSourceId,
        _buildRouteGeoJson(polyline),
      );

      await _mapController!.addLineLayer(
        _kRouteSourceId,
        _kRouteCasingLayerId,
        LineLayerProperties(
          lineColor: '#4338CA', // darker indigo for casing
          lineWidth: options.routeLineWidth + 2,
          lineOpacity: options.routeLineOpacity * 0.6,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        belowLayerId: belowLayerId,
      );

      // Add route fill — narrower, brighter
      await _mapController!.addLineLayer(
        _kRouteSourceId,
        _kRouteLayerId,
        LineLayerProperties(
          lineColor:
              '#${options.routeLineColor.value.toRadixString(16).substring(2)}',
          lineWidth: options.routeLineWidth,
          lineOpacity: options.routeLineOpacity,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        belowLayerId: belowLayerId,
      );

      // Add traveled overlay (dimmed portion)
      await _mapController!.addGeoJsonSource(
        _kTraveledSourceId,
        _buildRouteGeoJson([]),
      );

      await _mapController!.addLineLayer(
        _kTraveledSourceId,
        _kTraveledLayerId,
        LineLayerProperties(
          lineColor: '#9CA3AF', // gray for traveled
          lineWidth: options.routeLineWidth,
          lineOpacity: 0.5,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        belowLayerId: belowLayerId,
      );

      _layerAdded = true;
      NavigationLogger.info('RouteLineManager', 'Route drawn', {
        'points': polyline.length,
        'belowLayer': belowLayerId ?? 'none',
      });
    } catch (e) {
      NavigationLogger.error('RouteLineManager', 'Draw route failed', e);
    }
  }

  /// Updates the traveled portion of the route.
  ///
  /// [segmentIndex] the index of the segment the user is currently on.
  /// [snappedPosition] the user's snapped position on the route.
  Future<void> updateTraveledPortion(
    int segmentIndex,
    Coordinates snappedPosition,
  ) async {
    if (_mapController == null || !_layerAdded || _polyline == null) return;

    // Throttle
    final now = DateTime.now();
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!).inMilliseconds < _throttleMs) {
      return;
    }
    _lastUpdate = now;

    _currentSegmentIndex = segmentIndex;

    try {
      // Traveled portion: from start to current position
      final traveled = <Coordinates>[];
      for (int i = 0; i <= segmentIndex && i < _polyline!.length; i++) {
        traveled.add(_polyline![i]);
      }
      traveled.add(snappedPosition);

      await _mapController!.setGeoJsonSource(
        _kTraveledSourceId,
        _buildRouteGeoJson(traveled),
      );

      // Update remaining route (from snapped position to end)
      final remaining = <Coordinates>[snappedPosition];
      for (int i = segmentIndex + 1; i < _polyline!.length; i++) {
        remaining.add(_polyline![i]);
      }

      await _mapController!.setGeoJsonSource(
        _kRouteSourceId,
        _buildRouteGeoJson(remaining),
      );
    } catch (e) {
      NavigationLogger.error(
          'RouteLineManager', 'Update traveled failed', e);
    }
  }

  /// Snaps both the remaining route start and traveled route end
  /// to the animated cursor position.
  ///
  /// Called at animation frame rate (~60fps) to keep the route
  /// visually attached to the cursor.
  ///
  /// [segmentIndex] - real-time segment index from RouteCursorEngine.
  /// If provided, updates internal state for accurate route splitting.
  Future<void> snapRouteStartToCursor(
    Coordinates cursorPosition, {
    int? segmentIndex,
  }) async {
    if (_mapController == null || !_layerAdded || _polyline == null) return;

    // Throttle to ~30fps for route line (visual updates)
    final now = DateTime.now();
    if (_lastSnapUpdate != null &&
        now.difference(_lastSnapUpdate!).inMilliseconds < _snapThrottleMs) {
      return;
    }
    _lastSnapUpdate = now;

    // Use provided segment index (from RouteCursorEngine) or fall back to cached
    final actualSegmentIndex = segmentIndex ?? _currentSegmentIndex;

    // Update cached segment index if new value provided
    if (segmentIndex != null && segmentIndex != _currentSegmentIndex) {
      // Log significant segment jumps for debugging
      final jump = (segmentIndex - _currentSegmentIndex).abs();
      if (jump > 1) {
        NavigationLogger.debug('RouteLineManager', 'Segment jump', {
          'from': _currentSegmentIndex,
          'to': segmentIndex,
          'jump': jump,
        });
      }
      _currentSegmentIndex = segmentIndex;
    }

    try {
      // Remaining route: from cursor to end
      final remaining = <Coordinates>[cursorPosition];
      for (int i = actualSegmentIndex + 1; i < _polyline!.length; i++) {
        remaining.add(_polyline![i]);
      }

      // Traveled portion: from start to cursor
      final traveled = <Coordinates>[];
      for (int i = 0; i <= actualSegmentIndex && i < _polyline!.length; i++) {
        traveled.add(_polyline![i]);
      }
      traveled.add(cursorPosition);

      await _mapController!.setGeoJsonSource(
        _kRouteSourceId,
        _buildRouteGeoJson(remaining),
      );
      await _mapController!.setGeoJsonSource(
        _kTraveledSourceId,
        _buildRouteGeoJson(traveled),
      );
    } catch (e) {
      // Silently ignore snap errors — non-critical visual update
    }
  }

  /// Removes all route layers from map.
  Future<void> removeRoute() async {
    await _removeLayers();
    _polyline = null;
    _currentSegmentIndex = 0;
    NavigationLogger.info('RouteLineManager', 'Route removed');
  }

  /// Resets state.
  void reset() {
    _currentSegmentIndex = 0;
    _lastUpdate = null;
    _lastSnapUpdate = null;
  }

  /// Disposes resources.
  void dispose() {
    _mapController = null;
    _layerAdded = false;
    _polyline = null;
  }

  // --- Private ---

  Future<void> _removeLayers() async {
    if (_mapController == null) return;

    try {
      if (_layerAdded) {
        await _mapController!.removeLayer(_kTraveledLayerId);
        await _mapController!.removeSource(_kTraveledSourceId);
        await _mapController!.removeLayer(_kRouteLayerId);
        await _mapController!.removeLayer(_kRouteCasingLayerId);
        await _mapController!.removeSource(_kRouteSourceId);
        _layerAdded = false;
      }
    } catch (e) {
      // Layers may already be removed
      NavigationLogger.debug('RouteLineManager', 'Remove layers (ignored)', {
        'error': e.toString(),
      });
    }
  }

  Map<String, dynamic> _buildRouteGeoJson(List<Coordinates> points) {
    return {
      'type': 'FeatureCollection',
      'features': [
        if (points.length >= 2)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates':
                  points.map((p) => [p.lon, p.lat]).toList(),
            },
            'properties': <String, dynamic>{},
          },
      ],
    };
  }
}
