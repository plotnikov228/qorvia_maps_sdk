import '../../models/route/lane_info.dart';
import '../navigation_logger.dart';
import '../navigation_options.dart';
import '../navigation_state.dart';

/// Data for speed indicator widget.
///
/// Contains current speed, optional speed limit, and computed over-limit status.
/// Use with custom [SpeedWidgetBuilder] to create your own speed display.
///
/// Example:
/// ```dart
/// speedWidgetBuilder: (data) => Text(
///   '${data.currentSpeedKmh.round()} km/h',
///   style: TextStyle(
///     color: data.isOverLimit ? Colors.red : Colors.black,
///   ),
/// ),
/// ```
class SpeedWidgetData {
  /// Current speed in kilometers per hour.
  final double currentSpeedKmh;

  /// Speed limit on current road segment (km/h), if available.
  final double? speedLimit;

  /// Whether current speed exceeds the speed limit.
  final bool isOverLimit;

  const SpeedWidgetData({
    required this.currentSpeedKmh,
    this.speedLimit,
    required this.isOverLimit,
  });

  /// Creates [SpeedWidgetData] from navigation state.
  factory SpeedWidgetData.fromState(NavigationState state) {
    final speedKmh = state.currentSpeed * 3.6; // m/s to km/h
    final limit = state.currentStep?.speedLimit?.toDouble();
    final isOverLimit = limit != null && speedKmh > limit;

    NavigationLogger.debug('SpeedWidgetData', 'Created from state', {
      'speedKmh': speedKmh,
      'speedLimit': limit,
      'isOverLimit': isOverLimit,
    });

    if (limit != null && isOverLimit) {
      NavigationLogger.info('SpeedWidgetData', 'Speed limit exceeded', {
        'currentSpeed': speedKmh,
        'limit': limit,
        'overBy': speedKmh - limit,
      });
    }

    return SpeedWidgetData(
      currentSpeedKmh: speedKmh,
      speedLimit: limit,
      isOverLimit: isOverLimit,
    );
  }

  @override
  String toString() =>
      'SpeedWidgetData(speedKmh: ${currentSpeedKmh.toStringAsFixed(1)}, limit: $speedLimit, overLimit: $isOverLimit)';
}

/// Data for ETA (Estimated Time of Arrival) panel widget.
///
/// Contains formatted strings for display and raw values for calculations.
/// Use with custom [EtaWidgetBuilder] to create your own ETA display.
///
/// Example:
/// ```dart
/// etaWidgetBuilder: (data, onClose) => Column(
///   children: [
///     Text('Arriving at ${data.formattedEta}'),
///     Text('${data.formattedDistance} remaining'),
///     IconButton(icon: Icon(Icons.close), onPressed: onClose),
///   ],
/// ),
/// ```
class EtaWidgetData {
  /// Formatted ETA time (e.g., "14:35").
  final String formattedEta;

  /// Formatted remaining duration (e.g., "25 min" or "1 h 30 min").
  final String formattedDuration;

  /// Formatted remaining distance (e.g., "12.5 km" or "500 m").
  final String formattedDistance;

  /// Remaining duration as [Duration] for calculations.
  final Duration durationRemaining;

  /// Remaining distance in meters.
  final double distanceRemaining;

  /// Estimated arrival time as [DateTime].
  final DateTime estimatedArrival;

  /// Progress along the route (0.0 - 1.0).
  final double progress;

  const EtaWidgetData({
    required this.formattedEta,
    required this.formattedDuration,
    required this.formattedDistance,
    required this.durationRemaining,
    required this.distanceRemaining,
    required this.estimatedArrival,
    required this.progress,
  });

  /// Creates [EtaWidgetData] from navigation state.
  factory EtaWidgetData.fromState(NavigationState state) {
    NavigationLogger.debug('EtaWidgetData', 'Created from state', {
      'distanceRemaining': state.distanceRemaining,
      'durationRemaining': state.durationRemaining,
      'progress': state.progress,
    });

    return EtaWidgetData(
      formattedEta: state.formattedEta,
      formattedDuration: state.formattedDurationRemaining,
      formattedDistance: state.formattedDistanceRemaining,
      durationRemaining: Duration(seconds: state.durationRemaining),
      distanceRemaining: state.distanceRemaining,
      estimatedArrival: state.estimatedArrival,
      progress: state.progress,
    );
  }

  @override
  String toString() =>
      'EtaWidgetData(eta: $formattedEta, duration: $formattedDuration, distance: $formattedDistance)';
}

/// Data for turn instruction panel widget.
///
/// Contains current maneuver instruction, road name, distance to maneuver,
/// lane information, and traffic signal data.
/// Use with custom [TurnWidgetBuilder] to create your own turn panel.
///
/// Example:
/// ```dart
/// turnWidgetBuilder: (data) => Row(
///   children: [
///     ManeuverIcon(maneuver: data.maneuver),
///     Column(
///       children: [
///         Text(data.formattedDistance),
///         Text(data.instruction),
///         if (data.lanes.isNotEmpty)
///           LanesIndicator(lanes: data.lanes),
///       ],
///     ),
///   ],
/// ),
/// ```
class TurnWidgetData {
  /// Turn instruction text (e.g., "Turn right onto Main Street").
  final String instruction;

  /// Name of the road to turn onto, if available.
  final String? roadName;

  /// Maneuver type identifier (e.g., "turn-right", "uturn-left").
  final String maneuver;

  /// Formatted distance to maneuver (e.g., "250 m" or "1.2 km").
  final String formattedDistance;

  /// Distance to maneuver in meters.
  final double distanceToManeuver;

  /// Hint about the next maneuver after this one, if available.
  final String? nextManeuverHint;

  /// Whether there is a valid maneuver to display.
  final bool hasManeuver;

  /// Index of the current step in the route.
  final int stepIndex;

  /// Lane information for the current step.
  ///
  /// Empty list if lane data is not available.
  final List<LaneInfo> lanes;

  /// Whether there is a traffic signal at this step.
  ///
  /// Note: Only available from Valhalla routing engine.
  final bool hasTrafficSignal;

  /// Number of traffic signals at this step.
  ///
  /// Note: Only available from Valhalla routing engine.
  final int trafficSignalCount;

  const TurnWidgetData({
    required this.instruction,
    this.roadName,
    required this.maneuver,
    required this.formattedDistance,
    required this.distanceToManeuver,
    this.nextManeuverHint,
    required this.hasManeuver,
    required this.stepIndex,
    this.lanes = const [],
    this.hasTrafficSignal = false,
    this.trafficSignalCount = 0,
  });

  /// Creates [TurnWidgetData] from navigation state.
  factory TurnWidgetData.fromState(NavigationState state) {
    final step = state.currentStep;
    final hasManeuver = step != null;

    NavigationLogger.debug('TurnWidgetData', 'Created from state', {
      'hasManeuver': hasManeuver,
      'stepIndex': state.currentStepIndex,
      'maneuver': step?.maneuver,
      'distanceToManeuver': state.distanceToNextManeuver,
      'lanesCount': step?.lanes.length ?? 0,
      'hasTrafficSignal': step?.hasTrafficSignal ?? false,
    });

    return TurnWidgetData(
      instruction: step?.instruction ?? '',
      roadName: step?.name,
      maneuver: step?.maneuver ?? '',
      formattedDistance: state.formattedDistanceToManeuver,
      distanceToManeuver: state.distanceToNextManeuver,
      nextManeuverHint: step?.nextManeuverHint,
      hasManeuver: hasManeuver,
      stepIndex: state.currentStepIndex,
      lanes: step?.lanes ?? const [],
      hasTrafficSignal: step?.hasTrafficSignal ?? false,
      trafficSignalCount: step?.trafficSignalCount ?? 0,
    );
  }

  @override
  String toString() =>
      'TurnWidgetData(maneuver: $maneuver, distance: $formattedDistance, instruction: $instruction)';
}

/// Data for recenter button widget.
///
/// Contains current camera tracking mode and visibility state.
/// Use with custom [RecenterWidgetBuilder] to create your own recenter button.
///
/// Example:
/// ```dart
/// recenterWidgetBuilder: (data, onPressed) => Visibility(
///   visible: data.isVisible,
///   child: FloatingActionButton(
///     onPressed: onPressed,
///     child: Icon(Icons.my_location),
///   ),
/// ),
/// ```
class RecenterWidgetData {
  /// Current camera tracking mode.
  final CameraTrackingMode currentMode;

  /// Whether the button should be visible.
  ///
  /// Typically visible only when tracking mode is [CameraTrackingMode.free].
  final bool isVisible;

  const RecenterWidgetData({
    required this.currentMode,
    required this.isVisible,
  });

  /// Creates [RecenterWidgetData] from tracking mode.
  factory RecenterWidgetData.fromMode(CameraTrackingMode mode) {
    final isVisible = mode == CameraTrackingMode.free;

    NavigationLogger.debug('RecenterWidgetData', 'Created from mode', {
      'mode': mode.name,
      'isVisible': isVisible,
    });

    return RecenterWidgetData(
      currentMode: mode,
      isVisible: isVisible,
    );
  }

  @override
  String toString() =>
      'RecenterWidgetData(mode: ${currentMode.name}, visible: $isVisible)';
}

/// Data for map control widgets (zoom, compass, location button).
///
/// Contains current map state for building custom map controls.
/// Use with custom builders in [MapWidgetsConfig].
///
/// Example:
/// ```dart
/// zoomControlsBuilder: (data, onZoomIn, onZoomOut) => Column(
///   children: [
///     IconButton(
///       icon: Icon(Icons.add),
///       onPressed: data.currentZoom < 18 ? onZoomIn : null,
///     ),
///     Text('${data.currentZoom.round()}'),
///     IconButton(
///       icon: Icon(Icons.remove),
///       onPressed: data.currentZoom > 2 ? onZoomOut : null,
///     ),
///   ],
/// ),
/// ```
class MapControlsWidgetData {
  /// Current map zoom level.
  final double currentZoom;

  /// Current map bearing/rotation in degrees (0-360).
  final double currentBearing;

  /// Current map tilt in degrees.
  final double currentTilt;

  /// Whether user location layer is enabled.
  final bool isUserLocationEnabled;

  /// Whether user location is currently being tracked.
  final bool isTracking;

  /// Minimum allowed zoom level.
  final double minZoom;

  /// Maximum allowed zoom level.
  final double maxZoom;

  const MapControlsWidgetData({
    required this.currentZoom,
    required this.currentBearing,
    required this.currentTilt,
    required this.isUserLocationEnabled,
    required this.isTracking,
    this.minZoom = 0,
    this.maxZoom = 22,
  });

  /// Whether zoom in is allowed (not at max zoom).
  bool get canZoomIn => currentZoom < maxZoom;

  /// Whether zoom out is allowed (not at min zoom).
  bool get canZoomOut => currentZoom > minZoom;

  /// Whether compass should be visible (bearing is not north).
  bool get shouldShowCompass => currentBearing.abs() > 1;

  @override
  String toString() =>
      'MapControlsWidgetData(zoom: ${currentZoom.toStringAsFixed(1)}, bearing: ${currentBearing.toStringAsFixed(1)})';
}
