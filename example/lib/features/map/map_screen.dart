import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../../core/constants/app_constants.dart';
import '../../shared/services/app_location_service.dart';

/// Callback for when the map is ready.
typedef OnMapReady = void Function(QorviaMapController controller);

/// Map screen widget displaying the base map with markers and routes.
class MapScreen extends StatefulWidget {
  /// Controller for managing the map.
  final QorviaMapController? controller;

  /// Location service for managing user location.
  final AppLocationService? locationService;

  /// Initial center coordinates.
  final Coordinates? initialCenter;

  /// Markers to display on the map.
  final List<Marker> markers;

  /// Route lines to display on the map.
  final List<RouteLine> routeLines;

  /// Called when the map is tapped.
  final void Function(Coordinates)? onMapTap;

  /// Called when the map is ready.
  final OnMapReady? onMapReady;

  const MapScreen({
    super.key,
    this.controller,
    this.locationService,
    this.initialCenter,
    this.markers = const [],
    this.routeLines = const [],
    this.onMapTap,
    this.onMapReady,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late QorviaMapController _controller;
  bool _mapReady = false;
  Coordinates? _pendingCenter;
  Coordinates _initialCenter = const Coordinates(
    lat: AppConstants.defaultLat,
    lon: AppConstants.defaultLon,
  );

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? QorviaMapController();

    if (widget.initialCenter != null) {
      _initialCenter = widget.initialCenter!;
    }

    _loadCachedLocation();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCenter != null &&
        widget.initialCenter != oldWidget.initialCenter) {
      _initialCenter = widget.initialCenter!;
    }
  }

  Future<void> _loadCachedLocation() async {
    if (widget.initialCenter != null) return;

    final locationService = widget.locationService;
    if (locationService == null) return;

    final cached = await locationService.loadCachedLocation();
    if (cached != null && mounted) {
      _log('Using cached location', {'lat': cached.lat, 'lon': cached.lon});
      setState(() {
        _initialCenter = cached;
      });
      if (_mapReady) {
        _controller.animateCamera(
          CameraUpdate.newLatLngZoom(cached, AppConstants.defaultZoom),
        );
      }
    }
  }

  /// Moves the camera to the specified location.
  void moveToLocation(Coordinates coordinates, {double? zoom}) {
    final targetZoom = zoom ?? AppConstants.navigationZoom;
    if (_mapReady) {
      _log('Moving to location', {
        'lat': coordinates.lat,
        'lon': coordinates.lon,
        'zoom': targetZoom,
      });
      _controller.animateCamera(
        CameraUpdate.newLatLngZoom(coordinates, targetZoom),
      );
    } else {
      _log('Map not ready, storing pending center');
      _pendingCenter = coordinates;
    }
  }

  void _onMapCreated(QorviaMapController controller) {
    _log('Map created');
    _mapReady = true;
    widget.onMapReady?.call(controller);

    if (_pendingCenter != null) {
      moveToLocation(_pendingCenter!);
      _pendingCenter = null;
    }
  }

  void _onMapTap(Coordinates coordinates) {
    _log('Map tapped', {'lat': coordinates.lat, 'lon': coordinates.lon});
    widget.onMapTap?.call(coordinates);
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[MapScreen] $message$dataStr');
  }

  @override
  Widget build(BuildContext context) {
    return QorviaMapView(
      controller: _controller,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: AppConstants.defaultZoom,
        styleUrlFallbacks: const [
          MapStyles.openFreeMapLiberty, // Lighter style
          MapStyles.osm,
        ],
        showUserLocation: true,
      ),
      markers: widget.markers,
      routeLines: widget.routeLines,
      // TODO: Re-enable after performance testing
      // clusterOptions: const MarkerClusterOptions(
      //   style: MarkerClusterStyle(
      //     iconColor: Colors.indigo,
      //     iconImage: 'cluster-14',
      //   )
      // ),
      onMapTap: _onMapTap,
      onMapCreated: _onMapCreated,
      enableLogging: true, // Latency logging
    );
  }
}
