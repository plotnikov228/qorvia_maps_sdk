import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../location/location_data.dart';
import '../location/location_service.dart';
import '../models/coordinates.dart';
import '../markers/marker.dart' as sdk;
import '../markers/cluster/marker_cluster.dart';
import '../navigation/ui/widget_builders.dart';
import '../navigation/ui/widget_data.dart';
import '../offline/connectivity/connectivity_service.dart';
import '../offline/connectivity/network_status.dart';
import '../route_display/route_line.dart';
import '../sdk_initializer.dart';
import 'qorvia_map_controller.dart';
import 'map_options.dart';
import 'camera/camera_position.dart' as sdk_camera;
import 'ui/map_compass.dart';
import 'ui/map_scale_bar.dart';
import 'ui/user_location_button.dart';
import 'ui/widget_builders.dart';
import 'ui/zoom_controls.dart';
import 'user_location_layer.dart';

/// Callback for when the map is created and ready.
typedef OnMapCreated = void Function(QorviaMapController controller);

/// Callback for marker tap events.
typedef OnMarkerTap = void Function(sdk.Marker marker);

/// Callback for cluster tap events.
typedef OnClusterTap = void Function(MarkerCluster cluster);

/// Callback for map tap events.
typedef OnMapTap = void Function(Coordinates coordinates);

/// Callback for camera movement events.
typedef OnCameraMove = void Function(sdk_camera.CameraPosition position);

/// Callback for offline mode state changes.
typedef OnOfflineModeChanged = void Function(bool isOffline);

/// Main map widget for displaying and interacting with the map.
///
/// Example:
/// ```dart
/// QorviaMapView(
///   controller: _mapController,
///   options: MapOptions(
///     initialCenter: Coordinates(lat: 55.7539, lon: 37.6208),
///     initialZoom: 12,
///   ),
///   markers: [
///     Marker(
///       id: 'start',
///       position: Coordinates(lat: 55.7539, lon: 37.6208),
///       icon: DefaultMarkerIcon.start,
///     ),
///   ],
///   onMapTap: (coordinates) => print('Tapped at $coordinates'),
/// )
/// ```
class QorviaMapView extends StatefulWidget {
  /// Controller for managing the map.
  final QorviaMapController? controller;

  /// Map configuration options.
  final MapOptions options;

  /// Markers to display on the map.
  final List<sdk.Marker> markers;

  /// Options for marker clustering.
  final MarkerClusterOptions? clusterOptions;

  /// Route lines to display on the map.
  final List<RouteLine> routeLines;

  /// Called when the map is created and ready.
  final OnMapCreated? onMapCreated;

  /// Called when a marker is tapped.
  final OnMarkerTap? onMarkerTap;

  /// Called when a marker cluster is tapped.
  final OnClusterTap? onClusterTap;

  /// Called when the map is tapped (not on a marker).
  final OnMapTap? onMapTap;

  /// Called when the map is long-pressed.
  final OnMapTap? onMapLongPress;

  /// Called when the camera starts moving.
  final OnCameraMove? onCameraMoveStarted;

  /// Called while the camera is moving.
  final OnCameraMove? onCameraMove;

  /// Called when the camera stops moving.
  final OnCameraMove? onCameraIdle;

  /// Whether to automatically load the tile URL from SDK if not specified.
  ///
  /// When true (default), if [MapOptions.styleUrl] is null and [QorviaMapsSDK]
  /// is initialized, the map will automatically use the tile URL from the SDK.
  final bool autoLoadStyle;

  /// Whether to automatically refresh the style when connectivity changes.
  ///
  /// When true (default), the map will attempt to switch from offline to
  /// online style when network becomes available, and vice versa.
  final bool autoRefreshOnConnectivity;

  /// Called when the map switches between online and offline mode.
  final OnOfflineModeChanged? onOfflineModeChanged;

  /// Enable verbose logging for debugging.
  final bool enableLogging;

  const QorviaMapView({
    super.key,
    this.controller,
    required this.options,
    this.markers = const [],
    this.clusterOptions,
    this.routeLines = const [],
    this.onMapCreated,
    this.onMarkerTap,
    this.onClusterTap,
    this.onMapTap,
    this.onMapLongPress,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.autoLoadStyle = true,
    this.autoRefreshOnConnectivity = true,
    this.onOfflineModeChanged,
    this.enableLogging = false,
  });

  @override
  State<QorviaMapView> createState() => _QorviaMapViewState();
}

class _QorviaMapViewState extends State<QorviaMapView> {
  late QorviaMapController _controller;
  MaplibreMapController? _maplibreController;
  final Map<String, sdk.Marker> _markerLookup = {};
  bool _isCameraMoving = false;
  bool _styleLoaded = false;
  Timer? _styleTimeoutTimer;
  int _styleIndex = 0;
  bool _isUpdatingMarkers = false;
  int _markersUpdateGeneration = 0;

  // Track route IDs that are managed by the widget (passed via routeLines prop).
  // Routes added directly via controller are NOT tracked here and won't be
  // affected by widget route updates.
  final Set<String> _widgetManagedRouteIds = {};

  // Auto tile URL loading state
  String? _resolvedStyleUrl;
  bool _styleUrlLoading = false;

  // Map ready state for crossfade animation
  bool _mapReady = false;

  // Widget overlay state - using ValueNotifiers for efficient updates
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(14);
  final ValueNotifier<double> _bearingNotifier = ValueNotifier<double>(0);
  final ValueNotifier<double> _metersPerPixelNotifier = ValueNotifier<double>(1);
  bool _isLocationTracking = false;

  // Throttling for camera updates to reduce rebuilds
  DateTime? _lastOverlayUpdateAt;
  static const Duration _overlayUpdateThrottle = Duration(milliseconds: 100);

  // Touch latency logging
  final Stopwatch _touchStopwatch = Stopwatch();
  bool _touchLatencyLogged = false;
  int _cameraUpdateCount = 0;
  DateTime? _lastTouchTime;

  // Custom user location layer
  UserLocationLayer? _userLocationLayer;
  StreamSubscription<LocationData>? _locationSubscription;

  // Connectivity monitoring
  StreamSubscription<NetworkStatus>? _connectivitySubscription;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? QorviaMapController();
    _resolveStyleUrl();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    if (!widget.autoRefreshOnConnectivity) return;
    if (!QorviaMapsSDK.isInitialized || !QorviaMapsSDK.isOfflineEnabled) return;

    _connectivitySubscription = ConnectivityService.instance.statusStream.listen(
      _onConnectivityChanged,
    );

    // Check initial offline mode state
    _isOfflineMode = QorviaMapsSDK.isUsingOfflineMode;
  }

  void _onConnectivityChanged(NetworkStatus status) {
    _log('Connectivity changed', {'status': status.name, 'isConnected': status.isConnected});

    // When connection is restored and we're using offline mode, try to switch to online
    if (status.isConnected && _isOfflineMode) {
      _log('Connection restored, attempting to switch to online style');
      _refreshStyleUrl();
    }
    // When connection is lost, try to switch to offline mode (will use cached style if available)
    else if (!status.isConnected && !_isOfflineMode) {
      _log('Connection lost, attempting to switch to offline style');
      _refreshStyleUrl();
    }
  }

  Future<void> _refreshStyleUrl() async {
    if (!QorviaMapsSDK.isInitialized) return;

    try {
      final newUrl = await QorviaMapsSDK.refreshTileUrl();
      final newOfflineMode = QorviaMapsSDK.isUsingOfflineMode;

      if (_resolvedStyleUrl != newUrl && mounted) {
        _log('Style URL changed', {
          'old': _resolvedStyleUrl,
          'new': newUrl,
          'isOffline': newOfflineMode,
        });

        setState(() {
          _resolvedStyleUrl = newUrl;
          _styleLoaded = false;
          _mapReady = false;
        });

        // Notify about offline mode change
        if (_isOfflineMode != newOfflineMode) {
          _isOfflineMode = newOfflineMode;
          widget.onOfflineModeChanged?.call(newOfflineMode);
        }

        // Reload style in existing map controller
        await _maplibreController?.setStyle(newUrl);
      }
    } catch (e) {
      _log('Failed to refresh style URL', {'error': e.toString()});
    }
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    if (!widget.enableLogging) return;
    final dataStr = data != null ? ' $data' : '';
    debugPrint('[QorviaMapView] $message$dataStr');
  }

  void _resolveStyleUrl() {
    // If explicit styleUrl is provided, use it
    if (widget.options.styleUrl != null) {
      _log('Using explicit styleUrl', {'url': widget.options.styleUrl});
      _resolvedStyleUrl = widget.options.styleUrl;
      return;
    }

    // If autoLoadStyle is disabled, use fallback
    if (!widget.autoLoadStyle) {
      _log('autoLoadStyle disabled, using fallback');
      _resolvedStyleUrl = _getFallbackStyle();
      return;
    }

    // Try to get URL from SDK
    if (QorviaMapsSDK.isInitialized) {
      final sdk = QorviaMapsSDK.instance;

      // Check if already cached
      if (sdk.hasTileUrl) {
        _log('Using cached SDK tile URL', {'url': sdk.tileUrlOrNull});
        _resolvedStyleUrl = sdk.tileUrlOrNull;
        return;
      }

      // Need to fetch - show loading state
      _log('Fetching tile URL from SDK...');
      _styleUrlLoading = true;

      sdk.getTileUrl().then((url) {
        if (mounted) {
          final isOffline = QorviaMapsSDK.isUsingOfflineMode;
          _log('SDK tile URL received', {'url': url, 'isOffline': isOffline});
          setState(() {
            _resolvedStyleUrl = url;
            _styleUrlLoading = false;
            _isOfflineMode = isOffline;
          });
          // Notify if starting in offline mode
          if (isOffline) {
            widget.onOfflineModeChanged?.call(true);
          }
        }
      });
    } else {
      // SDK not initialized, use fallback
      _log('SDK not initialized, using fallback');
      _resolvedStyleUrl = _getFallbackStyle();
    }
  }

  String _getFallbackStyle() {
    if (widget.options.styleUrlFallbacks.isNotEmpty) {
      return widget.options.styleUrlFallbacks.first;
    }
    return MapStyles.osm;
  }

  @override
  void didUpdateWidget(QorviaMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update markers if changed
    if (widget.markers != oldWidget.markers ||
        widget.clusterOptions != oldWidget.clusterOptions) {
      if (_styleLoaded) {
        _updateMarkers();
      }
    }

    // Update routes if changed
    if (widget.routeLines != oldWidget.routeLines) {
      if (_styleLoaded) {
        _updateRouteLines();
      }
    }
  }

  /// Updates markers using diff-based algorithm for better performance.
  /// Only adds new markers, removes old markers, and updates changed markers.
  Future<void> _updateMarkers() async {
    // Prevent concurrent updates - use generation counter to cancel stale updates
    final generation = ++_markersUpdateGeneration;

    if (_isUpdatingMarkers) {
      return; // Skip if already updating, the current update will use latest data
    }

    _isUpdatingMarkers = true;
    final stopwatch = Stopwatch()..start();

    try {
      // Check if this update is still valid
      if (generation != _markersUpdateGeneration) return;

      final markersToRender = _clusterMarkers(widget.markers);

      // Build new marker map
      final newMarkerMap = <String, sdk.Marker>{};
      for (final marker in markersToRender) {
        newMarkerMap[marker.id] = marker;
      }

      // Calculate diff
      final oldIds = _markerLookup.keys.toSet();
      final newIds = newMarkerMap.keys.toSet();

      final toRemove = oldIds.difference(newIds).toList();
      final toAdd = newIds.difference(oldIds).toList();
      final toCheck = oldIds.intersection(newIds);

      // Find markers that changed position (need update)
      final toUpdate = <String>[];
      for (final id in toCheck) {
        final oldMarker = _markerLookup[id]!;
        final newMarker = newMarkerMap[id]!;
        if (_markerNeedsUpdate(oldMarker, newMarker)) {
          toUpdate.add(id);
        }
      }

      // Log diff stats
      if (kDebugMode && widget.enableLogging) {
        debugPrint('[QorviaMapView._updateMarkers] DIFF: '
            'total=${markersToRender.length}, '
            'add=${toAdd.length}, '
            'remove=${toRemove.length}, '
            'update=${toUpdate.length}, '
            'unchanged=${toCheck.length - toUpdate.length}');
      }

      // Check if full refresh is more efficient
      // (if changing more than 50% of markers, batch is faster)
      final changeCount = toAdd.length + toRemove.length + toUpdate.length;
      final totalCount = math.max(oldIds.length, newIds.length);
      final useFullRefresh = totalCount > 0 && changeCount > totalCount * 0.5;

      if (useFullRefresh && totalCount > 10) {
        // Full refresh: clear all and add all using batch
        if (kDebugMode && widget.enableLogging) {
          debugPrint('[QorviaMapView._updateMarkers] Using FULL REFRESH (change ratio: ${(changeCount / totalCount * 100).toStringAsFixed(1)}%)');
        }

        await _controller.clearMarkers();
        _markerLookup.clear();

        if (generation != _markersUpdateGeneration) return;

        // Use batch add for all markers
        await _controller.addMarkers(markersToRender);

        // Update lookup
        for (final marker in markersToRender) {
          _markerLookup[marker.id] = marker;
        }
      } else {
        // Diff-based update: remove, add, update individually
        if (kDebugMode && widget.enableLogging) {
          debugPrint('[QorviaMapView._updateMarkers] Using DIFF UPDATE');
        }

        // Step 1: Remove old markers (batch)
        if (toRemove.isNotEmpty) {
          await _controller.removeMarkers(toRemove);
          for (final id in toRemove) {
            _markerLookup.remove(id);
          }
        }

        if (generation != _markersUpdateGeneration) return;

        // Step 2: Update changed markers (position only)
        for (final id in toUpdate) {
          if (generation != _markersUpdateGeneration) return;
          final newMarker = newMarkerMap[id]!;
          await _controller.updateMarkerPosition(id, newMarker.position);
          _markerLookup[id] = newMarker;
        }

        // Step 3: Add new markers (batch)
        if (toAdd.isNotEmpty) {
          final newMarkers = toAdd.map((id) => newMarkerMap[id]!).toList();
          await _controller.addMarkers(newMarkers);
          for (final marker in newMarkers) {
            _markerLookup[marker.id] = marker;
          }
        }
      }

      stopwatch.stop();
      if (kDebugMode && widget.enableLogging) {
        debugPrint('[QorviaMapView._updateMarkers] COMPLETE: ${stopwatch.elapsedMilliseconds}ms');
      }

      // Configure icon rotation alignment to 'map' so markers rotate with the map
      // (point north regardless of camera rotation). Do this once after first marker add.
      if (!_controller.isIconRotationAlignmentConfigured && markersToRender.isNotEmpty) {
        await _controller.setIconRotationAlignment('map');
      }
    } finally {
      _isUpdatingMarkers = false;

      // If there was a newer request while we were updating, run again
      if (generation != _markersUpdateGeneration) {
        _updateMarkers();
      }
    }
  }

  /// Checks if a marker needs to be updated (position changed).
  bool _markerNeedsUpdate(sdk.Marker oldMarker, sdk.Marker newMarker) {
    // Check position change
    if (oldMarker.position.lat != newMarker.position.lat ||
        oldMarker.position.lon != newMarker.position.lon) {
      return true;
    }
    // Check rotation change
    if (oldMarker.rotation != newMarker.rotation) {
      return true;
    }
    return false;
  }

  /// Updates route lines using diff-based approach.
  /// Only manages routes that are passed via widget.routeLines.
  /// Routes added directly via controller are NOT affected.
  Future<void> _updateRouteLines() async {
    // Build set of new route IDs from widget
    final newRouteIds = widget.routeLines.map((r) => r.id).toSet();

    // Remove routes that were widget-managed but are no longer in the list
    final toRemove = _widgetManagedRouteIds.difference(newRouteIds);
    for (final routeId in toRemove) {
      await _controller.removeRoute(routeId);
    }

    // Add/update routes from widget
    for (final routeLine in widget.routeLines) {
      await _controller.displayRouteLine(routeLine);
    }

    // Update tracking set
    _widgetManagedRouteIds
      ..clear()
      ..addAll(newRouteIds);
  }

  void _onMapCreated(MaplibreMapController controller) {
    _maplibreController = controller;
    _controller.setMapController(controller);
    controller.onSymbolTapped.add(_onSymbolTapped);
    controller.addListener(_onMapControllerChanged);

    // Clear widget-managed route tracking (previous routes are gone)
    _widgetManagedRouteIds.clear();

    // Notify callback
    widget.onMapCreated?.call(_controller);

    _styleIndex = 0;
    _scheduleStyleTimeout();
  }

  void _onStyleLoaded() {
    _log('Style loaded', {'styleUrl': _resolvedStyleUrl});
    _styleLoaded = true;
    _styleTimeoutTimer?.cancel();
    _updateMarkers();
    // Clear tracking before updating routes on style load (style change clears all routes)
    _widgetManagedRouteIds.clear();
    _updateRouteLines();
    _initUserLocationLayer();

    // Mark map as ready for crossfade animation
    if (!_mapReady) {
      _log('Map ready, triggering crossfade animation');
      setState(() {
        _mapReady = true;
      });
    }
  }

  /// Initializes custom user location layer if configured.
  Future<void> _initUserLocationLayer() async {
    final style = widget.options.userLocationStyle;
    if (!widget.options.showUserLocation || style == null) {
      _log('User location: using native MapLibre indicator');
      return;
    }

    final mapController = _maplibreController;
    if (mapController == null) {
      _log('User location: mapController is null, skipping custom layer');
      return;
    }

    _log('User location: initializing custom layer', {'iconAsset': style.iconAsset});

    try {
      _userLocationLayer = UserLocationLayer(style: style);
      await _userLocationLayer!.attach(mapController);
      await _startLocationUpdates();
      _log('User location: custom layer initialized successfully');
    } catch (e) {
      _log('User location: failed to initialize custom layer', {'error': e.toString()});
      // Fallback: native indicator will be shown (if myLocationEnabled is true)
      _userLocationLayer = null;
    }
  }

  /// Starts listening to location updates for custom user location layer.
  Future<void> _startLocationUpdates() async {
    if (_userLocationLayer == null) return;

    _log('User location: starting location updates');

    final locationService = LocationService();

    // Start location tracking if not already active
    if (!locationService.isTracking) {
      _log('User location: starting location tracking');
      await locationService.startTracking();
    }

    _locationSubscription?.cancel();
    _locationSubscription = locationService.locationStream.listen(
      (location) {
        _userLocationLayer?.update(
          location.coordinates,
          location.heading ?? 0,
          accuracy: location.accuracy,
        );
      },
      onError: (e) {
        _log('User location: location stream error', {'error': e.toString()});
      },
    );

    // Update immediately with last known location or fetch current position
    final lastLocation = locationService.lastLocation;
    if (lastLocation != null) {
      _log('User location: using last known location', {
        'lat': lastLocation.coordinates.lat,
        'lon': lastLocation.coordinates.lon,
      });
      _userLocationLayer?.update(
        lastLocation.coordinates,
        lastLocation.heading ?? 0,
        accuracy: lastLocation.accuracy,
      );
    } else {
      // No cached location - actively fetch current position
      _log('User location: no cached location, fetching current position');
      final currentLocation = await locationService.getCurrentLocation();
      if (currentLocation != null) {
        _log('User location: got current position', {
          'lat': currentLocation.coordinates.lat,
          'lon': currentLocation.coordinates.lon,
        });
        _userLocationLayer?.update(
          currentLocation.coordinates,
          currentLocation.heading ?? 0,
          accuracy: currentLocation.accuracy,
        );
      } else {
        _log('User location: failed to get current position, marker will appear on first stream update');
      }
    }
  }

  /// Stops listening to location updates.
  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _log('User location: stopped location updates');
  }

  void _scheduleStyleTimeout() {
    _styleTimeoutTimer?.cancel();
    if (widget.options.styleUrlFallbacks.isEmpty) return;

    _styleTimeoutTimer = Timer(widget.options.styleLoadTimeout, () async {
      if (_styleLoaded) return;
      await _switchToNextStyle();
    });
  }

  Future<void> _switchToNextStyle() async {
    final controller = _maplibreController;
    if (controller == null) return;

    if (_styleIndex >= widget.options.styleUrlFallbacks.length) {
      return;
    }

    final nextStyle = widget.options.styleUrlFallbacks[_styleIndex];
    _styleIndex += 1;
    _styleLoaded = false;
    await controller.setStyle(nextStyle);
    _scheduleStyleTimeout();
  }

  void _onCameraIdle() {
    if (widget.enableLogging && _touchStopwatch.isRunning) {
      _touchStopwatch.stop();
      debugPrint('[QorviaMapView.Latency] CAMERA_IDLE: ${_touchStopwatch.elapsedMilliseconds}ms after touch, $_cameraUpdateCount updates');
      _cameraUpdateCount = 0;
    }

    final position = _controller.cameraPosition;
    if (position != null) {
      widget.onCameraIdle?.call(position);
    }
    if (_isCameraMoving) {
      _isCameraMoving = false;
    }
    if (widget.clusterOptions?.enabled == true) {
      final sw = Stopwatch()..start();
      _updateMarkers().then((_) {
        if (widget.enableLogging) {
          debugPrint('[QorviaMapView.Latency] CLUSTER_UPDATE: ${sw.elapsedMilliseconds}ms, ${widget.markers.length} markers');
        }
      });
    }
  }

  void _onMapClick(math.Point<num> point, LatLng latLng) {
    widget.onMapTap?.call(Coordinates(
      lat: latLng.latitude,
      lon: latLng.longitude,
    ));
  }

  void _onMapLongClick(math.Point<num> point, LatLng latLng) {
    widget.onMapLongPress?.call(Coordinates(
      lat: latLng.latitude,
      lon: latLng.longitude,
    ));
  }

  void _onSymbolTapped(Symbol symbol) {
    final markerId = _controller.markerIdForSymbolId(symbol.id);
    if (markerId == null) return;

    final marker = _markerLookup[markerId];
    if (marker == null) return;

    if (marker is ClusterMarker) {
      widget.onClusterTap?.call(marker.cluster);
    } else {
      widget.onMarkerTap?.call(marker);
    }
  }

  void _onMapControllerChanged() {
    final mapPosition = _controller.maplibreCameraPosition;
    if (mapPosition == null) return;

    // Latency logging
    if (widget.enableLogging && _touchStopwatch.isRunning) {
      _cameraUpdateCount++;
      if (!_touchLatencyLogged) {
        _touchLatencyLogged = true;
        debugPrint('[QorviaMapView.Latency] FIRST_CAMERA_RESPONSE: ${_touchStopwatch.elapsedMilliseconds}ms after touch');
      }
    }

    final sdkPosition = sdk_camera.CameraPosition(
      center: Coordinates(
        lat: mapPosition.target.latitude,
        lon: mapPosition.target.longitude,
      ),
      zoom: mapPosition.zoom,
      tilt: mapPosition.tilt,
      bearing: mapPosition.bearing,
    );

    _controller.updateCameraPosition(sdkPosition);

    // Update widget overlay state using ValueNotifiers (no setState needed)
    // Also throttle updates to reduce overhead
    final hasWidgetOverlays = widget.options.widgetsConfig.zoomControlsConfig.enabled ||
        widget.options.widgetsConfig.compassConfig.enabled ||
        widget.options.widgetsConfig.scaleConfig.enabled;

    if (hasWidgetOverlays) {
      final now = DateTime.now();
      if (_lastOverlayUpdateAt != null &&
          now.difference(_lastOverlayUpdateAt!) < _overlayUpdateThrottle) {
        // Skip update - throttled
      } else {
        _lastOverlayUpdateAt = now;

        final newZoom = mapPosition.zoom;
        final newBearing = mapPosition.bearing;
        final newMetersPerPixel = _calculateMetersPerPixel(
          mapPosition.target.latitude,
          mapPosition.zoom,
        );

        // Update ValueNotifiers - only affected widgets will rebuild
        if (_zoomNotifier.value != newZoom) {
          _zoomNotifier.value = newZoom;
        }
        if (_bearingNotifier.value != newBearing) {
          _bearingNotifier.value = newBearing;
        }
        if (_metersPerPixelNotifier.value != newMetersPerPixel) {
          _metersPerPixelNotifier.value = newMetersPerPixel;
        }
      }
    }

    if (!_isCameraMoving) {
      _isCameraMoving = true;
      if (widget.enableLogging && _touchStopwatch.isRunning) {
        debugPrint('[QorviaMapView.Latency] CAMERA_MOVE_STARTED: ${_touchStopwatch.elapsedMilliseconds}ms after touch');
      }
      widget.onCameraMoveStarted?.call(sdkPosition);
    }
    widget.onCameraMove?.call(sdkPosition);
  }

  /// Clusters markers using grid-based spatial indexing for O(n) performance.
  /// Previous O(n²) algorithm checked all pairs; this checks only neighboring cells.
  List<sdk.Marker> _clusterMarkers(List<sdk.Marker> markers) {
    final options = widget.clusterOptions;
    if (options == null || !options.enabled) {
      return markers;
    }

    final zoom = _controller.maplibreCameraPosition?.zoom ??
        widget.options.initialZoom;

    if (zoom < options.minZoom || zoom > options.maxZoom) {
      return markers;
    }

    if (markers.length < options.minClusterSize) {
      return markers;
    }

    final stopwatch = Stopwatch()..start();

    // Calculate cell size in degrees based on cluster radius
    // Use the center latitude for approximation
    final centerLat = markers.isNotEmpty
        ? markers.map((m) => m.position.lat).reduce((a, b) => a + b) / markers.length
        : 0.0;
    final radiusMeters = _clusterRadiusMeters(centerLat, zoom, options.radiusPx);

    // Convert radius to degrees (approximate)
    // 1 degree latitude ≈ 111,320 meters
    // 1 degree longitude ≈ 111,320 * cos(lat) meters
    final cellSizeLat = radiusMeters / 111320.0;
    final cellSizeLon = radiusMeters / (111320.0 * math.cos(centerLat * math.pi / 180));

    // Build spatial grid
    final grid = <String, List<int>>{};
    for (int i = 0; i < markers.length; i++) {
      final marker = markers[i];
      final cellKey = _getCellKey(marker.position.lat, marker.position.lon, cellSizeLat, cellSizeLon);
      grid.putIfAbsent(cellKey, () => []).add(i);
    }

    // Track which markers are already clustered
    final clustered = List<bool>.filled(markers.length, false);
    final result = <sdk.Marker>[];
    int clusterIndex = 0;

    // Process each marker
    for (int i = 0; i < markers.length; i++) {
      if (clustered[i]) continue;

      final baseMarker = markers[i];
      final baseRadiusMeters = _clusterRadiusMeters(
        baseMarker.position.lat,
        zoom,
        options.radiusPx,
      );

      final clusterMembers = <sdk.Marker>[baseMarker];
      clustered[i] = true;

      // Get cell coordinates for the base marker
      final baseCellX = (baseMarker.position.lon / cellSizeLon).floor();
      final baseCellY = (baseMarker.position.lat / cellSizeLat).floor();

      // Check neighboring cells (3x3 grid around current cell)
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final neighborKey = '${baseCellX + dx},${baseCellY + dy}';
          final cellMarkers = grid[neighborKey];
          if (cellMarkers == null) continue;

          for (final candidateIdx in cellMarkers) {
            if (clustered[candidateIdx]) continue;

            final candidate = markers[candidateIdx];
            if (baseMarker.position.distanceTo(candidate.position) <= baseRadiusMeters) {
              clusterMembers.add(candidate);
              clustered[candidateIdx] = true;
            }
          }
        }
      }

      // Create cluster or add individual markers
      if (clusterMembers.length >= options.minClusterSize) {
        final centroid = _calculateCentroid(clusterMembers);
        final cluster = MarkerCluster(
          id: 'cluster_${zoom.toStringAsFixed(2)}_${clusterIndex++}',
          position: centroid,
          markers: clusterMembers,
        );
        result.add(ClusterMarker(cluster: cluster, style: options.style));
      } else {
        result.addAll(clusterMembers);
      }
    }

    stopwatch.stop();
    if (kDebugMode && widget.enableLogging) {
      debugPrint('[QorviaMapView._clusterMarkers] '
          'input=${markers.length}, '
          'output=${result.length}, '
          'clusters=${result.whereType<ClusterMarker>().length}, '
          'gridCells=${grid.length}, '
          'time=${stopwatch.elapsedMilliseconds}ms');
    }

    return result;
  }

  /// Returns a cell key for grid-based spatial indexing.
  String _getCellKey(double lat, double lon, double cellSizeLat, double cellSizeLon) {
    final cellX = (lon / cellSizeLon).floor();
    final cellY = (lat / cellSizeLat).floor();
    return '$cellX,$cellY';
  }

  Coordinates _calculateCentroid(List<sdk.Marker> markers) {
    double latSum = 0;
    double lonSum = 0;

    for (final marker in markers) {
      latSum += marker.position.lat;
      lonSum += marker.position.lon;
    }

    return Coordinates(
      lat: latSum / markers.length,
      lon: lonSum / markers.length,
    );
  }

  double _clusterRadiusMeters(double latitude, double zoom, double radiusPx) {
    final latRad = latitude * math.pi / 180;
    final metersPerPixel =
        156543.03392 * math.cos(latRad) / math.pow(2, zoom);
    return radiusPx * metersPerPixel;
  }

  // === Widget Builder Helpers ===

  /// Wraps a widget with positioning based on WidgetConfig.
  Widget _buildPositionedWidget(Widget child, WidgetConfig config) {
    return Align(
      alignment: config.alignment,
      child: Padding(
        padding: config.padding,
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }

  /// Builds zoom controls widget with customization support.
  Widget _buildZoomControls(double currentZoom) {
    final config = widget.options.widgetsConfig.zoomControlsConfig;
    if (!config.enabled) return const SizedBox.shrink();

    final data = MapControlsWidgetData(
      currentZoom: currentZoom,
      currentBearing: _bearingNotifier.value,
      currentTilt: 0,
      isUserLocationEnabled: widget.options.showUserLocation,
      isTracking: _isLocationTracking,
      minZoom: widget.options.minZoom,
      maxZoom: widget.options.maxZoom,
    );

    final builder = widget.options.widgetsConfig.zoomControlsBuilder;

    final child = builder != null
        ? builder(data, _onZoomIn, _onZoomOut)
        : ZoomControls(
            currentZoom: currentZoom,
            minZoom: widget.options.minZoom,
            maxZoom: widget.options.maxZoom,
            onZoomIn: _onZoomIn,
            onZoomOut: _onZoomOut,
          );

    return _buildPositionedWidget(child, config);
  }

  /// Builds compass widget with customization support.
  Widget _buildCompass(double currentBearing) {
    final config = widget.options.widgetsConfig.compassConfig;
    if (!config.enabled) return const SizedBox.shrink();

    final builder = widget.options.widgetsConfig.compassBuilder;

    final child = builder != null
        ? builder(currentBearing, _onResetBearing)
        : MapCompass(
            bearing: currentBearing,
            onReset: _onResetBearing,
          );

    return _buildPositionedWidget(child, config);
  }

  /// Builds scale bar widget with customization support.
  Widget _buildScaleBar(double metersPerPixel, double zoom) {
    final config = widget.options.widgetsConfig.scaleConfig;
    if (!config.enabled) return const SizedBox.shrink();

    final builder = widget.options.widgetsConfig.scaleBuilder;

    final child = builder != null
        ? builder(metersPerPixel, zoom)
        : MapScaleBar(
            metersPerPixel: metersPerPixel,
            zoom: zoom,
          );

    return _buildPositionedWidget(child, config);
  }

  /// Builds user location button widget with customization support.
  Widget _buildUserLocationButton() {
    final config = widget.options.widgetsConfig.userLocationButtonConfig;
    if (!config.enabled) return const SizedBox.shrink();

    final builder = widget.options.widgetsConfig.userLocationButtonBuilder;

    final child = builder != null
        ? builder(_isLocationTracking, _onToggleLocationTracking)
        : UserLocationButton(
            isTracking: _isLocationTracking,
            onToggle: _onToggleLocationTracking,
          );

    return _buildPositionedWidget(child, config);
  }

  // === Widget Callbacks ===

  void _onZoomIn() {
    _maplibreController?.animateCamera(
      CameraUpdate.zoomIn(),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onZoomOut() {
    _maplibreController?.animateCamera(
      CameraUpdate.zoomOut(),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onResetBearing() {
    _maplibreController?.animateCamera(
      CameraUpdate.bearingTo(0),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onToggleLocationTracking() {
    setState(() {
      _isLocationTracking = !_isLocationTracking;
    });
    // Note: Actual location tracking implementation depends on the app
  }

  /// Calculate meters per pixel at current zoom and latitude.
  double _calculateMetersPerPixel(double latitude, double zoom) {
    final latRad = latitude * math.pi / 180;
    return 156543.03392 * math.cos(latRad) / math.pow(2, zoom);
  }

  // Touch event handlers for latency logging
  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enableLogging) return;
    _touchStopwatch.reset();
    _touchStopwatch.start();
    _touchLatencyLogged = false;
    _cameraUpdateCount = 0;
    _lastTouchTime = DateTime.now();
    debugPrint('[QorviaMapView.Latency] TOUCH_DOWN: pointer=${event.pointer}, position=${event.localPosition}');
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.enableLogging) return;
    if (_lastTouchTime != null) {
      final touchDuration = DateTime.now().difference(_lastTouchTime!).inMilliseconds;
      debugPrint('[QorviaMapView.Latency] TOUCH_UP: duration=${touchDuration}ms, cameraUpdates=$_cameraUpdateCount');
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.options.backgroundColor;
    final animationDuration = widget.options.mapReadyAnimationDuration;

    // Show only placeholder while loading style URL
    if (_styleUrlLoading || _resolvedStyleUrl == null) {
      _log('Showing placeholder (style loading)');
      return Container(color: backgroundColor);
    }

    final widgetsConfig = widget.options.widgetsConfig;
    final hasOverlays = widgetsConfig.zoomControlsConfig.enabled ||
        widgetsConfig.compassConfig.enabled ||
        widgetsConfig.scaleConfig.enabled ||
        widgetsConfig.userLocationButtonConfig.enabled;

    // Disable native compass if we're showing our own
    final showNativeCompass = widget.options.showCompass &&
        !widgetsConfig.compassConfig.enabled;

    final map = MaplibreMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.options.initialCenter.lat,
          widget.options.initialCenter.lon,
        ),
        zoom: widget.options.initialZoom,
        tilt: widget.options.initialTilt,
        bearing: widget.options.initialBearing,
      ),
      styleString: _resolvedStyleUrl!,
      minMaxZoomPreference: MinMaxZoomPreference(
        widget.options.minZoom,
        widget.options.maxZoom,
      ),
      trackCameraPosition: true,
      compassEnabled: showNativeCompass,
      attributionButtonMargins: widget.options.showAttribution
          ? const math.Point<num>(8, 8)
          : const math.Point<num>(-100, -100),
      // Use native location indicator only if custom style is not provided
      myLocationEnabled: widget.options.showUserLocation &&
          widget.options.userLocationStyle == null,
      rotateGesturesEnabled: widget.options.rotateGesturesEnabled,
      tiltGesturesEnabled: widget.options.tiltGesturesEnabled,
      zoomGesturesEnabled: widget.options.zoomGesturesEnabled,
      scrollGesturesEnabled: widget.options.scrollGesturesEnabled,
      doubleClickZoomEnabled: widget.options.doubleTapZoomEnabled,
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onCameraIdle: _onCameraIdle,
      onMapClick: _onMapClick,
      onMapLongClick: _onMapLongClick,
    );

    // Wrap map with Listener for touch latency logging
    final mapWithListener = widget.enableLogging
        ? Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            child: map,
          )
        : map;

    // Build the map content (with or without overlays)
    Widget mapContent;
    if (!hasOverlays) {
      mapContent = mapWithListener;
    } else {
      // Wrap with Stack for overlays - using ValueListenableBuilder for efficient updates
      mapContent = Stack(
      children: [
        mapWithListener,
        // Zoom controls - rebuilds only when zoom changes
        ValueListenableBuilder<double>(
          valueListenable: _zoomNotifier,
          builder: (context, zoom, _) => _buildZoomControls(zoom),
        ),
        // Compass - rebuilds only when bearing changes
        ValueListenableBuilder<double>(
          valueListenable: _bearingNotifier,
          builder: (context, bearing, _) => _buildCompass(bearing),
        ),
        // Scale bar - rebuilds only when metersPerPixel or zoom changes
        ValueListenableBuilder<double>(
          valueListenable: _metersPerPixelNotifier,
          builder: (context, metersPerPixel, _) => ValueListenableBuilder<double>(
            valueListenable: _zoomNotifier,
            builder: (context, zoom, _) => _buildScaleBar(metersPerPixel, zoom),
          ),
        ),
        // User location button
        _buildUserLocationButton(),
      ],
    );
    }

    // Use AnimatedSwitcher for smooth crossfade from placeholder to map
    if (animationDuration != Duration.zero) {
      return Stack(
        children: [
          // Background placeholder (always visible, will be covered by map)
          Container(color: backgroundColor),

          // Map with animated opacity
          AnimatedOpacity(
            opacity: _mapReady ? 1.0 : 0.0,
            duration: animationDuration,
            curve: Curves.easeInOut,
            child: mapContent,
          ),
        ],
      );
    }

    // No animation - return map directly
    return mapContent;
  }

  @override
  void dispose() {
    _styleTimeoutTimer?.cancel();
    _connectivitySubscription?.cancel();
    _stopLocationUpdates();
    _userLocationLayer?.dispose();
    _userLocationLayer = null;
    _maplibreController?.onSymbolTapped.remove(_onSymbolTapped);
    _maplibreController?.removeListener(_onMapControllerChanged);
    _maplibreController = null;
    _zoomNotifier.dispose();
    _bearingNotifier.dispose();
    _metersPerPixelNotifier.dispose();
    _widgetManagedRouteIds.clear();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }
}
