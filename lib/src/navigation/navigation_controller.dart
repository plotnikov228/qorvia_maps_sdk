import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/coordinates.dart';
import '../models/route/route_response.dart';
import '../models/route/route_step.dart';
import '../location/location_data.dart';
import '../location/location_service.dart';
import '../location/location_settings.dart';
import '../location/location_filter.dart';
import 'navigation_logger.dart';
import 'navigation_state.dart';
import 'navigation_options.dart';
import 'voice/voice_guidance.dart';

/// Controller for managing navigation state and logic.
///
/// Clean state machine: idle → navigating → arrived/cancelled/error.
/// Handles location tracking, step progression, off-route detection,
/// multi-waypoint navigation, and voice guidance.
class NavigationController extends ChangeNotifier {
  final LocationService _locationService;
  final NavigationOptions options;
  final VoiceGuidance? _voiceGuidance;

  NavigationState? _state;
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _autoRecenterTimer;
  CameraTrackingMode _currentTrackingMode;
  bool _isNavigating = false;

  // Subscription recovery state
  int _subscriptionRecoveryAttempts = 0;
  static const int _maxRecoveryAttempts = 5;
  Timer? _recoveryTimer;

  // Step hysteresis state
  int _confirmedStepIndex = 0;
  // ignore: unused_field
  double _distancePastStepBoundary = 0;

  // Off-route logging throttle
  DateTime? _lastOffRouteLogTime;

  // Multi-waypoint state
  int _currentLegIndex = 0;
  int _waypointsVisited = 0;

  // Callbacks
  final void Function(NavigationState)? onStateChanged;
  final void Function(RouteStep)? onStepChanged;
  final void Function()? onArrival;
  final void Function()? onOffRoute;
  final void Function(RouteResponse)? onReroute;
  final void Function()? onResumeTracking;
  final void Function(int waypointIndex, Coordinates waypoint)?
      onWaypointArrival;

  NavigationController({
    LocationService? locationService,
    this.options = const NavigationOptions(),
    this.onStateChanged,
    this.onStepChanged,
    this.onArrival,
    this.onOffRoute,
    this.onReroute,
    this.onResumeTracking,
    this.onWaypointArrival,
  })  : _locationService = locationService ?? LocationService(),
        _currentTrackingMode = options.trackingMode,
        _voiceGuidance = _buildVoiceGuidance(options);

  static VoiceGuidance? _buildVoiceGuidance(NavigationOptions options) {
    final voiceEnabled =
        options.enableVoiceInstructions || options.voiceGuidanceOptions.enabled;
    if (!voiceEnabled) return null;
    final effectiveOptions =
        options.voiceGuidanceOptions.copyWith(enabled: true);
    return VoiceGuidance(effectiveOptions);
  }

  /// Current navigation state.
  NavigationState? get state => _state;

  /// Whether navigation is active.
  bool get isNavigating => _isNavigating;

  /// Current camera tracking mode.
  CameraTrackingMode get trackingMode => _currentTrackingMode;

  /// Current user location.
  LocationData? get currentLocation => _locationService.lastLocation;

  /// Starts navigation with the given route.
  Future<void> startNavigation(RouteResponse route) async {
    NavigationLogger.info('NavigationController', 'startNavigation called', {
      'routeDistance': route.distanceMeters,
      'routeDuration': route.durationSeconds,
      'stepsCount': route.steps?.length ?? 0,
    });

    if (_isNavigating) {
      stopNavigation();
    }

    final permissionsOk = await _ensureLocationPermissions();
    if (!permissionsOk) {
      NavigationLogger.warn(
          'NavigationController', 'Location permission not granted');
      _isNavigating = false;
      _state = null;
      notifyListeners();
      _notifyStateChanged();
      return;
    }

    _state = NavigationState.initial(route);
    _isNavigating = true;
    _currentTrackingMode = options.trackingMode;
    _confirmedStepIndex = 0;
    _distancePastStepBoundary = 0;
    _currentLegIndex = 0;
    _waypointsVisited = 0;

    NavigationLogger.info('NavigationController', 'State: idle -> navigating', {
      'routeDistance': route.distanceMeters,
      'totalLegs': _state!.totalLegs,
    });

    await _voiceGuidance?.initialize();
    _voiceGuidance?.updateCurrentStepIndex(0);

    // Speak initial step
    final initialStep = _state?.currentStep;
    if (initialStep != null) {
      await _voiceGuidance?.speakStep(initialStep, _state!.currentStepIndex);
      _logVoiceAnnouncement(
        type: 'INITIAL',
        text: initialStep.voiceInstruction ?? initialStep.instruction,
        stepIndex: _state!.currentStepIndex,
      );
    }

    // Setup LocationService recovery callbacks
    _locationService.onStreamProblem = _onLocationStreamProblem;
    _locationService.onStreamRecovered = _onLocationStreamRecovered;

    await _locationService.startTracking(
      LocationSettings.navigation(),
      LocationFilterSettings.navigation(),
    );

    _setupLocationSubscription();

    notifyListeners();
    _notifyStateChanged();
  }

  /// Stops navigation.
  void stopNavigation() {
    NavigationLogger.info(
        'NavigationController', 'State: navigating -> stopped');
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _autoRecenterTimer?.cancel();
    _autoRecenterTimer = null;
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    _subscriptionRecoveryAttempts = 0;
    _locationService.onStreamProblem = null;
    _locationService.onStreamRecovered = null;
    _locationService.stopTracking();
    _voiceGuidance?.reset();
    _isNavigating = false;
    _state = null;
    notifyListeners();
  }

  /// Sets the camera tracking mode.
  void setTrackingMode(CameraTrackingMode mode) {
    NavigationLogger.debug('NavigationController', 'Tracking mode changed', {
      'from': _currentTrackingMode.name,
      'to': mode.name,
    });
    _currentTrackingMode = mode;
    _autoRecenterTimer?.cancel();
    _autoRecenterTimer = null;
    notifyListeners();
  }

  /// Temporarily disables tracking (e.g., when user pans the map).
  void pauseTracking() {
    final wasAlreadyFree = _currentTrackingMode == CameraTrackingMode.free;
    _currentTrackingMode = CameraTrackingMode.free;

    _autoRecenterTimer?.cancel();
    _autoRecenterTimer = Timer(
      Duration(seconds: options.autoRecenterDelaySeconds),
      _resumeTracking,
    );

    if (!wasAlreadyFree) {
      NavigationLogger.debug(
          'NavigationController', 'Tracking paused, auto-recenter scheduled', {
        'delaySeconds': options.autoRecenterDelaySeconds,
      });
      notifyListeners();
    }
  }

  void _resumeTracking() {
    NavigationLogger.debug('NavigationController', 'Auto-recenter triggered');
    _currentTrackingMode = options.trackingMode;
    _autoRecenterTimer = null;
    notifyListeners();
    onResumeTracking?.call();
  }

  /// Recenters the camera on the user.
  void recenter() {
    _currentTrackingMode = options.trackingMode;
    _autoRecenterTimer?.cancel();
    _autoRecenterTimer = null;
    notifyListeners();
  }

  /// Notifies the controller that a new route has been set (e.g., after reroute).
  void notifyNewRoute() {
    NavigationLogger.info('NavigationController', 'New route notification');
    _voiceGuidance?.onNewRoute();
  }

  /// Manually triggers arrival - speaks arrival message and ends navigation.
  /// Use this when you want to force arrival regardless of distance conditions.
  void triggerArrival() {
    if (!_isNavigating || _state == null) {
      NavigationLogger.warn('NavigationController', 'triggerArrival called but not navigating');
      return;
    }

    NavigationLogger.info('NavigationController', 'Manual arrival triggered');
    _state = _state!.copyWith(hasArrived: true);
    notifyListeners();
    _handleArrival();
  }

  /// Handles arrival: stops current speech, speaks arrival message, waits for completion, then triggers callback.
  Future<void> _handleArrival() async {
    NavigationLogger.info('NavigationController', 'Handling arrival...', {
      'hasVoiceGuidance': _voiceGuidance != null,
      'hasOnArrivalCallback': onArrival != null,
    });

    try {
      // Stop any current speech and clear queue
      if (_voiceGuidance != null) {
        await _voiceGuidance!.stopAndClear();
        NavigationLogger.info('NavigationController', 'Voice queue cleared');

        // Speak arrival and wait for it to complete
        NavigationLogger.info('NavigationController', 'Speaking arrival message...');
        await _voiceGuidance!.speakArrival();
        NavigationLogger.info('NavigationController', 'Arrival message completed');
      }
    } catch (e, stack) {
      NavigationLogger.error('NavigationController', 'Error in _handleArrival voice', e, stack);
    }

    // Always trigger callback, even if voice failed
    NavigationLogger.info('NavigationController', 'Triggering onArrival callback');
    if (onArrival != null) {
      onArrival!.call();
      NavigationLogger.info('NavigationController', 'onArrival callback executed');
    } else {
      NavigationLogger.warn('NavigationController', 'onArrival callback is null!');
    }
  }

  /// Updates the current route without fully restarting navigation.
  Future<void> updateRoute(RouteResponse newRoute) async {
    if (!_isNavigating || _state == null) {
      NavigationLogger.warn(
          'NavigationController', 'updateRoute called but navigation inactive');
      return;
    }

    NavigationLogger.info('NavigationController', 'Updating route', {
      'oldDistance': _state!.route.distanceMeters,
      'newDistance': newRoute.distanceMeters,
      'newSteps': newRoute.steps?.length ?? 0,
    });

    _confirmedStepIndex = 0;
    _distancePastStepBoundary = 0;

    _state = NavigationState.initial(newRoute).copyWith(
      currentLocation: _state!.currentLocation,
      isOffRoute: false,
    );

    _voiceGuidance?.onNewRoute();
    _voiceGuidance?.updateCurrentStepIndex(0);

    final firstStep =
        newRoute.steps?.isNotEmpty == true ? newRoute.steps!.first : null;
    if (firstStep != null) {
      final textToSpeak = firstStep.instruction;
      await _voiceGuidance?.speakStep(firstStep, 0, overrideText: textToSpeak);
      _logVoiceAnnouncement(type: 'REROUTE', text: textToSpeak, stepIndex: 0);
    }

    notifyListeners();
    _notifyStateChanged();
  }

  // ---------------------------------------------------------------------------
  // Location handling
  // ---------------------------------------------------------------------------

  void _setupLocationSubscription() {
    _locationSubscription?.cancel();
    NavigationLogger.info(
        'NavigationController', 'Setting up location subscription');
    _locationSubscription = _locationService.locationStream.listen(
      _onLocationUpdate,
      onError: (error, stackTrace) {
        NavigationLogger.error(
            'NavigationController', 'Location stream error', error, stackTrace);
        _scheduleRecovery('Stream error: $error');
      },
      onDone: () {
        NavigationLogger.warn(
            'NavigationController', 'Location stream closed');
        if (_isNavigating) {
          _scheduleRecovery('Stream closed unexpectedly');
        }
      },
    );
  }

  void _onLocationStreamProblem(String reason) {
    NavigationLogger.warn(
        'NavigationController', 'Location stream problem', {'reason': reason});
  }

  void _onLocationStreamRecovered() {
    NavigationLogger.info(
        'NavigationController', 'Location stream recovered');
    _subscriptionRecoveryAttempts = 0;
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    if (_isNavigating) {
      _setupLocationSubscription();
    }
  }

  void _scheduleRecovery(String reason) {
    if (!_isNavigating) return;
    if (_subscriptionRecoveryAttempts >= _maxRecoveryAttempts) {
      NavigationLogger.error(
          'NavigationController', 'Max recovery attempts reached', null, null);
      return;
    }

    _recoveryTimer?.cancel();
    _subscriptionRecoveryAttempts++;

    final delaySeconds = 2 << (_subscriptionRecoveryAttempts - 1);
    NavigationLogger.info('NavigationController', 'Scheduling recovery', {
      'attempt': _subscriptionRecoveryAttempts,
      'delaySeconds': delaySeconds,
      'reason': reason,
    });

    _recoveryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_isNavigating) _attemptRecovery();
    });
  }

  Future<void> _attemptRecovery() async {
    if (!_isNavigating) return;
    NavigationLogger.info('NavigationController', 'Attempting recovery', {
      'attempt': _subscriptionRecoveryAttempts,
    });

    try {
      _locationService.stopTracking();
      await Future.delayed(const Duration(milliseconds: 500));
      await _locationService.startTracking(
        LocationSettings.navigation(),
        LocationFilterSettings.navigation(),
      );
      _setupLocationSubscription();
      _subscriptionRecoveryAttempts = 0;
      NavigationLogger.info('NavigationController', 'Recovery successful');
    } catch (e, stack) {
      NavigationLogger.error(
          'NavigationController', 'Recovery failed', e, stack);
      _scheduleRecovery('Recovery failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Core navigation logic
  // ---------------------------------------------------------------------------

  void _onLocationUpdate(LocationData location) {
    if (_state == null || !_isNavigating) return;

    _subscriptionRecoveryAttempts = 0;

    final route = _state!.route;
    final polyline = route.decodedPolyline;
    if (polyline == null || polyline.isEmpty) return;

    // Find closest point on route
    final (closestPoint, closestIndex, distanceToRoute) =
        _findClosestPointOnRoute(location.coordinates, polyline);

    // Off-route detection
    final speed = location.speed ?? 0;
    final isMoving = speed > options.minSpeedForOffRoute;
    final isOffRoute = isMoving && distanceToRoute > options.offRouteThreshold;
    final wasOffRoute = _state!.isOffRoute;

    // Log off-route check every 3 seconds to help diagnose reroute issues
    final now = DateTime.now();
    if (_lastOffRouteLogTime == null ||
        now.difference(_lastOffRouteLogTime!).inSeconds >= 3) {
      _lastOffRouteLogTime = now;
      NavigationLogger.info('NavigationController', 'Off-route check', {
        'distanceToRoute': distanceToRoute.toStringAsFixed(1),
        'offRouteThreshold': options.offRouteThreshold,
        'speed': speed.toStringAsFixed(2),
        'minSpeedForOffRoute': options.minSpeedForOffRoute,
        'isMoving': isMoving,
        'isOffRoute': isOffRoute,
      });
    }

    if (isOffRoute && !wasOffRoute) {
      NavigationLogger.warn('NavigationController', 'Off-route detected', {
        'distance': distanceToRoute,
        'threshold': options.offRouteThreshold,
        'speed': speed,
      });
      onOffRoute?.call();
      _voiceGuidance?.speakOffRoute();
    } else if (!isOffRoute && wasOffRoute) {
      NavigationLogger.info('NavigationController', 'Returned to route');
      _voiceGuidance?.onRouteStatusChanged(true);
    }

    // Calculate progress
    final (distanceCovered, distanceRemaining) =
        _calculateRouteProgress(closestIndex, closestPoint, polyline, route.distanceMeters);
    final progress = distanceCovered / route.distanceMeters;

    // Step detection with hysteresis
    final steps = route.steps ?? [];
    final (rawStepIndex, distanceToManeuver) =
        _getCurrentStep(distanceCovered, steps);
    final confirmedStepIndex =
        _applyStepHysteresis(rawStepIndex, distanceCovered, steps);

    // Multi-waypoint: detect leg transitions
    final currentStep =
        confirmedStepIndex < steps.length ? steps[confirmedStepIndex] : null;
    final stepLegIndex = currentStep?.legIndex ?? 0;

    if (stepLegIndex > _currentLegIndex) {
      _currentLegIndex = stepLegIndex;
      _waypointsVisited++;
      NavigationLogger.info(
          'NavigationController', 'Waypoint ${ _waypointsVisited} reached', {
        'legIndex': _currentLegIndex,
        'waypointsVisited': _waypointsVisited,
      });

      // Find waypoint coordinates (last point of previous leg in polyline)
      if (closestIndex < polyline.length) {
        onWaypointArrival?.call(_waypointsVisited - 1, closestPoint);
      }
    }

    // Calculate next waypoint distance for multi-waypoint routes
    double nextWaypointDistance = 0;
    final totalLegs = _state!.totalLegs;
    if (totalLegs > 1 && _currentLegIndex < totalLegs - 1) {
      // Sum remaining distance in current leg steps
      double legDistanceRemaining = 0;
      for (int i = confirmedStepIndex; i < steps.length; i++) {
        if ((steps[i].legIndex ?? 0) != _currentLegIndex) break;
        legDistanceRemaining += steps[i].distanceMeters;
      }
      // Subtract already-traveled portion of current step
      if (confirmedStepIndex < steps.length) {
        legDistanceRemaining -= (steps[confirmedStepIndex].distanceMeters - distanceToManeuver);
      }
      nextWaypointDistance = legDistanceRemaining.clamp(0, double.infinity);
    }

    // Arrival check - multiple conditions for robust detection
    final totalSteps = steps.length;
    final isLastStep = rawStepIndex >= totalSteps - 1;
    final isWithinArrivalThreshold = distanceRemaining < options.arrivalThreshold;

    // Extended arrival: on penultimate step, close to destination, and stopped
    // This handles GPS inaccuracy when user has physically arrived
    final isPenultimateStep = rawStepIndex == totalSteps - 2;
    final isNearDestination = distanceRemaining < 50.0; // Extended radius
    final isStopped = speed < 1.0;
    final extendedArrival = isPenultimateStep && isNearDestination && isStopped;

    final hasArrived = isLastStep || isWithinArrivalThreshold || extendedArrival;

    if (hasArrived && !_state!.hasArrived) {
      NavigationLogger.info('NavigationController', '=== ARRIVAL DETECTED ===', {
        'stepIndex': rawStepIndex,
        'totalSteps': totalSteps,
        'isLastStep': isLastStep,
      });

      // Mark as arrived immediately to prevent duplicate triggers
      _state = _state!.copyWith(hasArrived: true);
      notifyListeners();
      _notifyStateChanged();

      // Speak arrival and trigger callback
      NavigationLogger.info('NavigationController', 'Calling _handleArrival()');
      _handleArrival();

      return;
    }

    // Get step details
    RouteStep? nextStep;
    if (currentStep != null && confirmedStepIndex + 1 < steps.length) {
      nextStep = steps[confirmedStepIndex + 1];
    }

    // Step change detection and voice guidance
    final stepJustChanged = confirmedStepIndex != _state!.currentStepIndex;
    if (stepJustChanged) {
      _voiceGuidance?.updateCurrentStepIndex(confirmedStepIndex);
    }

    // Skip voice instructions for last step - arrival message will be spoken instead
    if (stepJustChanged && currentStep != null && !isLastStep) {
      NavigationLogger.info('NavigationController',
          'Step ${_state!.currentStepIndex} -> $confirmedStepIndex: ${currentStep.instruction}');
      onStepChanged?.call(currentStep);

      if (_voiceGuidance != null) {
        final transitionText =
            currentStep.voiceInstruction ?? currentStep.instruction;
        final capturedIdx = confirmedStepIndex;
        _voiceGuidance!
            .speakUpcomingStep(currentStep, confirmedStepIndex)
            .then((spoken) {
          if (spoken) {
            _logVoiceAnnouncement(
                type: 'STEP_TRANSITION',
                text: transitionText,
                stepIndex: capturedIdx);
          }
        });
      }
    }

    // Proactive voice: UPCOMING (~250m) and SHORT (~30m)
    // Skip for last step - arrival message will be spoken instead
    if (!stepJustChanged && currentStep != null && _voiceGuidance != null && !isLastStep) {
      final upcomingThreshold = options.upcomingInstructionThreshold;
      final shortThreshold =
          options.voiceGuidanceOptions.shortInstructionThreshold;

      if (distanceToManeuver <= upcomingThreshold &&
          distanceToManeuver > shortThreshold) {
        final text = currentStep.voiceInstruction ?? currentStep.instruction;
        final idx = confirmedStepIndex;
        _voiceGuidance!
            .speakUpcomingStep(currentStep, confirmedStepIndex)
            .then((spoken) {
          if (spoken) {
            _logVoiceAnnouncement(
                type: 'UPCOMING', text: text, stepIndex: idx);
          }
        });
      } else if (distanceToManeuver <= shortThreshold &&
          distanceToManeuver > 0) {
        final text =
            currentStep.voiceInstructionShort ?? currentStep.instruction;
        final idx = confirmedStepIndex;
        _voiceGuidance!
            .speakShortInstruction(currentStep, confirmedStepIndex)
            .then((spoken) {
          if (spoken) {
            _logVoiceAnnouncement(type: 'SHORT', text: text, stepIndex: idx);
          }
        });
      }
    }

    // Calculate ETA
    const minSpeedForEta = 1.0;
    final routeAvgSpeed = route.durationSeconds > 0
        ? route.distanceMeters / route.durationSeconds
        : 10.0;
    final effectiveSpeed = speed > minSpeedForEta ? speed : routeAvgSpeed;
    final durationRemaining = (distanceRemaining / effectiveSpeed).round();
    final eta = DateTime.now().add(Duration(seconds: durationRemaining));

    // Update state
    _state = _state!.copyWith(
      currentLocation: location,
      currentStepIndex: confirmedStepIndex,
      currentStep: currentStep,
      nextStep: nextStep,
      distanceToNextManeuver: distanceToManeuver,
      distanceRemaining: distanceRemaining,
      durationRemaining: durationRemaining,
      estimatedArrival: eta,
      currentSpeed: speed,
      isOffRoute: isOffRoute,
      hasArrived: hasArrived,
      progress: progress.clamp(0.0, 1.0),
      closestRouteIndex: closestIndex,
      closestRoutePoint: closestPoint,
      currentLegIndex: _currentLegIndex,
      waypointsVisited: _waypointsVisited,
      nextWaypointDistance: nextWaypointDistance,
    );

    notifyListeners();
    _notifyStateChanged();
  }

  // ---------------------------------------------------------------------------
  // Route geometry helpers
  // ---------------------------------------------------------------------------

  (Coordinates, int, double) _findClosestPointOnRoute(
    Coordinates location,
    List<Coordinates> polyline,
  ) {
    double minDistance = double.infinity;
    int closestIndex = 0;
    Coordinates closestPoint = polyline.first;

    for (int i = 0; i < polyline.length - 1; i++) {
      final (point, distance) =
          _closestPointOnSegment(location, polyline[i], polyline[i + 1]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
        closestPoint = point;
      }
    }

    return (closestPoint, closestIndex, minDistance);
  }

  (Coordinates, double) _closestPointOnSegment(
    Coordinates point,
    Coordinates segStart,
    Coordinates segEnd,
  ) {
    final dx = segEnd.lon - segStart.lon;
    final dy = segEnd.lat - segStart.lat;

    if (dx == 0 && dy == 0) {
      return (segStart, point.distanceTo(segStart));
    }

    final t =
        ((point.lon - segStart.lon) * dx + (point.lat - segStart.lat) * dy) /
            (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);

    final closest = Coordinates(
      lat: segStart.lat + clampedT * dy,
      lon: segStart.lon + clampedT * dx,
    );

    return (closest, point.distanceTo(closest));
  }

  (double, double) _calculateRouteProgress(
    int closestIndex,
    Coordinates closestPoint,
    List<Coordinates> polyline,
    int totalDistance,
  ) {
    double distanceCovered = 0;

    for (int i = 0; i < closestIndex; i++) {
      distanceCovered += polyline[i].distanceTo(polyline[i + 1]);
    }

    if (closestIndex < polyline.length) {
      distanceCovered += polyline[closestIndex].distanceTo(closestPoint);
    }

    final distanceRemaining = totalDistance - distanceCovered;
    return (distanceCovered, distanceRemaining.clamp(0, totalDistance.toDouble()));
  }

  (int, double) _getCurrentStep(double distanceCovered, List<RouteStep> steps) {
    if (steps.isEmpty) return (0, 0);

    double accumulated = 0;
    for (int i = 0; i < steps.length; i++) {
      accumulated += steps[i].distanceMeters;
      if (accumulated > distanceCovered) {
        return (i, accumulated - distanceCovered);
      }
    }

    return (steps.length - 1, 0);
  }

  int _applyStepHysteresis(
    int rawStepIndex,
    double distanceCovered,
    List<RouteStep> steps,
  ) {
    // Never go backward
    if (rawStepIndex < _confirmedStepIndex) {
      return _confirmedStepIndex;
    }

    if (rawStepIndex == _confirmedStepIndex) {
      _distancePastStepBoundary = 0;
      return _confirmedStepIndex;
    }

    // Calculate boundary distance
    double boundaryDistance = 0;
    for (int i = 0; i <= _confirmedStepIndex && i < steps.length; i++) {
      boundaryDistance += steps[i].distanceMeters;
    }

    final distancePastBoundary = distanceCovered - boundaryDistance;

    if (distancePastBoundary >= options.stepTransitionHysteresis) {
      _confirmedStepIndex = rawStepIndex;
      _distancePastStepBoundary = distancePastBoundary;
    }

    return _confirmedStepIndex;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _notifyStateChanged() {
    if (_state != null) {
      onStateChanged?.call(_state!);
    }
  }

  void _logVoiceAnnouncement({
    required String type,
    required String text,
    required int stepIndex,
  }) {
    NavigationLogger.info('NavigationController', 'Voice: $type', {
      'text': text,
      'stepIndex': stepIndex,
    });
  }

  Future<bool> _ensureLocationPermissions() async {
    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await _locationService.checkPermission();
    if (permission == LocationPermissionStatus.denied) {
      permission = await _locationService.requestPermission();
    }

    return permission == LocationPermissionStatus.granted;
  }

  @override
  void dispose() {
    stopNavigation();
    _locationService.dispose();
    _voiceGuidance?.dispose();
    super.dispose();
  }
}
