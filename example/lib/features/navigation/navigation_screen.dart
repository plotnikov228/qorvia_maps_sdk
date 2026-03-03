import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../search/models/travel_mode.dart';

/// Callback for requesting a new route during navigation.
typedef OnRerouteCallback = Future<RouteResponse> Function(
  Coordinates from,
  Coordinates to,
);

/// Full-screen navigation experience.
class NavigationScreen extends StatefulWidget {
  /// The route to navigate.
  final RouteResponse route;

  /// Initial location data.
  final LocationData? initialLocation;

  /// Current travel mode.
  final TravelMode travelMode;

  /// Called when navigation state changes.
  final void Function(NavigationState state)? onStateChanged;

  /// Called when navigation ends.
  final void Function(NavigationEndReason reason)? onNavigationEnd;

  /// Called when rerouting is needed.
  final OnRerouteCallback? onReroute;

  const NavigationScreen({
    super.key,
    required this.route,
    this.initialLocation,
    this.travelMode = TravelMode.car,
    this.onStateChanged,
    this.onNavigationEnd,
    this.onReroute,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  void initState() {
    super.initState();
    _log('NavigationScreen initialized', {
      'route_distance': widget.route.distanceMeters,
      'route_steps': widget.route.steps?.length ?? 0,
    });

    // Enter immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _log('NavigationScreen disposed');
    super.dispose();
  }

  void _onStateChanged(NavigationState state) {
    _log('Navigation state changed', {
      'currentStep': state.currentStepIndex,
      'remainingDistance': state.distanceRemaining,
    });
    widget.onStateChanged?.call(state);
  }

  void _onNavigationEnd(NavigationEndReason reason) {
    _log('Navigation ended', {'reason': reason.name});
    widget.onNavigationEnd?.call(reason);
  }

  Future<RouteResponse> _onReroute(Coordinates from, Coordinates to) async {
    _log('Rerouting', {
      'from': '${from.lat},${from.lon}',
      'to': '${to.lat},${to.lon}',
    });

    if (widget.onReroute != null) {
      return widget.onReroute!(from, to);
    }

    // Default implementation using SDK client
    final client = QorviaMapsSDK.instance.client;
    final route = await client.route(
      from: from,
      to: to,
      mode: widget.travelMode.transportMode,
      steps: true,
      language: 'ru',
    );
    return route;
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[NavigationScreen] $message$dataStr');
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      route: widget.route,
      initialLocation: widget.initialLocation,
      onStateChanged: _onStateChanged,
      options: const NavigationOptions(
        logLevel: NavigationLogLevel.debug,
        useNativeTracking: false,
        cursorColor: RouteColors.primary,
        routeLineColor: RouteColors.primary,
        routeLineOpacity: 1,
        routeLineWidth: 7,
        widgetsConfig: NavigationWidgetsConfig(

        ),
        trackingMode: CameraTrackingMode.followWithBearing,
        showNextTurnPanel: true,
        enableVoiceInstructions: true,
        voiceGuidanceOptions: VoiceGuidanceOptions(
          enabled: true,
          language: 'ru-RU',
        ),
      ),
      styleUrlFallbacks: const [
        MapStyles.openFreeMapLiberty,
        MapStyles.cartoPositron,
        MapStyles.osm,
      ],
      onNavigationEnd: _onNavigationEnd,
      onReroute: _onReroute,
    );
  }
}
