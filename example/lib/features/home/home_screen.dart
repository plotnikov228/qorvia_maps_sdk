import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart' hide SearchPanel;

import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../shared/services/app_location_service.dart';
import '../../shared/services/offline_geocoding_helper.dart';
import '../map/map_screen.dart';
import '../navigation/navigation_screen.dart';
import '../route/route_service.dart';
import '../route/widgets/navigation_button.dart';
import '../route/widgets/route_info_card.dart';
import '../search/models/selected_point.dart';
import '../search/models/travel_mode.dart';
import '../search/search_panel.dart';
import '../search/widgets/expandable_bottom_panel.dart';
import '../settings/settings_screen.dart';
import '../settings/settings_service.dart';
import 'widgets/map_pick_hint.dart';

/// Main home screen integrating map, search, and navigation.
class HomeScreen extends StatefulWidget {
  final SettingsService settingsService;

  const HomeScreen({
    super.key,
    required this.settingsService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QorviaMapController _controller = QorviaMapController();
  final AppLocationService _locationService = AppLocationService();
  late final RouteService _routeService;
  final GlobalKey<dynamic> _searchPanelKey = GlobalKey();

  bool _mapReady = false;
  bool _isNavigationMode = false;
  bool _isMapPickMode = false;
  bool _isRoutingPreview = false;
  bool _isRouting = false;
  Coordinates? _lastCameraPosition;

  SelectedPoint? _fromPoint;
  SelectedPoint? _toPoint;
  List<SelectedPoint> _waypoints = [];
  TravelMode _travelMode = TravelMode.car;
  ActiveField? _activeField;
  int? _activeWaypointIndex;

  RouteResponse? _activeRoute;
  List<RouteLine> _routeLines = [];
  List<Marker> _markers = [];

  // Panel height state for Column layout
  double _panelHeight = 0;

  @override
  void initState() {
    super.initState();
    _routeService = RouteService(QorviaMapsSDK.instance.client);
    _initLocation();
    _log('HomeScreen initialized');
  }

  @override
  void dispose() {
    _locationService.dispose();
    _log('HomeScreen disposed');
    super.dispose();
  }

  // ============================================================
  // Location
  // ============================================================

  Future<void> _initLocation() async {
    if (_locationService.isLocating) return;

    setState(() {});

    final location = await _locationService.initLocation(
      onServiceDisabled: _showMessage,
      onPermissionDenied: _showMessage,
    );

    if (location != null && mounted) {
      _moveToLocation(location.coordinates);
      await _setFromCurrentLocation(location.coordinates);
    } else if (mounted) {
      _showMessage(AppLocalizations.of(context).failedToGetLocation);
    }

    if (mounted) setState(() {});
  }

  void _moveToLocation(Coordinates coordinates) {
    if (_mapReady) {
      _log('Moving to location', {
        'lat': coordinates.lat,
        'lon': coordinates.lon,
      });
      _controller.animateCamera(
        CameraUpdate.newLatLngZoom(coordinates, AppConstants.navigationZoom),
      );
    }
  }

  Future<void> _setFromCurrentLocation(Coordinates coordinates) async {
    // Show loading state immediately with coordinates as placeholder
    final coordsLabel = '${coordinates.lat.toStringAsFixed(5)}, '
        '${coordinates.lon.toStringAsFixed(5)}';

    setState(() {
      _fromPoint = SelectedPoint(
        coordinates: coordinates,
        label: coordsLabel,
        isLoading: true,
      );
    });

    // Fetch address in background (offline-first)
    String label = coordsLabel;
    try {
      final reverse = await OfflineGeocodingHelper.reverse(
        coordinates: coordinates,
        language: Localizations.localeOf(context).languageCode,
      );
      if (reverse != null) {
        label = reverse.displayName;
        _log('Reverse geocode success', {'label': label});
      }
    } catch (e) {
      _log('Reverse geocode failed', {'error': e.toString()});
      // Keep coordinates as fallback
    }

    if (!mounted) return;
    setState(() {
      _fromPoint = SelectedPoint(coordinates: coordinates, label: label);
    });

    _updateRoutePreview();
  }

  // ============================================================
  // Map Picking
  // ============================================================

  void _selectPointFromMap(Coordinates coordinates) {
    if (!_isMapPickMode && _activeField == null) return;

    final targetField = _activeField ??
        (_fromPoint == null ? ActiveField.from : ActiveField.to);

    _log('Point selected from map', {
      'field': targetField.name,
      'lat': coordinates.lat,
      'lon': coordinates.lon,
    });

    // Set point immediately with coordinates as label + loading indicator
    final coordsLabel = '${coordinates.lat.toStringAsFixed(5)}, '
        '${coordinates.lon.toStringAsFixed(5)}';

    _setPoint(targetField, SelectedPoint(coordinates: coordinates, label: coordsLabel, isLoading: true));

    // Fetch address in background and update label when ready
    _resolveAddressInBackground(coordinates, targetField);
  }

  void _setPoint(ActiveField targetField, SelectedPoint point) {
    setState(() {
      switch (targetField) {
        case ActiveField.from:
          _fromPoint = point;
          break;
        case ActiveField.to:
          _toPoint = point;
          break;
        case ActiveField.waypoint:
          if (_activeWaypointIndex != null &&
              _activeWaypointIndex! < _waypoints.length) {
            _waypoints[_activeWaypointIndex!] = point;
            _searchPanelKey.currentState?.setWaypoint(_activeWaypointIndex!, point);
          }
          break;
      }
      _isMapPickMode = false;
      _activeWaypointIndex = null;
    });

    _updateRoutePreview();
  }

  void _resolveAddressInBackground(Coordinates coordinates, ActiveField targetField) {
    // Run in background - doesn't block UI (offline-first)
    OfflineGeocodingHelper.reverse(
      coordinates: coordinates,
      language: Localizations.localeOf(context).languageCode,
    ).then((reverse) {
      if (!mounted || reverse == null) return;

      // Update label with resolved address and clear loading state
      final currentPoint = targetField == ActiveField.from ? _fromPoint : _toPoint;
      if (currentPoint != null && currentPoint.coordinates == coordinates) {
        setState(() {
          final updatedPoint = SelectedPoint(
            coordinates: coordinates,
            label: reverse.displayName,
          );
          if (targetField == ActiveField.from) {
            _fromPoint = updatedPoint;
          } else if (targetField == ActiveField.to) {
            _toPoint = updatedPoint;
          }
        });
      }
    }).catchError((_) {
      if (!mounted) return;

      // Clear loading state on error, keep coordinates label
      final currentPoint = targetField == ActiveField.from ? _fromPoint : _toPoint;
      if (currentPoint != null && currentPoint.coordinates == coordinates) {
        setState(() {
          if (targetField == ActiveField.from) {
            _fromPoint = currentPoint.copyWith(isLoading: false);
          } else if (targetField == ActiveField.to) {
            _toPoint = currentPoint.copyWith(isLoading: false);
          }
        });
      }
    });
  }

  // ============================================================
  // Routing
  // ============================================================

  void _updateMarkersFromRoute() {
    if (_activeRoute != null) {
      _markers = _routeService.createRouteMarkers(_activeRoute!);
    } else {
      _markers = [];
    }
  }

  Future<void> _updateRoutePreview() async {
    if (_fromPoint == null || _toPoint == null) {
      setState(() {
        _activeRoute = null;
        _routeLines = [];
        _updateMarkersFromRoute();
      });
      return;
    }

    if (_isRoutingPreview) return;

    setState(() => _isRoutingPreview = true);

    try {
      final route = await _routeService.requestRoute(
        from: _fromPoint!,
        to: _toPoint!,
        mode: _travelMode,
        waypoints: _waypoints.isNotEmpty ? _waypoints : null,
        includeSteps: false,
      );

      if (route == null || !mounted) return;

      final line = _routeService.createRouteLine(route);

      setState(() {
        _activeRoute = route;
        _routeLines = [line];
        _updateMarkersFromRoute();
      });

      if (_mapReady) {
        await _controller.fitRoute(
          route,
          padding: const EdgeInsets.all(90),
        );
      }
    } catch (error) {
      _showMessage('${AppLocalizations.of(context).routeError}: $error');
    } finally {
      if (mounted) {
        setState(() => _isRoutingPreview = false);
      }
    }
  }

  // ============================================================
  // Navigation
  // ============================================================

  Future<void> _enterNavigationMode() async {
    if (_fromPoint == null || _toPoint == null) return;
    if (_isRouting) return;

    _log('Entering navigation mode');
    setState(() => _isRouting = true);

    try {
      // Always get fresh location before navigation (not cached)
      _log('Fetching fresh location for navigation');
      final freshLocation = await _locationService.getFreshLocation(
        timeout: const Duration(seconds: 5),
        accuracy: LocationAccuracy.high,
      );

      if (freshLocation != null) {
        _log('Fresh location obtained', {
          'lat': freshLocation.coordinates.lat,
          'lon': freshLocation.coordinates.lon,
          'accuracy': freshLocation.accuracy,
        });
      } else {
        _log('Fresh location failed, using cached/fallback');
      }

      final startPoint = _locationService.lastUserLocation ?? _fromPoint!.coordinates;
      _log('Navigation start point', {
        'lat': startPoint.lat,
        'lon': startPoint.lon,
        'isGPS': _locationService.lastUserLocation != null,
      });

      // Extract waypoint coordinates (only set waypoints)
      final waypointCoords = _waypoints
          .where((wp) => wp.isSet)
          .map((wp) => wp.coordinates)
          .toList();

      final route = await _routeService.requestNavigationRoute(
        from: startPoint,
        to: _toPoint!.coordinates,
        waypoints: waypointCoords.isNotEmpty ? waypointCoords : null,
        mode: _travelMode,
        language: Localizations.localeOf(context).languageCode,
      );

      _log('Navigation route received', {
        'distance': route.distanceMeters,
        'stepsCount': route.steps?.length ?? 0,
      });

      setState(() {
        _activeRoute = route;
        _isNavigationMode = true;
        _updateMarkersFromRoute();
      });
    } catch (error) {
      _showMessage('${AppLocalizations.of(context).routeError}: $error');
    } finally {
      if (mounted) {
        setState(() => _isRouting = false);
      }
    }
  }

  void _exitNavigationMode(NavigationEndReason reason) {
    _log('Exiting navigation mode', {'reason': reason.name});

    final locationToCenter = _locationService.lastUserLocation ?? _fromPoint?.coordinates;

    // Save last camera position so MapScreen rebuilds at the right spot
    if (locationToCenter != null) {
      _lastCameraPosition = locationToCenter;
    }

    // Defer state change to avoid layout conflicts during navigation callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() => _isNavigationMode = false);

      if (reason == NavigationEndReason.error) {
        _showMessage(AppLocalizations.of(context).navigationError);
      } else if (reason == NavigationEndReason.arrived) {
        _showMessage(AppLocalizations.of(context).youHaveArrived);
      }

      // Center map on last known location
      if (locationToCenter != null && _mapReady) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _controller.animateCamera(
              CameraUpdate.newLatLngZoom(locationToCenter, AppConstants.navigationZoom),
            );
          }
        });
      }
    });
  }

  Future<RouteResponse> _onReroute(Coordinates from, Coordinates to) async {
    _log('Rerouting');

    // Include remaining waypoints in reroute
    final waypointCoords = _waypoints
        .where((wp) => wp.isSet)
        .map((wp) => wp.coordinates)
        .toList();

    return await _routeService.requestNavigationRoute(
      from: from,
      to: to,
      waypoints: waypointCoords.isNotEmpty ? waypointCoords : null,
      mode: _travelMode,
      language: Localizations.localeOf(context).languageCode,
    );
  }

  // ============================================================
  // Search Panel Callbacks
  // ============================================================

  void _onFromChanged(SelectedPoint point) {
    _log('From changed', {'label': point.label});
    setState(() => _fromPoint = point);
    _updateRoutePreview();
  }

  void _onToChanged(SelectedPoint point) {
    _log('To changed', {'label': point.label});
    setState(() => _toPoint = point);
    _updateRoutePreview();
  }

  void _onTravelModeChanged(TravelMode mode) {
    _log('Travel mode changed', {'mode': mode.name});
    setState(() => _travelMode = mode);
    _updateRoutePreview();
  }

  void _onWaypointsChanged(List<SelectedPoint> waypoints) {
    _log('Waypoints changed', {'count': waypoints.length});
    setState(() {
      _waypoints = List<SelectedPoint>.from(waypoints);
    });
    _updateRoutePreview();
  }

  void _onMapSelect(ActiveField field, int? waypointIndex) {
    _log('Map select requested', {'field': field.name, 'waypointIndex': waypointIndex});
    setState(() {
      _activeField = field;
      _activeWaypointIndex = waypointIndex;
      _isMapPickMode = true;
    });

    final l10n = AppLocalizations.of(context);
    String message;
    switch (field) {
      case ActiveField.from:
        message = l10n.selectDeparturePoint;
        break;
      case ActiveField.to:
        message = l10n.selectDestinationPoint;
        break;
      case ActiveField.waypoint:
        message = l10n.selectWaypoint;
        break;
    }
    _showMessage(message);
  }

  void _onReset() {
    _log('Reset');
    setState(() {
      _fromPoint = null;
      _toPoint = null;
      _activeRoute = null;
      _routeLines = [];
      _updateMarkersFromRoute();
    });
  }

  // ============================================================
  // Helpers
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[HomeScreen] $message$dataStr');
  }

  // ============================================================
  // Panel height handling
  // ============================================================

  void _onPanelHeightChanged(double newHeight) {
    _log('Panel height callback', {
      'oldHeight': _panelHeight,
      'newHeight': newHeight,
      'diff': (_panelHeight - newHeight).abs(),
    });
    if ((_panelHeight - newHeight).abs() > 1.0) {
      setState(() {
        _panelHeight = newHeight;
      });
    }
  }

  void _onPanelSnapChanged(PanelSnapPoint snapPoint) {
    _log('Panel snapped', {
      'snapPoint': snapPoint.name,
      'height': snapPoint.height,
    });
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarPadding = MediaQuery.of(context).padding.top;

    // Calculate panel heights with proper clamping
    final minPanelHeight = AppConstants.panelMinHeight;
    // Ensure maxPanelHeight is at least minPanelHeight
    final maxPanelHeight = (screenHeight * AppConstants.panelMaxHeightFraction)
        .clamp(minPanelHeight, screenHeight);
    // Ensure initialPanelHeight is between min and max
    final initialPanelHeight = (screenHeight * AppConstants.panelInitialHeightFraction)
        .clamp(minPanelHeight, maxPanelHeight);

    // Initialize panel height if not set, or clamp existing value
    if (_panelHeight == 0) {
      _panelHeight = initialPanelHeight;
    } else {
      // Ensure existing panel height stays within bounds after recalculation
      _panelHeight = _panelHeight.clamp(minPanelHeight, maxPanelHeight);
    }

    // Navigation mode: full screen navigation
    if (_isNavigationMode && _activeRoute != null) {
      return Scaffold(
        body: NavigationScreen(
          key: const ValueKey('nav'),
          route: _activeRoute!,
          initialLocation: _locationService.lastLocationData,
          travelMode: _travelMode,
          onStateChanged: (state) {
            if (state.currentLocation != null) {
              _locationService.updateLocation(state.currentLocation!);
            }
          },
          onNavigationEnd: _exitNavigationMode,
          onReroute: _onReroute,
        ),
      );
    }

    // Calculate map height based on panel height
    final mapHeight = screenHeight - _panelHeight;
    _log('Build', {
      'screenHeight': screenHeight,
      'panelHeight': _panelHeight,
      'mapHeight': mapHeight,
    });

    // Normal mode: Column layout with map above panel
    return Scaffold(
      body: Column(
        children: [
          // Map area - explicit height calculated from panel height
          SizedBox(
            height: mapHeight,
            child: Stack(
              children: [
                // Map
                MapScreen(
                  key: const ValueKey('map'),
                  controller: _controller,
                  locationService: _locationService,
                  initialCenter: _lastCameraPosition,
                  markers: _markers,
                  routeLines: _routeLines,
                  onMapTap: _selectPointFromMap,
                  onMapReady: (_) {
                    _mapReady = true;
                  },
                ),

                // Top bar
                Positioned(
                  top: statusBarPadding + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _buildSettingsButton(),
                      Spacer(),
                      if (_fromPoint != null && _toPoint != null) ...[
                        const SizedBox(width: 8),
                        NavigationButton(
                          onTap: _enterNavigationMode,
                          isLoading: _isRouting,
                        ),
                      ],
                    ],
                  ),
                ),

                // My location FAB - positioned at bottom of map area
                if(!_isNavigationMode)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildLocationFab(),
                ),

                // Map pick hint
                if (_isMapPickMode)
                  Positioned(
                    top: statusBarPadding + 64,
                    left: 16,
                    right: 16,
                    child: const MapPickHint(),
                  ),
              ],
            ),
          ),

          // Bottom panel (fixed at bottom, expandable)
          ExpandableBottomPanel(
            minHeight: minPanelHeight,
            initialHeight: minPanelHeight, // Start collapsed
            maxHeight: maxPanelHeight,
            snapAnimationDuration: AppConstants.panelSnapDuration,
            onHeightChanged: _onPanelHeightChanged,
            onSnapChanged: _onPanelSnapChanged,
            childBuilder: (isCollapsed, expandPanel) => _buildSearchPanelContent(
              isCollapsed: isCollapsed,
              onExpandRequest: expandPanel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFab() {
    return FloatingActionButton.small(
      onPressed: _locationService.isLocating ? null : _initLocation,
      child: _locationService.isLocating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
    );
  }

  Widget _buildSettingsButton() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: AppColors.shadowMedium,
      child: InkWell(
        onTap: _openSettings,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.settings_rounded,
            size: 22,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    _log('Opening settings');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          settingsService: widget.settingsService,
        ),
      ),
    );
  }

  Widget _buildSearchPanelContent({
    required bool isCollapsed,
    required VoidCallback onExpandRequest,
  }) {
    _log('Building search panel content', {'isCollapsed': isCollapsed});

    // SearchPanel handles its own scrolling and padding.
    // Disable glassmorphism since ExpandableBottomPanel provides it.
    return SearchPanel(
      key: _searchPanelKey,
      fromPoint: _fromPoint,
      toPoint: _toPoint,
      waypoints: _waypoints,
      travelMode: _travelMode,
      isLocating: _locationService.isLocating,
      enableGlassmorphism: false,
      isCollapsed: isCollapsed,
      onExpandRequest: onExpandRequest,
      onFromChanged: _onFromChanged,
      onToChanged: _onToChanged,
      onWaypointsChanged: _onWaypointsChanged,
      onTravelModeChanged: _onTravelModeChanged,
      onMapSelect: _onMapSelect,
      onMyLocation: _initLocation,
      onReset: _onReset,
      child: _activeRoute != null
          ? RouteInfoCard(
              route: _activeRoute!,
              travelMode: _travelMode,
              isLoading: _isRoutingPreview,
            )
          : null,
    );
  }
}
