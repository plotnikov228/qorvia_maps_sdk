import 'package:flutter/material.dart';
import '../markers/marker_icon.dart';
import 'navigation_logger.dart';
import 'ui/widget_builders.dart';
import 'voice/voice_guidance.dart';

/// Camera tracking mode during navigation.
enum CameraTrackingMode {
  /// Camera doesn't follow user (free pan/zoom).
  free,

  /// Camera follows user position, north is up.
  follow,

  /// Camera follows user and rotates with bearing/heading.
  followWithBearing,
}

/// Options for navigation behavior and appearance.
class NavigationOptions {
  // === Camera Settings ===

  /// Camera tilt angle in degrees (0-60).
  final double tilt;

  /// Zoom level during navigation.
  final double zoom;

  /// Camera tracking mode.
  final CameraTrackingMode trackingMode;

  /// Duration for camera animations.
  final Duration cameraAnimationDuration;

  /// Offset of the user icon from center (0-1, where 0.5 is center).
  /// Lower values move the icon toward the bottom.
  final double userIconVerticalOffset;

  // === User Arrow Settings ===

  /// Style for the user direction arrow.
  final UserArrowStyle userArrowStyle;

  /// Cursor (user arrow) fill color override.
  final Color? cursorColor;

  /// Cursor (user arrow) border color override.
  final Color? cursorBorderColor;

  /// Route line color during navigation.
  final Color routeLineColor;

  /// Route line width during navigation.
  final double routeLineWidth;

  /// Route line opacity during navigation.
  final double routeLineOpacity;

  /// Whether to show accuracy circle around user.
  final bool showAccuracyCircle;

  /// Map symbol icon for user location (from style sprite).
  final String userLocationIconImage;

  /// Map symbol size for user location.
  final double userLocationIconSize;

  /// Map symbol color for user location (SDF icons only).
  final Color? userLocationIconColor;

  // === UI Settings ===

  /// Whether to show the next turn panel.
  final bool showNextTurnPanel;

  /// Whether to show the ETA/remaining distance panel.
  final bool showEtaPanel;

  /// Whether to show current speed indicator.
  final bool showSpeedIndicator;

  /// Whether to show the recenter button when in free mode.
  final bool showRecenterButton;

  // === Behavior Settings ===

  /// Distance threshold in meters to consider off-route.
  final double offRouteThreshold;

  /// Minimum speed (m/s) to consider off-route. User must be moving
  /// faster than this to trigger reroute. Prevents reroute when stationary.
  final double minSpeedForOffRoute;

  /// Distance in meters to trigger arrival.
  final double arrivalThreshold;

  /// Hysteresis distance in meters for step transitions.
  /// User must travel this distance past a step boundary before the step
  /// is confirmed as changed. Prevents rapid step flickering from GPS noise.
  /// Also prevents steps from going backward (step index can only increase).
  /// Default: 5m.
  final double stepTransitionHysteresis;

  /// Time in seconds before auto-returning to follow mode.
  final int autoRecenterDelaySeconds;

  /// Whether to automatically request reroute when off-route.
  final bool autoReroute;

  /// Whether to simulate location for testing.
  final bool simulateLocation;

  /// Simulation speed multiplier (1.0 = real speed).
  final double simulationSpeedMultiplier;

  /// Use compass heading when GNSS heading is unavailable.
  final bool useCompassHeading;

  /// Smooth compass heading changes (degrees per update).
  final double compassSmoothing;

  /// Use native MapLibre location tracking (smoother camera).
  final bool useNativeTracking;

  /// Max prediction time window for virtual position (ms).
  final int maxPredictMs;

  /// Max distance to predict ahead (meters).
  final double maxPredictDistanceMeters;

  /// Minimum speed (m/s) to enable prediction.
  final double minSpeedForPrediction;

  /// Heading change threshold to consider as a turn (degrees).
  final double turnAngleThresholdDeg;

  /// Heading rate threshold to consider as a turn (deg/sec).
  final double turnRateThresholdDegPerSec;

  /// Render delay for buffered smoothing (ms).
  final int renderDelayMs;

  /// Buffer window for smoothing (ms).
  final int bufferMaxMs;

  /// Minimum camera bearing smoothing factor (0-1).
  /// Higher values = more responsive but potentially jittery.
  /// Default: 0.08 (smooth rotation, reduced jitter).
  final double minBearingSmoothing;

  /// Maximum camera bearing smoothing factor (0-1).
  /// Higher values = more responsive but potentially jittery.
  /// Default: 0.15 (balanced responsiveness vs smoothness).
  final double maxBearingSmoothing;

  /// Camera look-ahead distance in meters.
  /// Places camera target slightly ahead of user in direction of travel.
  /// Set to 0 to disable look-ahead.
  final double cameraLookAheadMeters;

  /// Minimum speed (m/s) to enable camera look-ahead.
  /// Below this speed, look-ahead is disabled to prevent jitter when stationary.
  /// Look-ahead gradually increases between this value and 10 m/s using smoothstep.
  /// Default: 5.0 m/s (~18 km/h).
  final double cameraLookAheadMinSpeed;

  // === Camera Smoothing Settings ===

  /// Minimum alpha for position smoothing (0-1).
  /// Lower values = smoother but slower to respond.
  /// Default: 0.06 (very smooth).
  final double cameraPositionAlphaMin;

  /// Maximum alpha for position smoothing (0-1).
  /// Higher values = more responsive but potentially jittery.
  /// Default: 0.18 (balanced).
  final double cameraPositionAlphaMax;

  /// Dead zone for camera position in meters.
  /// Camera updates are skipped when position change is smaller than this.
  /// Prevents micro-jitter from GPS noise.
  /// Default: 0.3 meters.
  final double cameraDeadZoneMeters;

  /// Dead zone for camera bearing in degrees.
  /// Camera updates are skipped when bearing change is smaller than this.
  /// Prevents micro-rotation from heading noise.
  /// Default: 1.0 degrees.
  final double cameraDeadZoneDegrees;

  /// Enable speed-adaptive smoothing for position updates.
  /// When true, smoothing alpha increases with speed to reduce lag.
  /// Helps prevent "rubber-band" effect at high speeds (50+ km/h).
  /// Default: true.
  final bool speedSmoothingEnabled;

  /// Maximum bearing velocity at low speed (deg/sec).
  /// Limits how fast camera can rotate when moving slowly (< 5 m/s).
  /// Default: 30 deg/sec.
  final double cameraBearingMaxVelocityLowSpeed;

  /// Maximum bearing velocity at high speed (deg/sec).
  /// Limits how fast camera can rotate when moving fast (> 10 m/s).
  /// Default: 60 deg/sec.
  final double cameraBearingMaxVelocityHighSpeed;

  // === Position Buffering Settings ===

  /// Duration of position buffer in milliseconds.
  /// GPS positions are collected and blended over this time window.
  /// Higher values = smoother but more lag.
  /// Default: 100ms.
  final int positionBufferDurationMs;

  // === Bearing Prediction Settings ===

  /// Time ahead to predict bearing direction in milliseconds.
  /// Helps reduce rotation lag by anticipating where the user is heading.
  /// Default: 50ms.
  final int bearingPredictionMs;

  // === Micro-animation Settings ===

  /// Enable smooth 60 FPS camera mode.
  /// When enabled:
  /// - Camera throttle is disabled (updates every frame)
  /// - Micro-animation is used for each camera move
  /// - Route line updates more frequently
  /// This provides the smoothest animation but uses more battery.
  /// Default: false (30 FPS camera for battery savings).
  final bool smooth60FpsCamera;

  /// Duration of micro-animations for camera moves in milliseconds.
  /// Each frame animates the camera instead of instant moves.
  /// Default: 16ms (one frame at 60 FPS).
  final int cameraFrameAnimationMs;

  // === Spring Physics Settings ===

  /// Spring tension for arrow rotation animation.
  /// Higher values = faster/snappier spring response.
  /// Default: 150.
  final double arrowSpringTension;

  /// Spring friction for arrow rotation animation.
  /// Higher values = more damping, less oscillation.
  /// Default: 15 (critically damped).
  final double arrowSpringFriction;

  // === GPS Filter Settings ===

  /// Alpha for GPS position filter (0-1).
  /// Lower values = more filtering, smoother but more lag.
  /// Default: 0.3.
  final double gpsPositionFilterAlpha;

  /// Alpha for GPS heading filter (0-1).
  /// Lower values = more filtering, smoother but more lag.
  /// Default: 0.2.
  final double gpsHeadingFilterAlpha;

  // === Snap to Route Settings ===

  /// Whether to snap cursor to route line when on-route.
  /// When enabled, the cursor will "stick" to the route line
  /// for smoother visual movement.
  final bool snapToRouteEnabled;

  /// Distance threshold in meters for route snapping.
  /// When user is within this distance from route, cursor snaps to route.
  /// Should be less than [offRouteThreshold].
  final double snapToRouteThreshold;

  /// Distance threshold for exiting snap mode (hysteresis).
  /// Must be >= [snapToRouteThreshold] to prevent oscillation.
  /// Example: enter snap at 15m, exit at 20m prevents rapid state changes.
  final double snapExitThreshold;

  /// Duration in milliseconds for smooth transition when entering/leaving snap zone.
  /// Prevents abrupt jumps when crossing the snap threshold.
  /// Note: This is adaptive - reduced at high speeds for responsiveness.
  final int snapTransitionDurationMs;

  /// Threshold in degrees for considering user is moving against route direction.
  /// If angle between GPS heading and route bearing exceeds this value,
  /// route bearing is NOT used for camera/cursor rotation.
  /// Prevents camera spinning when reroute happens while driving opposite direction.
  final double headingMismatchThreshold;

  /// Cooldown in milliseconds before snap-to-route activates after a reroute.
  /// This delay allows GPS heading to stabilize before snapping to new route.
  /// Prevents immediate snap to wrong direction after reroute.
  final int rerouteSnapCooldownMs;

  // === Destination Reroute Settings ===

  /// Distance threshold in meters to destination for triggering reroute.
  /// If user is farther than this distance from the final route point,
  /// a reroute will be requested (once per destination).
  /// This handles cases where the route endpoint doesn't match the actual destination.
  final double destinationRerouteThreshold;

  /// Whether to prevent repeated reroute attempts when still far from destination.
  /// When true, only one reroute attempt is made per destination.
  /// This prevents infinite reroute loops when API returns similar routes.
  final bool preventRepeatedDestinationReroute;

  // === Voice Timing Settings ===

  /// Distance threshold in meters to trigger UPCOMING (full) voice instruction.
  /// When user is within this distance from the next maneuver,
  /// the full voice instruction will be spoken proactively.
  /// This announces the maneuver BEFORE the driver reaches it.
  /// Default: 250m (~15 seconds at 60 km/h).
  final double upcomingInstructionThreshold;

  // === Logging Settings ===

  /// Log level for navigation debugging.
  /// Set to [NavigationLogLevel.debug] for verbose tracing,
  /// [NavigationLogLevel.none] to disable logging entirely.
  final NavigationLogLevel logLevel;

  /// Whether voice instructions are enabled.
  final bool enableVoiceInstructions;

  /// Voice guidance options.
  final VoiceGuidanceOptions voiceGuidanceOptions;

  // === Motion Prediction Settings ===

  /// Enable kinematic (velocity + acceleration) position prediction.
  /// When true, uses physics-based prediction between GPS updates
  /// for smoother cursor movement at constant speeds.
  /// Default: true.
  final bool motionPredictionEnabled;

  /// Number of position samples to keep in prediction buffer.
  /// More samples = smoother velocity estimation but more lag.
  /// Typical values: 5-10 samples.
  /// Default: 8 samples.
  final int motionPredictionBufferSize;

  /// Maximum acceleration change (jerk) threshold in m/s³.
  /// Above this threshold, prediction becomes more conservative
  /// to handle sudden braking/acceleration scenarios.
  /// Default: 5.0 m/s³ (typical for car braking).
  final double maxJerkThreshold;

  /// Minimum prediction confidence to use predicted position.
  /// Below this, fallback to simple linear extrapolation.
  /// Range: 0.0 - 1.0.
  /// Default: 0.3.
  final double minPredictionConfidence;

  /// Prediction blend factor when correcting prediction errors.
  /// Higher = faster correction but potentially jerky.
  /// Lower = smoother but may lag behind actual position.
  /// Default: 0.15.
  final double predictionCorrectionAlpha;

  /// Speed threshold for high-speed mode optimization (m/s).
  /// Above this speed, use more aggressive prediction and higher alpha.
  /// Default: 15.0 m/s (~54 km/h).
  final double highSpeedThreshold;

  /// Auto-enable 60 FPS camera at high speeds.
  /// When true, automatically enables smooth60FpsCamera when
  /// speed exceeds [smooth60FpsSpeedThreshold] for 3+ seconds.
  /// Default: true (recommended for smooth high-speed navigation).
  final bool autoSmooth60FpsOnHighSpeed;

  /// Speed threshold for auto-enabling 60 FPS mode (m/s).
  /// Default: 13.9 m/s (~50 km/h).
  final double smooth60FpsSpeedThreshold;

  // === Widget Customization ===

  /// Configuration for customizing navigation UI widgets.
  ///
  /// Allows replacing default widgets with custom implementations,
  /// repositioning widgets, and toggling visibility.
  ///
  /// Example:
  /// ```dart
  /// NavigationOptions(
  ///   widgetsConfig: NavigationWidgetsConfig(
  ///     speedWidgetBuilder: (data) => MyCustomSpeed(data),
  ///     speedWidgetConfig: WidgetConfig(
  ///       alignment: Alignment.bottomRight,
  ///     ),
  ///   ),
  /// )
  /// ```
  final NavigationWidgetsConfig widgetsConfig;

  const NavigationOptions({
    // Camera — top-down heading-up by default
    this.tilt = 0,
    this.zoom = 17,
    this.trackingMode = CameraTrackingMode.followWithBearing,
    this.cameraAnimationDuration = const Duration(milliseconds: 500),
    this.userIconVerticalOffset = 0.7,
    // User arrow
    this.userArrowStyle = const UserArrowStyle(),
    this.cursorColor,
    this.cursorBorderColor,
    this.routeLineColor = const Color(0xFF6366F1),
    this.routeLineWidth = 6,
    this.routeLineOpacity = 0.8,
    this.showAccuracyCircle = true,
    this.userLocationIconImage = 'triangle-11',
    this.userLocationIconSize = 1.6,
    this.userLocationIconColor,
    // UI
    this.showNextTurnPanel = true,
    this.showEtaPanel = true,
    this.showSpeedIndicator = true,
    this.showRecenterButton = true,
    // Behavior
    this.offRouteThreshold = 30,
    this.minSpeedForOffRoute = 1.0,
    this.arrivalThreshold = 20,
    this.stepTransitionHysteresis = 5.0,
    this.autoRecenterDelaySeconds = 6,
    this.autoReroute = true,
    this.simulateLocation = false,
    this.simulationSpeedMultiplier = 1.0,
    this.useCompassHeading = true,
    this.compassSmoothing = 8,
    this.useNativeTracking = false,
    this.maxPredictMs = 1500,  // Allow longer prediction at high speeds
    this.maxPredictDistanceMeters = 28.0,  // ~1 second at 100 km/h for smooth highway navigation
    this.minSpeedForPrediction = 0.5,
    this.turnAngleThresholdDeg = 25,
    this.turnRateThresholdDegPerSec = 90,
    this.renderDelayMs = 150,
    this.bufferMaxMs = 2000,
    this.minBearingSmoothing = 0.08,  // Balanced for smooth rotation
    this.maxBearingSmoothing = 0.15,  // Higher for responsive turns at speed
    this.cameraLookAheadMeters = 5.0,
    this.cameraLookAheadMinSpeed = 5.0,  // Increased from 2.0 to reduce jitter at low speed
    // Camera smoothing defaults - tuned for smooth high-speed movement
    this.cameraPositionAlphaMin = 0.12,  // Higher min for faster response at high speeds
    this.cameraPositionAlphaMax = 0.28,  // Higher max for faster catching up to GPS
    this.cameraDeadZoneMeters = 0.15,  // Smaller dead zone for smoother micro-movements
    this.cameraDeadZoneDegrees = 0.5,  // Smaller for smoother rotation
    this.speedSmoothingEnabled = true,  // Enable speed-adaptive smoothing
    this.cameraBearingMaxVelocityLowSpeed = 30.0,  // Faster rotation at low speed
    this.cameraBearingMaxVelocityHighSpeed = 60.0,  // Higher cap for responsive high-speed turns
    // Position buffering
    this.positionBufferDurationMs = 100,
    // Bearing prediction
    this.bearingPredictionMs = 50,
    // Micro-animation / 60 FPS
    this.smooth60FpsCamera = true,  // Enable by default for smooth navigation
    this.cameraFrameAnimationMs = 16,
    // Spring physics
    this.arrowSpringTension = 150.0,
    this.arrowSpringFriction = 15.0,
    // GPS filter
    this.gpsPositionFilterAlpha = 0.3,
    this.gpsHeadingFilterAlpha = 0.2,
    this.snapToRouteEnabled = true,
    this.snapToRouteThreshold = 15.0,
    this.snapExitThreshold = 20.0,  // Hysteresis: enter at 15m, exit at 20m
    this.snapTransitionDurationMs = 200,
    this.headingMismatchThreshold = 90.0,
    this.rerouteSnapCooldownMs = 2000,
    this.destinationRerouteThreshold = 100.0,
    this.preventRepeatedDestinationReroute = true,
    this.upcomingInstructionThreshold = 250.0,
    this.logLevel = NavigationLogLevel.info,
    this.enableVoiceInstructions = false,
    this.voiceGuidanceOptions = const VoiceGuidanceOptions(),
    // Motion prediction
    this.motionPredictionEnabled = true,
    this.motionPredictionBufferSize = 8,
    this.maxJerkThreshold = 5.0,
    this.minPredictionConfidence = 0.3,
    this.predictionCorrectionAlpha = 0.15,
    this.highSpeedThreshold = 15.0,
    this.autoSmooth60FpsOnHighSpeed = true,
    this.smooth60FpsSpeedThreshold = 8.0,  // ~29 km/h - activate earlier for smoother city driving
    // Widget customization
    this.widgetsConfig = const NavigationWidgetsConfig(),
  });

  /// Creates options optimized for driving (top-down heading-up).
  factory NavigationOptions.driving() {
    return const NavigationOptions(
      tilt: 0,
      zoom: 17,
      trackingMode: CameraTrackingMode.followWithBearing,
      offRouteThreshold: 30,
      arrivalThreshold: 20,
    );
  }

  /// Creates options optimized for walking (top-down heading-up).
  factory NavigationOptions.walking() {
    return const NavigationOptions(
      tilt: 0,
      zoom: 18,
      trackingMode: CameraTrackingMode.followWithBearing,
      offRouteThreshold: 20,
      arrivalThreshold: 15,
    );
  }

  /// Creates options for testing with simulated location.
  factory NavigationOptions.simulation({double speedMultiplier = 2.0}) {
    return NavigationOptions(
      simulateLocation: true,
      simulationSpeedMultiplier: speedMultiplier,
    );
  }

  NavigationOptions copyWith({
    double? tilt,
    double? zoom,
    CameraTrackingMode? trackingMode,
    Duration? cameraAnimationDuration,
    double? userIconVerticalOffset,
    UserArrowStyle? userArrowStyle,
    bool? showAccuracyCircle,
    String? userLocationIconImage,
    double? userLocationIconSize,
    Color? userLocationIconColor,
    Color? cursorColor,
    Color? cursorBorderColor,
    Color? routeLineColor,
    double? routeLineWidth,
    double? routeLineOpacity,
    bool? showNextTurnPanel,
    bool? showEtaPanel,
    bool? showSpeedIndicator,
    bool? showRecenterButton,
    double? offRouteThreshold,
    double? arrivalThreshold,
    double? stepTransitionHysteresis,
    int? autoRecenterDelaySeconds,
    bool? autoReroute,
    bool? simulateLocation,
    double? simulationSpeedMultiplier,
    bool? useCompassHeading,
    double? compassSmoothing,
    bool? useNativeTracking,
    int? maxPredictMs,
    double? maxPredictDistanceMeters,
    double? minSpeedForPrediction,
    double? turnAngleThresholdDeg,
    double? turnRateThresholdDegPerSec,
    int? renderDelayMs,
    int? bufferMaxMs,
    double? minBearingSmoothing,
    double? maxBearingSmoothing,
    double? cameraLookAheadMeters,
    double? cameraLookAheadMinSpeed,
    double? cameraPositionAlphaMin,
    double? cameraPositionAlphaMax,
    double? cameraDeadZoneMeters,
    double? cameraDeadZoneDegrees,
    bool? speedSmoothingEnabled,
    double? cameraBearingMaxVelocityLowSpeed,
    double? cameraBearingMaxVelocityHighSpeed,
    int? positionBufferDurationMs,
    int? bearingPredictionMs,
    int? cameraFrameAnimationMs,
    double? arrowSpringTension,
    double? arrowSpringFriction,
    double? gpsPositionFilterAlpha,
    double? gpsHeadingFilterAlpha,
    bool? snapToRouteEnabled,
    double? snapToRouteThreshold,
    double? snapExitThreshold,
    int? snapTransitionDurationMs,
    double? headingMismatchThreshold,
    int? rerouteSnapCooldownMs,
    double? destinationRerouteThreshold,
    bool? preventRepeatedDestinationReroute,
    double? upcomingInstructionThreshold,
    NavigationLogLevel? logLevel,
    bool? enableVoiceInstructions,
    VoiceGuidanceOptions? voiceGuidanceOptions,
    NavigationWidgetsConfig? widgetsConfig,
    bool? smooth60FpsCamera,
    // Motion prediction
    bool? motionPredictionEnabled,
    int? motionPredictionBufferSize,
    double? maxJerkThreshold,
    double? minPredictionConfidence,
    double? predictionCorrectionAlpha,
    double? highSpeedThreshold,
    bool? autoSmooth60FpsOnHighSpeed,
    double? smooth60FpsSpeedThreshold,
  }) {
    return NavigationOptions(
      tilt: tilt ?? this.tilt,
      zoom: zoom ?? this.zoom,
      trackingMode: trackingMode ?? this.trackingMode,
      cameraAnimationDuration: cameraAnimationDuration ?? this.cameraAnimationDuration,
      userIconVerticalOffset: userIconVerticalOffset ?? this.userIconVerticalOffset,
      userArrowStyle: userArrowStyle ?? this.userArrowStyle,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorBorderColor: cursorBorderColor ?? this.cursorBorderColor,
      routeLineColor: routeLineColor ?? this.routeLineColor,
      routeLineWidth: routeLineWidth ?? this.routeLineWidth,
      routeLineOpacity: routeLineOpacity ?? this.routeLineOpacity,
      showAccuracyCircle: showAccuracyCircle ?? this.showAccuracyCircle,
      userLocationIconImage: userLocationIconImage ?? this.userLocationIconImage,
      userLocationIconSize: userLocationIconSize ?? this.userLocationIconSize,
      userLocationIconColor: userLocationIconColor ?? this.userLocationIconColor,
      showNextTurnPanel: showNextTurnPanel ?? this.showNextTurnPanel,
      showEtaPanel: showEtaPanel ?? this.showEtaPanel,
      showSpeedIndicator: showSpeedIndicator ?? this.showSpeedIndicator,
      showRecenterButton: showRecenterButton ?? this.showRecenterButton,
      offRouteThreshold: offRouteThreshold ?? this.offRouteThreshold,
      arrivalThreshold: arrivalThreshold ?? this.arrivalThreshold,
      stepTransitionHysteresis: stepTransitionHysteresis ?? this.stepTransitionHysteresis,
      autoRecenterDelaySeconds: autoRecenterDelaySeconds ?? this.autoRecenterDelaySeconds,
      autoReroute: autoReroute ?? this.autoReroute,
      simulateLocation: simulateLocation ?? this.simulateLocation,
      simulationSpeedMultiplier: simulationSpeedMultiplier ?? this.simulationSpeedMultiplier,
      useCompassHeading: useCompassHeading ?? this.useCompassHeading,
      compassSmoothing: compassSmoothing ?? this.compassSmoothing,
      useNativeTracking: useNativeTracking ?? this.useNativeTracking,
      maxPredictMs: maxPredictMs ?? this.maxPredictMs,
      maxPredictDistanceMeters:
          maxPredictDistanceMeters ?? this.maxPredictDistanceMeters,
      minSpeedForPrediction:
          minSpeedForPrediction ?? this.minSpeedForPrediction,
      turnAngleThresholdDeg:
          turnAngleThresholdDeg ?? this.turnAngleThresholdDeg,
      turnRateThresholdDegPerSec:
          turnRateThresholdDegPerSec ?? this.turnRateThresholdDegPerSec,
      renderDelayMs: renderDelayMs ?? this.renderDelayMs,
      bufferMaxMs: bufferMaxMs ?? this.bufferMaxMs,
      minBearingSmoothing: minBearingSmoothing ?? this.minBearingSmoothing,
      maxBearingSmoothing: maxBearingSmoothing ?? this.maxBearingSmoothing,
      cameraLookAheadMeters: cameraLookAheadMeters ?? this.cameraLookAheadMeters,
      cameraLookAheadMinSpeed: cameraLookAheadMinSpeed ?? this.cameraLookAheadMinSpeed,
      cameraPositionAlphaMin: cameraPositionAlphaMin ?? this.cameraPositionAlphaMin,
      cameraPositionAlphaMax: cameraPositionAlphaMax ?? this.cameraPositionAlphaMax,
      cameraDeadZoneMeters: cameraDeadZoneMeters ?? this.cameraDeadZoneMeters,
      cameraDeadZoneDegrees: cameraDeadZoneDegrees ?? this.cameraDeadZoneDegrees,
      speedSmoothingEnabled: speedSmoothingEnabled ?? this.speedSmoothingEnabled,
      cameraBearingMaxVelocityLowSpeed: cameraBearingMaxVelocityLowSpeed ?? this.cameraBearingMaxVelocityLowSpeed,
      cameraBearingMaxVelocityHighSpeed: cameraBearingMaxVelocityHighSpeed ?? this.cameraBearingMaxVelocityHighSpeed,
      positionBufferDurationMs: positionBufferDurationMs ?? this.positionBufferDurationMs,
      bearingPredictionMs: bearingPredictionMs ?? this.bearingPredictionMs,
      cameraFrameAnimationMs: cameraFrameAnimationMs ?? this.cameraFrameAnimationMs,
      arrowSpringTension: arrowSpringTension ?? this.arrowSpringTension,
      arrowSpringFriction: arrowSpringFriction ?? this.arrowSpringFriction,
      gpsPositionFilterAlpha: gpsPositionFilterAlpha ?? this.gpsPositionFilterAlpha,
      gpsHeadingFilterAlpha: gpsHeadingFilterAlpha ?? this.gpsHeadingFilterAlpha,
      snapToRouteEnabled: snapToRouteEnabled ?? this.snapToRouteEnabled,
      snapToRouteThreshold: snapToRouteThreshold ?? this.snapToRouteThreshold,
      snapExitThreshold: snapExitThreshold ?? this.snapExitThreshold,
      snapTransitionDurationMs: snapTransitionDurationMs ?? this.snapTransitionDurationMs,
      headingMismatchThreshold: headingMismatchThreshold ?? this.headingMismatchThreshold,
      rerouteSnapCooldownMs: rerouteSnapCooldownMs ?? this.rerouteSnapCooldownMs,
      destinationRerouteThreshold: destinationRerouteThreshold ?? this.destinationRerouteThreshold,
      preventRepeatedDestinationReroute: preventRepeatedDestinationReroute ?? this.preventRepeatedDestinationReroute,
      upcomingInstructionThreshold: upcomingInstructionThreshold ?? this.upcomingInstructionThreshold,
      logLevel: logLevel ?? this.logLevel,
      enableVoiceInstructions: enableVoiceInstructions ?? this.enableVoiceInstructions,
      voiceGuidanceOptions: voiceGuidanceOptions ?? this.voiceGuidanceOptions,
      widgetsConfig: widgetsConfig ?? this.widgetsConfig,
      smooth60FpsCamera: smooth60FpsCamera ?? this.smooth60FpsCamera,
      motionPredictionEnabled: motionPredictionEnabled ?? this.motionPredictionEnabled,
      motionPredictionBufferSize: motionPredictionBufferSize ?? this.motionPredictionBufferSize,
      maxJerkThreshold: maxJerkThreshold ?? this.maxJerkThreshold,
      minPredictionConfidence: minPredictionConfidence ?? this.minPredictionConfidence,
      predictionCorrectionAlpha: predictionCorrectionAlpha ?? this.predictionCorrectionAlpha,
      highSpeedThreshold: highSpeedThreshold ?? this.highSpeedThreshold,
      autoSmooth60FpsOnHighSpeed: autoSmooth60FpsOnHighSpeed ?? this.autoSmooth60FpsOnHighSpeed,
      smooth60FpsSpeedThreshold: smooth60FpsSpeedThreshold ?? this.smooth60FpsSpeedThreshold,
    );
  }
}

/// Style configuration for user direction arrow.
class UserArrowStyle {
  /// Icon for the arrow.
  final MarkerIcon? icon;

  /// Size of the arrow in pixels.
  final double size;

  /// Primary color of the arrow (Indigo 500).
  final Color color;

  /// Border/outline color.
  final Color borderColor;

  /// Whether to show pulsing animation.
  final bool showPulse;

  const UserArrowStyle({
    this.icon,
    this.size = 48,
    this.color = const Color(0xFF6366F1),
    this.borderColor = Colors.white,
    this.showPulse = true,
  });
}
