import 'dart:async';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../models/coordinates.dart';
import '../models/route/route_response.dart';
import '../models/route/route_step.dart';
import '../location/location_data.dart';
import '../markers/marker.dart' as sdk;
import '../sdk_initializer.dart';
import 'navigation_controller.dart';
import 'navigation_logger.dart';
import 'navigation_options.dart';
import 'navigation_state.dart';
import 'camera/camera_controller.dart';
import 'camera/position_animator.dart';
import 'tracking/route_tracker.dart';
import 'user_arrow/user_arrow_layer.dart';
import 'user_arrow/route_line_manager.dart';
import 'ui/next_turn_panel.dart';
import 'ui/eta_panel.dart';
import 'ui/speed_indicator.dart';
import 'ui/recenter_button.dart';
import 'ui/widget_data.dart';

/// Widget for turn-by-turn navigation with map.
class NavigationView extends StatefulWidget {
  /// The route to navigate.
  final RouteResponse route;

  /// Navigation options.
  final NavigationOptions options;

  /// Additional markers to render on the navigation map.
  final List<sdk.Marker> markers;

  /// Map style URL.
  final String? styleUrl;

  /// Fallback style URLs, used if the primary style fails to load.
  final List<String> styleUrlFallbacks;

  /// Timeout for style loading before trying the next fallback.
  final Duration styleLoadTimeout;

  /// Initial location to show arrow immediately while waiting for GPS.
  final LocationData? initialLocation;

  /// Called when navigation state changes.
  final void Function(NavigationState)? onStateChanged;

  /// Called when advancing to next step.
  final void Function(RouteStep)? onStepChanged;

  /// Called when arrived at destination.
  final VoidCallback? onArrival;

  /// Called when user goes off route.
  final VoidCallback? onOffRoute;

  /// Called when navigation ends.
  final void Function(NavigationEndReason)? onNavigationEnd;

  /// Called when reroute is requested.
  final void Function(Coordinates from, Coordinates to)? onRerouteRequested;

  /// Called to build a new route when off-route (auto reroute).
  final Future<RouteResponse> Function(Coordinates from, Coordinates to)?
      onReroute;

  /// Whether to automatically load the tile URL from SDK if not specified.
  final bool autoLoadStyle;

  const NavigationView({
    super.key,
    required this.route,
    this.options = const NavigationOptions(),
    this.markers = const [],
    this.styleUrl,
    this.styleUrlFallbacks = const [],
    this.styleLoadTimeout = const Duration(seconds: 8),
    this.initialLocation,
    this.onStateChanged,
    this.onStepChanged,
    this.onArrival,
    this.onOffRoute,
    this.onNavigationEnd,
    this.onRerouteRequested,
    this.onReroute,
    this.autoLoadStyle = true,
  });

  @override
  State<NavigationView> createState() => _NavigationViewState();
}

class _NavigationViewState extends State<NavigationView>
    with SingleTickerProviderStateMixin {
  // Core components
  late final NavigationController _navController;
  late final CameraController _cameraController;
  late final PositionAnimator _positionAnimator;
  late final UserArrowLayer _userArrowLayer;
  late final RouteLineManager _routeLineManager;
  RouteTracker? _routeTracker;

  // Map state
  MaplibreMapController? _mapController;
  String? _resolvedStyleUrl;
  bool _mapReady = false;
  bool _navigationStarted = false;

  // UI state
  NavigationState? _navState;
  CameraTrackingMode _trackingMode = CameraTrackingMode.followWithBearing;

  // Last known animated position for recenter animation
  Coordinates? _lastAnimatedPosition;
  double _lastAnimatedBearing = 0;

  // True while animateCamera recenter is in flight — suppresses moveCamera
  // from the 60fps loop so it doesn't cancel the smooth transition.
  bool _recentering = false;

  @override
  void initState() {
    super.initState();

    NavigationLogger.level = widget.options.logLevel;

    _navController = NavigationController(
      options: widget.options,
      onStateChanged: _onNavigationStateChanged,
      onStepChanged: widget.onStepChanged,
      onArrival: _onArrival,
      onOffRoute: _onOffRoute,
      onResumeTracking: _onResumeTracking,
    );

    _cameraController = CameraController(options: widget.options);
    _positionAnimator = PositionAnimator(options: widget.options);
    _userArrowLayer = UserArrowLayer(options: widget.options);
    _routeLineManager = RouteLineManager(options: widget.options);

    _trackingMode = widget.options.trackingMode;

    // Set up animation frame callback
    _positionAnimator.onFrame = _onAnimationFrame;

    // Resolve style URL
    _resolveStyleUrl();
  }

  @override
  void dispose() {
    _positionAnimator.dispose();
    _cameraController.dispose();
    _userArrowLayer.dispose();
    _routeLineManager.dispose();
    _navController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Style URL resolution
  // ---------------------------------------------------------------------------

  Future<void> _resolveStyleUrl() async {
    if (widget.styleUrl != null) {
      setState(() => _resolvedStyleUrl = widget.styleUrl);
      return;
    }

    if (!widget.autoLoadStyle) return;

    try {
      final sdk = QorviaMapsSDK.instance;
      if (sdk.hasTileUrl) {
        setState(() => _resolvedStyleUrl = sdk.tileUrlOrNull);
      } else {
        final url = await sdk.getTileUrl();
        if (mounted) {
          setState(() => _resolvedStyleUrl = url);
        }
      }
    } catch (e) {
      NavigationLogger.error('NavigationView', 'Failed to load style URL', e);
      // Try fallbacks
      if (widget.styleUrlFallbacks.isNotEmpty) {
        setState(() => _resolvedStyleUrl = widget.styleUrlFallbacks.first);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Map callbacks
  // ---------------------------------------------------------------------------

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
    NavigationLogger.info('NavigationView', 'Map controller created');
  }

  Future<void> _onStyleLoaded() async {
    if (_mapController == null) return;

    NavigationLogger.info('NavigationView', 'Style loaded');
    _mapReady = true;

    // Attach components to map
    _cameraController.attach(_mapController!);
    await _routeLineManager.attach(_mapController!);

    // Attach arrow layer FIRST so route layers can be inserted below it
    await _userArrowLayer.attach(_mapController!);

    // Draw route BELOW the arrow layer (cursor always on top)
    final polyline = widget.route.decodedPolyline;
    if (polyline != null && polyline.isNotEmpty) {
      await _routeLineManager.drawRoute(
        polyline,
        belowLayerId: kUserArrowLayerId,
      );

      // Initialize route tracker
      _routeTracker = RouteTracker(
        options: widget.options,
        polyline: polyline,
        steps: widget.route.steps ?? [],
      );

      // Set route for position animator
      _positionAnimator.setRoute(polyline);
    }

    NavigationLogger.info('NavigationView', 'Layers added: arrow → route (below)');

    // Set initial camera position
    if (widget.initialLocation != null) {
      final loc = widget.initialLocation!;
      await _cameraController.setInitialPosition(
        loc.coordinates,
        loc.heading ?? 0,
      );
      // Show initial arrow
      await _userArrowLayer.update(
        loc.coordinates,
        loc.heading ?? 0,
        accuracy: loc.accuracy,
      );
    } else if (polyline != null && polyline.isNotEmpty) {
      await _cameraController.setInitialPosition(polyline.first, 0);
    }

    // Start navigation and animation
    _startNavigation();
  }

  void _onCameraIdle() {
    // Could track user pan gestures here
  }

  // ---------------------------------------------------------------------------
  // Navigation lifecycle
  // ---------------------------------------------------------------------------

  Future<void> _startNavigation() async {
    if (_navigationStarted) return;
    _navigationStarted = true;

    // Start the 60fps animation loop
    _positionAnimator.start(this);

    // Start navigation controller (location tracking, step management)
    await _navController.startNavigation(widget.route);

    NavigationLogger.info('NavigationView', 'Navigation started');
  }

  void _onNavigationStateChanged(NavigationState state) {
    if (!mounted) return;

    // Feed location to animation pipeline
    final location = state.currentLocation;
    if (location != null) {
      _positionAnimator.feedLocation(location);

      // Update route tracker (for step detection, voice guidance)
      if (_routeTracker != null) {
        final progress =
            _routeTracker!.update(location.coordinates, location.speed ?? 0);

        // Update traveled portion of route line using route tracker's snapped position
        // (RouteCursorEngine handles segment index internally via PositionAnimator)
        if (_mapReady) {
          // Prefer cursor engine's segment index when on-route (more accurate)
          final cursorEngine = _positionAnimator.routeCursorEngine;
          final segIndex = cursorEngine != null && cursorEngine.isOnRoute
              ? cursorEngine.currentSegmentIndex
              : progress.closestSegmentIndex;
          final snappedPos = cursorEngine?.currentPosition ??
              progress.snappedPosition;

          _routeLineManager.updateTraveledPortion(
            segIndex,
            snappedPos,
          );
        }
      }
    }

    setState(() {
      _navState = state;
      _trackingMode = _navController.trackingMode;
    });

    widget.onStateChanged?.call(state);
  }

  void _onArrival() {
    NavigationLogger.info('NavigationView', 'Arrival detected — stopping navigation', {
      'hasOnArrivalCallback': widget.onArrival != null,
      'hasOnNavigationEndCallback': widget.onNavigationEnd != null,
    });
    _positionAnimator.stop();
    _navController.stopNavigation();
    widget.onArrival?.call();
    NavigationLogger.info('NavigationView', 'Calling onNavigationEnd with arrived reason');
    widget.onNavigationEnd?.call(NavigationEndReason.arrived);
  }

  void _onOffRoute() {
    NavigationLogger.warn('NavigationView', 'Off-route detected');
    widget.onOffRoute?.call();

    // Auto reroute if configured
    if (widget.options.autoReroute && widget.onReroute != null) {
      final location = _navController.currentLocation;
      if (location != null) {
        final polyline = widget.route.decodedPolyline;
        final destination = polyline?.last;
        if (destination != null) {
          widget.onRerouteRequested?.call(location.coordinates, destination);
          _performReroute(location.coordinates, destination);
        }
      }
    }
  }

  Future<void> _performReroute(Coordinates from, Coordinates to) async {
    if (widget.onReroute == null) return;

    try {
      final newRoute = await widget.onReroute!(from, to);

      // Reset components for new route
      _positionAnimator.reset();
      _cameraController.reset();
      _routeLineManager.reset();
      _routeTracker = null;

      final polyline = newRoute.decodedPolyline;
      if (polyline != null && polyline.isNotEmpty) {
        await _routeLineManager.drawRoute(
          polyline,
          belowLayerId: kUserArrowLayerId,
        );
        _routeTracker = RouteTracker(
          options: widget.options,
          polyline: polyline,
          steps: newRoute.steps ?? [],
        );
        _positionAnimator.setRoute(polyline);
      }

      // Restart animation
      _positionAnimator.start(this);
      await _navController.updateRoute(newRoute);

      NavigationLogger.info('NavigationView', 'Reroute completed');
    } catch (e) {
      NavigationLogger.error('NavigationView', 'Reroute failed', e);
    }
  }

  void _onResumeTracking() {
    if (_lastAnimatedPosition != null) {
      NavigationLogger.info('NavigationView', 'Auto-recenter: animating back');
      _recentering = true;
      _cameraController.animateToPosition(
        position: _lastAnimatedPosition!,
        bearing: _lastAnimatedBearing,
        duration: const Duration(milliseconds: 600),
      ).then((_) {
        _recentering = false;
      });
    } else {
      _cameraController.reset();
    }

    setState(() {
      _trackingMode = widget.options.trackingMode;
    });
  }

  // ---------------------------------------------------------------------------
  // Animation frame (60fps)
  // ---------------------------------------------------------------------------

  void _onAnimationFrame(
    Coordinates position,
    double bearing,
    double speed,
    int segmentIndex,
  ) {
    if (!_mapReady) return;

    // Track last position for recenter animation
    _lastAnimatedPosition = position;
    _lastAnimatedBearing = bearing;

    // Skip camera moveCamera while recenter animateCamera is in flight,
    // otherwise moveCamera cancels the smooth transition every frame.
    if (!_recentering) {
      _cameraController.updateCamera(
        position: position,
        bearing: bearing,
        speedMs: speed,
        trackingMode: _trackingMode,
      );
    }

    // Always update arrow and route line even during recenter
    // Pass segment index for real-time route line snapping
    _userArrowLayer.update(position, bearing);
    _routeLineManager.snapRouteStartToCursor(
      position,
      segmentIndex: segmentIndex,
    );
  }

  // ---------------------------------------------------------------------------
  // User interactions
  // ---------------------------------------------------------------------------

  void _onUserPan() {
    if (_trackingMode == CameraTrackingMode.free) {
      // Already in free mode — just reset the auto-recenter timer
      _navController.pauseTracking();
      return;
    }

    NavigationLogger.info('NavigationView', 'Entering free camera mode');
    _navController.pauseTracking();
    setState(() {
      _trackingMode = CameraTrackingMode.free;
    });
  }

  void _onRecenter() {
    _navController.recenter();

    // Animate back to the current tracking position for a smooth transition.
    // Set _recentering flag to suppress moveCamera from the 60fps loop
    // so it doesn't cancel the animateCamera transition.
    if (_lastAnimatedPosition != null) {
      _recentering = true;
      _cameraController.animateToPosition(
        position: _lastAnimatedPosition!,
        bearing: _lastAnimatedBearing,
        duration: const Duration(milliseconds: 600),
      ).then((_) {
        _recentering = false;
      });
    } else {
      _cameraController.reset();
    }

    setState(() {
      _trackingMode = widget.options.trackingMode;
    });
  }

  void _onClose() {
    NavigationLogger.info('NavigationView', 'Close button tapped - stopping navigation');
    _positionAnimator.stop();
    _navController.stopNavigation();
    widget.onNavigationEnd?.call(NavigationEndReason.cancelled);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_resolvedStyleUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Map layer
        _buildMap(),

        // Navigation overlays
        if (_navState != null) ...[
          // Turn instruction panel (top)
          _buildTurnPanel(),

          // Speed indicator (top-right)
          _buildSpeedIndicator(),

          // ETA panel (bottom)
          _buildEtaPanel(),

          // Recenter button
          _buildRecenterButton(),
        ],
      ],
    );
  }

  Widget _buildMap() {
    // Determine initial camera position from route or initial location
    final initialCoords = widget.initialLocation?.coordinates ??
        widget.route.decodedPolyline?.firstOrNull;
    final initialLatLng = initialCoords != null
        ? LatLng(initialCoords.lat, initialCoords.lon)
        : const LatLng(0, 0);

    return Listener(
      onPointerDown: (_) => _onUserPan(),
      child: MaplibreMap(
        initialCameraPosition: CameraPosition(
          target: initialLatLng,
          zoom: widget.options.zoom,
          tilt: widget.options.tilt,
          bearing: 0,
        ),
        styleString: _resolvedStyleUrl!,
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        onCameraIdle: _onCameraIdle,
        trackCameraPosition: true,
        compassEnabled: false,
        myLocationEnabled: false, // We manage location display ourselves
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: false, // Top-down, no manual tilt
        onMapLongClick: (_, __) {},
      ),
    );
  }

  Widget _buildTurnPanel() {
    final config = widget.options.widgetsConfig;
    if (!config.turnWidgetConfig.enabled || !widget.options.showNextTurnPanel) {
      return const SizedBox.shrink();
    }

    final data = TurnWidgetData.fromState(_navState!);
    if (!data.hasManeuver) return const SizedBox.shrink();

    final widgetConfig = config.turnWidgetConfig;

    return SafeArea(
      child: Align(
        alignment: widgetConfig.alignment,
        child: Padding(
          padding: widgetConfig.padding,
          child: config.turnWidgetBuilder != null
              ? config.turnWidgetBuilder!(data)
              : NextTurnPanel(
                  state: _navState!,
                  backgroundColor: config.colors.turnPanelBackground,
                  textColor: config.colors.turnPanelText,
                ),
        ),
      ),
    );
  }

  Widget _buildSpeedIndicator() {
    final config = widget.options.widgetsConfig;
    if (!config.speedWidgetConfig.enabled ||
        !widget.options.showSpeedIndicator) {
      return const SizedBox.shrink();
    }

    final data = SpeedWidgetData.fromState(_navState!);
    final widgetConfig = config.speedWidgetConfig;

    return SafeArea(
      child: Align(
        alignment: widgetConfig.alignment,
        child: Padding(
          padding: widgetConfig.padding,
          child: config.speedWidgetBuilder != null
              ? config.speedWidgetBuilder!(data)
              : SpeedIndicator(
                  speedKmh: data.currentSpeedKmh,
                  speedLimit: data.speedLimit,
                  backgroundColor: config.colors.speedBackground,
                  textColor: config.colors.speedText,
                  overLimitColor: config.colors.speedOverLimit,
                  limitBorderColor: config.colors.speedLimitBorder,
                ),
        ),
      ),
    );
  }

  Widget _buildEtaPanel() {
    final config = widget.options.widgetsConfig;
    if (!config.etaWidgetConfig.enabled || !widget.options.showEtaPanel) {
      return const SizedBox.shrink();
    }

    final data = EtaWidgetData.fromState(_navState!);
    final widgetConfig = config.etaWidgetConfig;

    // Use Positioned for full-width bottom panel to ensure proper hit testing
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: widgetConfig.padding,
        child: config.etaWidgetBuilder != null
            ? config.etaWidgetBuilder!(data, _onClose)
            : CompactEtaPanel(
                state: _navState!,
                onTap: _onClose,
              ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    final config = widget.options.widgetsConfig;
    if (!config.recenterWidgetConfig.enabled ||
        !widget.options.showRecenterButton) {
      return const SizedBox.shrink();
    }

    final data = RecenterWidgetData.fromMode(_trackingMode);
    if (!data.isVisible) return const SizedBox.shrink();

    final widgetConfig = config.recenterWidgetConfig;

    return SafeArea(
      child: Align(
        alignment: widgetConfig.alignment,
        child: Padding(
          padding: widgetConfig.padding,
          child: config.recenterWidgetBuilder != null
              ? config.recenterWidgetBuilder!(data, _onRecenter)
              : RecenterButton(
                  currentMode: _trackingMode,
                  onPressed: _onRecenter,
                ),
        ),
      ),
    );
  }
}
