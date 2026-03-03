import '../../qorvia_maps_sdk.dart';

/// Current state of navigation.
class NavigationState {
  /// The route being navigated.
  final RouteResponse route;

  /// Current user location.
  final LocationData? currentLocation;

  /// Index of the current step.
  final int currentStepIndex;

  /// Current step instructions.
  final RouteStep? currentStep;

  /// Next step instructions.
  final RouteStep? nextStep;

  /// Distance to the next maneuver in meters.
  final double distanceToNextManeuver;

  /// Total remaining distance in meters.
  final double distanceRemaining;

  /// Total remaining duration in seconds.
  final int durationRemaining;

  /// Estimated time of arrival.
  final DateTime estimatedArrival;

  /// Current speed in m/s.
  final double currentSpeed;

  /// Whether the user is off the route.
  final bool isOffRoute;

  /// Whether navigation has arrived at destination.
  final bool hasArrived;

  /// Progress along the route (0.0 - 1.0).
  final double progress;

  /// Closest index on route polyline.
  final int closestRouteIndex;

  /// Closest point on route polyline.
  final Coordinates? closestRoutePoint;

  // === Multi-waypoint fields ===

  /// Current leg index in a multi-waypoint route (0-based).
  final int currentLegIndex;

  /// Total number of legs in the route.
  final int totalLegs;

  /// Distance to the next waypoint in meters.
  final double nextWaypointDistance;

  /// Name of the next waypoint, if available.
  final String? nextWaypointName;

  /// Number of waypoints already visited.
  final int waypointsVisited;

  const NavigationState({
    required this.route,
    this.currentLocation,
    required this.currentStepIndex,
    this.currentStep,
    this.nextStep,
    required this.distanceToNextManeuver,
    required this.distanceRemaining,
    required this.durationRemaining,
    required this.estimatedArrival,
    required this.currentSpeed,
    required this.isOffRoute,
    required this.hasArrived,
    required this.progress,
    required this.closestRouteIndex,
    this.closestRoutePoint,
    this.currentLegIndex = 0,
    this.totalLegs = 1,
    this.nextWaypointDistance = 0,
    this.nextWaypointName,
    this.waypointsVisited = 0,
  });

  /// Whether this is the last leg of a multi-waypoint route.
  bool get isLastLeg => currentLegIndex >= totalLegs - 1;

  /// Whether this is a multi-waypoint route.
  bool get isMultiWaypoint => totalLegs > 1;

  /// Creates initial navigation state.
  factory NavigationState.initial(RouteResponse route) {
    final steps = route.steps;
    final hasSteps = steps != null && steps.isNotEmpty;

    // Determine total legs from step legIndex values
    int totalLegs = 1;
    if (hasSteps) {
      final maxLegIndex = steps.fold<int>(
        0,
        (max, step) => (step.legIndex ?? 0) > max ? (step.legIndex ?? 0) : max,
      );
      totalLegs = maxLegIndex + 1;
    }

    return NavigationState(
      route: route,
      currentStepIndex: 0,
      currentStep: hasSteps ? steps.first : null,
      nextStep: hasSteps && steps.length > 1 ? steps[1] : null,
      distanceToNextManeuver:
          hasSteps ? steps.first.distanceMeters.toDouble() : 0,
      distanceRemaining: route.distanceMeters.toDouble(),
      durationRemaining: route.durationSeconds,
      estimatedArrival:
          DateTime.now().add(Duration(seconds: route.durationSeconds)),
      currentSpeed: 0,
      isOffRoute: false,
      hasArrived: false,
      progress: 0,
      closestRouteIndex: 0,
      closestRoutePoint: null,
      currentLegIndex: 0,
      totalLegs: totalLegs,
      nextWaypointDistance: 0,
      nextWaypointName: null,
      waypointsVisited: 0,
    );
  }

  /// Formatted distance to next maneuver.
  String get formattedDistanceToManeuver {
    if (distanceToNextManeuver >= 1000) {
      return '${(distanceToNextManeuver / 1000).toStringAsFixed(1)} км';
    }
    return '${distanceToNextManeuver.round()} м';
  }

  /// Formatted remaining distance.
  String get formattedDistanceRemaining {
    if (distanceRemaining >= 1000) {
      return '${(distanceRemaining / 1000).toStringAsFixed(1)} км';
    }
    return '${distanceRemaining.round()} м';
  }

  /// Formatted remaining duration.
  String get formattedDurationRemaining {
    if (durationRemaining >= 3600) {
      final hours = durationRemaining ~/ 3600;
      final minutes = (durationRemaining % 3600) ~/ 60;
      return '$hours ч $minutes мин';
    }
    return '${durationRemaining ~/ 60} мин';
  }

  /// Formatted ETA.
  String get formattedEta {
    final hour = estimatedArrival.hour.toString().padLeft(2, '0');
    final minute = estimatedArrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formatted current speed.
  String get formattedSpeed {
    final kmh = currentSpeed * 3.6;
    return '${kmh.round()} км/ч';
  }

  /// Formatted distance to next waypoint.
  String get formattedNextWaypointDistance {
    if (nextWaypointDistance >= 1000) {
      return '${(nextWaypointDistance / 1000).toStringAsFixed(1)} км';
    }
    return '${nextWaypointDistance.round()} м';
  }

  NavigationState copyWith({
    RouteResponse? route,
    LocationData? currentLocation,
    int? currentStepIndex,
    RouteStep? currentStep,
    RouteStep? nextStep,
    double? distanceToNextManeuver,
    double? distanceRemaining,
    int? durationRemaining,
    DateTime? estimatedArrival,
    double? currentSpeed,
    bool? isOffRoute,
    bool? hasArrived,
    double? progress,
    int? closestRouteIndex,
    Coordinates? closestRoutePoint,
    int? currentLegIndex,
    int? totalLegs,
    double? nextWaypointDistance,
    String? nextWaypointName,
    int? waypointsVisited,
  }) {
    return NavigationState(
      route: route ?? this.route,
      currentLocation: currentLocation ?? this.currentLocation,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentStep: currentStep ?? this.currentStep,
      nextStep: nextStep ?? this.nextStep,
      distanceToNextManeuver:
          distanceToNextManeuver ?? this.distanceToNextManeuver,
      distanceRemaining: distanceRemaining ?? this.distanceRemaining,
      durationRemaining: durationRemaining ?? this.durationRemaining,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      hasArrived: hasArrived ?? this.hasArrived,
      progress: progress ?? this.progress,
      closestRouteIndex: closestRouteIndex ?? this.closestRouteIndex,
      closestRoutePoint: closestRoutePoint ?? this.closestRoutePoint,
      currentLegIndex: currentLegIndex ?? this.currentLegIndex,
      totalLegs: totalLegs ?? this.totalLegs,
      nextWaypointDistance: nextWaypointDistance ?? this.nextWaypointDistance,
      nextWaypointName: nextWaypointName ?? this.nextWaypointName,
      waypointsVisited: waypointsVisited ?? this.waypointsVisited,
    );
  }
}

/// Reason for navigation ending.
enum NavigationEndReason {
  /// User arrived at destination.
  arrived,

  /// User manually cancelled navigation.
  cancelled,

  /// Navigation failed due to error.
  error,
}
