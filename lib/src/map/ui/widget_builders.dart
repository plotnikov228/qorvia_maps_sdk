import 'package:flutter/material.dart';

import '../../navigation/navigation_logger.dart';
import '../../navigation/ui/widget_builders.dart' show WidgetConfig;
import '../../navigation/ui/widget_data.dart';

// Re-export WidgetConfig for convenience
export '../../navigation/ui/widget_builders.dart' show WidgetConfig;

/// Builder function for zoom controls widget.
///
/// Receives [MapControlsWidgetData] and callbacks for zoom in/out.
/// Return your custom zoom controls implementation.
///
/// Example:
/// ```dart
/// ZoomControlsBuilder zoomBuilder = (data, onZoomIn, onZoomOut) => Column(
///   children: [
///     IconButton(
///       icon: Icon(Icons.add),
///       onPressed: data.canZoomIn ? onZoomIn : null,
///     ),
///     Text('${data.currentZoom.round()}'),
///     IconButton(
///       icon: Icon(Icons.remove),
///       onPressed: data.canZoomOut ? onZoomOut : null,
///     ),
///   ],
/// );
/// ```
typedef ZoomControlsBuilder = Widget Function(
  MapControlsWidgetData data,
  VoidCallback onZoomIn,
  VoidCallback onZoomOut,
);

/// Builder function for compass widget.
///
/// Receives current bearing and callback to reset to north.
/// Return your custom compass implementation.
///
/// Example:
/// ```dart
/// CompassBuilder compassBuilder = (bearing, onReset) => GestureDetector(
///   onTap: onReset,
///   child: Transform.rotate(
///     angle: -bearing * (pi / 180),
///     child: Icon(Icons.navigation),
///   ),
/// );
/// ```
typedef CompassBuilder = Widget Function(
  double bearing,
  VoidCallback onReset,
);

/// Builder function for scale bar widget.
///
/// Receives meters per pixel at current zoom and the zoom level.
/// Return your custom scale bar implementation.
///
/// Example:
/// ```dart
/// ScaleBuilder scaleBuilder = (metersPerPixel, zoom) {
///   final scaleWidth = 100.0;
///   final distance = scaleWidth * metersPerPixel;
///   return Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       Container(width: scaleWidth, height: 2, color: Colors.black),
///       Text('${distance.round()}m'),
///     ],
///   );
/// };
/// ```
typedef ScaleBuilder = Widget Function(
  double metersPerPixel,
  double zoom,
);

/// Builder function for user location button widget.
///
/// Receives tracking state and callback to toggle location tracking.
/// Return your custom location button implementation.
///
/// Example:
/// ```dart
/// UserLocationButtonBuilder locationBuilder = (isTracking, onToggle) =>
///   FloatingActionButton(
///     mini: true,
///     onPressed: onToggle,
///     backgroundColor: isTracking ? Colors.blue : Colors.white,
///     child: Icon(
///       isTracking ? Icons.my_location : Icons.location_searching,
///       color: isTracking ? Colors.white : Colors.grey,
///     ),
///   );
/// ```
typedef UserLocationButtonBuilder = Widget Function(
  bool isTracking,
  VoidCallback onToggle,
);

/// Configuration for all map control widgets.
///
/// Allows customization of appearance, positioning, and behavior of
/// map overlay widgets. Each widget can be:
/// - Completely replaced with a custom builder
/// - Repositioned using alignment and padding
/// - Disabled by setting enabled: false
///
/// Example:
/// ```dart
/// MapWidgetsConfig(
///   // Custom zoom controls
///   zoomControlsBuilder: (data, onZoomIn, onZoomOut) =>
///     MyCustomZoomControls(data, onZoomIn, onZoomOut),
///   zoomControlsConfig: WidgetConfig(
///     alignment: Alignment.centerRight,
///     padding: EdgeInsets.only(right: 16),
///   ),
///
///   // Disable compass
///   compassConfig: WidgetConfig(enabled: false),
///
///   // Reposition location button
///   userLocationButtonConfig: WidgetConfig(
///     alignment: Alignment.bottomRight,
///     padding: EdgeInsets.all(16),
///   ),
/// )
/// ```
class MapWidgetsConfig {
  // === Zoom Controls ===

  /// Custom builder for zoom controls widget.
  ///
  /// When null, the default [ZoomControls] widget is used.
  final ZoomControlsBuilder? zoomControlsBuilder;

  /// Configuration for zoom controls positioning.
  ///
  /// Default: center-right with 16px padding.
  final WidgetConfig zoomControlsConfig;

  // === Compass ===

  /// Custom builder for compass widget.
  ///
  /// When null, the default [MapCompass] widget is used.
  final CompassBuilder? compassBuilder;

  /// Configuration for compass positioning.
  ///
  /// Default: top-right with 16px padding.
  final WidgetConfig compassConfig;

  // === Scale Bar ===

  /// Custom builder for scale bar widget.
  ///
  /// When null, the default [MapScaleBar] widget is used.
  final ScaleBuilder? scaleBuilder;

  /// Configuration for scale bar positioning.
  ///
  /// Default: bottom-left with 16px padding.
  final WidgetConfig scaleConfig;

  // === User Location Button ===

  /// Custom builder for user location button widget.
  ///
  /// When null, the default [UserLocationButton] widget is used.
  final UserLocationButtonBuilder? userLocationButtonBuilder;

  /// Configuration for user location button positioning.
  ///
  /// Default: bottom-right with 16px padding.
  final WidgetConfig userLocationButtonConfig;

  const MapWidgetsConfig({
    // Zoom controls
    this.zoomControlsBuilder,
    this.zoomControlsConfig = const WidgetConfig(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 16),
      enabled: false, // Disabled by default, use native gestures
    ),
    // Compass
    this.compassBuilder,
    this.compassConfig = const WidgetConfig(
      alignment: Alignment.topRight,
      padding: EdgeInsets.only(top: 16, right: 16),
      enabled: false, // Disabled by default, MapLibre has native compass
    ),
    // Scale
    this.scaleBuilder,
    this.scaleConfig = const WidgetConfig(
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.only(left: 16, bottom: 24),
      enabled: false, // Disabled by default
    ),
    // User location button
    this.userLocationButtonBuilder,
    this.userLocationButtonConfig = const WidgetConfig(
      alignment: Alignment.bottomRight,
      padding: EdgeInsets.only(right: 16, bottom: 24),
      enabled: false, // Disabled by default
    ),
  });

  /// Log the configuration at debug level.
  void logConfig() {
    NavigationLogger.debug('MapWidgetsConfig', 'Configuration', {
      'zoomEnabled': zoomControlsConfig.enabled,
      'zoomCustomBuilder': zoomControlsBuilder != null,
      'compassEnabled': compassConfig.enabled,
      'compassCustomBuilder': compassBuilder != null,
      'scaleEnabled': scaleConfig.enabled,
      'scaleCustomBuilder': scaleBuilder != null,
      'locationButtonEnabled': userLocationButtonConfig.enabled,
      'locationButtonCustomBuilder': userLocationButtonBuilder != null,
    });
  }

  /// Creates a copy with modified properties.
  MapWidgetsConfig copyWith({
    ZoomControlsBuilder? zoomControlsBuilder,
    WidgetConfig? zoomControlsConfig,
    CompassBuilder? compassBuilder,
    WidgetConfig? compassConfig,
    ScaleBuilder? scaleBuilder,
    WidgetConfig? scaleConfig,
    UserLocationButtonBuilder? userLocationButtonBuilder,
    WidgetConfig? userLocationButtonConfig,
  }) {
    return MapWidgetsConfig(
      zoomControlsBuilder: zoomControlsBuilder ?? this.zoomControlsBuilder,
      zoomControlsConfig: zoomControlsConfig ?? this.zoomControlsConfig,
      compassBuilder: compassBuilder ?? this.compassBuilder,
      compassConfig: compassConfig ?? this.compassConfig,
      scaleBuilder: scaleBuilder ?? this.scaleBuilder,
      scaleConfig: scaleConfig ?? this.scaleConfig,
      userLocationButtonBuilder:
          userLocationButtonBuilder ?? this.userLocationButtonBuilder,
      userLocationButtonConfig:
          userLocationButtonConfig ?? this.userLocationButtonConfig,
    );
  }

  @override
  String toString() => 'MapWidgetsConfig('
      'zoom: ${zoomControlsConfig.enabled}, '
      'compass: ${compassConfig.enabled}, '
      'scale: ${scaleConfig.enabled}, '
      'location: ${userLocationButtonConfig.enabled})';
}
