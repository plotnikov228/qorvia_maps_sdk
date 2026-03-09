import 'package:flutter/material.dart';

import '../models/coordinates.dart';
import 'camera/camera_position.dart';
import 'ui/widget_builders.dart';
import 'user_location_style.dart';

/// Configuration options for the map.
class MapOptions {
  /// Initial center coordinates.
  final Coordinates initialCenter;

  /// Initial zoom level (0-22).
  final double initialZoom;

  /// Initial tilt angle in degrees (0-60).
  final double initialTilt;

  /// Initial bearing in degrees (0-360).
  final double initialBearing;

  /// Minimum zoom level.
  final double minZoom;

  /// Maximum zoom level.
  final double maxZoom;

  /// Map style URL.
  final String? styleUrl;

  /// Fallback style URLs, used if the primary style fails to load.
  final List<String> styleUrlFallbacks;

  /// Timeout for style loading before trying the next fallback.
  final Duration styleLoadTimeout;

  /// Whether to show compass button.
  final bool showCompass;

  /// Whether to show zoom controls.
  final bool showZoomControls;

  /// Whether to show attribution.
  final bool showAttribution;

  /// Whether to show user location (requires permission).
  final bool showUserLocation;

  /// Custom style for user location marker.
  ///
  /// When provided, replaces the default blue dot with a custom icon.
  /// The icon is loaded from Flutter assets and rotates based on heading.
  ///
  /// If null, the default MapLibre location indicator is used.
  ///
  /// Example:
  /// ```dart
  /// MapOptions(
  ///   showUserLocation: true,
  ///   userLocationStyle: UserLocationStyle(
  ///     iconAsset: 'assets/icons/car_arrow.png',
  ///     iconSize: 1.2,
  ///   ),
  /// )
  /// ```
  final UserLocationStyle? userLocationStyle;

  /// Whether rotation gestures are enabled.
  final bool rotateGesturesEnabled;

  /// Whether tilt gestures are enabled.
  final bool tiltGesturesEnabled;

  /// Whether zoom gestures are enabled.
  final bool zoomGesturesEnabled;

  /// Whether scroll/pan gestures are enabled.
  final bool scrollGesturesEnabled;

  /// Whether double-tap to zoom is enabled.
  final bool doubleTapZoomEnabled;

  /// Background color shown while the map is loading.
  ///
  /// This color is displayed as a placeholder until the map style is loaded,
  /// preventing the "flicker" effect during initialization.
  ///
  /// Defaults to a light gray (#F5F5F5) which matches typical map backgrounds.
  final Color backgroundColor;

  /// Duration of the crossfade animation when the map becomes ready.
  ///
  /// Set to [Duration.zero] to disable the animation.
  final Duration mapReadyAnimationDuration;

  /// Configuration for customizing map overlay widgets.
  ///
  /// Allows replacing default widgets with custom implementations,
  /// repositioning widgets, and toggling visibility.
  ///
  /// Example:
  /// ```dart
  /// MapOptions(
  ///   widgetsConfig: MapWidgetsConfig(
  ///     zoomControlsConfig: WidgetConfig(
  ///       alignment: Alignment.centerRight,
  ///       enabled: true,
  ///     ),
  ///     compassConfig: WidgetConfig(
  ///       alignment: Alignment.topRight,
  ///       enabled: true,
  ///     ),
  ///   ),
  /// )
  /// ```
  final MapWidgetsConfig widgetsConfig;

  const MapOptions({
    required this.initialCenter,
    this.initialZoom = 14,
    this.initialTilt = 0,
    this.initialBearing = 0,
    this.minZoom = 0,
    this.maxZoom = 22,
    this.styleUrl,
    this.styleUrlFallbacks = const [],
    this.styleLoadTimeout = const Duration(seconds: 8),
    this.showCompass = true,
    this.showZoomControls = false,
    this.showAttribution = false,
    this.showUserLocation = false,
    this.userLocationStyle,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.doubleTapZoomEnabled = true,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.mapReadyAnimationDuration = const Duration(milliseconds: 300),
    this.widgetsConfig = const MapWidgetsConfig(),
  });

  /// Creates initial camera position from these options.
  CameraPosition get initialCameraPosition => CameraPosition(
        center: initialCenter,
        zoom: initialZoom,
        tilt: initialTilt,
        bearing: initialBearing,
      );

  MapOptions copyWith({
    Coordinates? initialCenter,
    double? initialZoom,
    double? initialTilt,
    double? initialBearing,
    double? minZoom,
    double? maxZoom,
    String? styleUrl,
    List<String>? styleUrlFallbacks,
    Duration? styleLoadTimeout,
    bool? showCompass,
    bool? showZoomControls,
    bool? showAttribution,
    bool? showUserLocation,
    UserLocationStyle? userLocationStyle,
    bool? rotateGesturesEnabled,
    bool? tiltGesturesEnabled,
    bool? zoomGesturesEnabled,
    bool? scrollGesturesEnabled,
    bool? doubleTapZoomEnabled,
    Color? backgroundColor,
    Duration? mapReadyAnimationDuration,
    MapWidgetsConfig? widgetsConfig,
  }) {
    return MapOptions(
      initialCenter: initialCenter ?? this.initialCenter,
      initialZoom: initialZoom ?? this.initialZoom,
      initialTilt: initialTilt ?? this.initialTilt,
      initialBearing: initialBearing ?? this.initialBearing,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      styleUrl: styleUrl ?? this.styleUrl,
      styleUrlFallbacks: styleUrlFallbacks ?? this.styleUrlFallbacks,
      styleLoadTimeout: styleLoadTimeout ?? this.styleLoadTimeout,
      showCompass: showCompass ?? this.showCompass,
      showZoomControls: showZoomControls ?? this.showZoomControls,
      showAttribution: showAttribution ?? this.showAttribution,
      showUserLocation: showUserLocation ?? this.showUserLocation,
      userLocationStyle: userLocationStyle ?? this.userLocationStyle,
      rotateGesturesEnabled: rotateGesturesEnabled ?? this.rotateGesturesEnabled,
      tiltGesturesEnabled: tiltGesturesEnabled ?? this.tiltGesturesEnabled,
      zoomGesturesEnabled: zoomGesturesEnabled ?? this.zoomGesturesEnabled,
      scrollGesturesEnabled: scrollGesturesEnabled ?? this.scrollGesturesEnabled,
      doubleTapZoomEnabled: doubleTapZoomEnabled ?? this.doubleTapZoomEnabled,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      mapReadyAnimationDuration: mapReadyAnimationDuration ?? this.mapReadyAnimationDuration,
      widgetsConfig: widgetsConfig ?? this.widgetsConfig,
    );
  }
}

/// Default map style URLs.
abstract class MapStyles {
  /// OpenStreetMap standard style.
  static const String osm = 'https://demotiles.maplibre.org/style.json';

  /// OpenFreeMap Liberty style (free, no key).
  static const String openFreeMapLiberty =
      'https://tiles.openfreemap.org/styles/liberty';

  /// CARTO Dark Matter style (free, no key) - dark theme fallback.
  static const String cartoDarkMatter =
      'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';

  /// CARTO Positron style (free, no key).
  static const String cartoPositron =
      'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';

  /// Custom style URL builder for your tile server.
  static String custom(String baseUrl) => '$baseUrl/style.json';
}
