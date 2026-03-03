import 'package:flutter/material.dart';

import '../navigation_logger.dart';
import 'next_turn_panel.dart';
import 'speed_indicator.dart';
import 'widget_data.dart';

/// Configurable color theme for navigation widgets.
///
/// Allows customization of colors for turn panel and speed indicator
/// to match your app's design system.
///
/// Example:
/// ```dart
/// NavigationWidgetColors(
///   turnPanelBackground: Colors.blue.shade700,
///   turnPanelText: Colors.white,
///   speedBackground: Colors.white,
///   speedText: Colors.black87,
///   speedOverLimit: Colors.red,
///   speedLimitBorder: Colors.red,
/// )
/// ```
class NavigationWidgetColors {
  // === Turn Panel Colors ===

  /// Background color for the turn instruction panel.
  ///
  /// Default: Blue (#2979FF) - Yandex Navigator style.
  final Color turnPanelBackground;

  /// Text and icon color for the turn instruction panel.
  ///
  /// Default: White.
  final Color turnPanelText;

  // === Speed Indicator Colors ===

  /// Background color for the speed indicator.
  ///
  /// Default: White.
  final Color speedBackground;

  /// Text color for the speed indicator (normal speed).
  ///
  /// Default: Dark gray (#333333).
  final Color speedText;

  /// Text color when speed exceeds the limit.
  ///
  /// Default: Red (#E53935).
  final Color speedOverLimit;

  /// Border color for the speed limit circle.
  ///
  /// Default: Red (#E53935).
  final Color speedLimitBorder;

  const NavigationWidgetColors({
    this.turnPanelBackground = kDefaultTurnPanelBlue,
    this.turnPanelText = Colors.white,
    this.speedBackground = kDefaultSpeedBackgroundColor,
    this.speedText = kDefaultSpeedTextColor,
    this.speedOverLimit = kDefaultSpeedOverLimitColor,
    this.speedLimitBorder = kDefaultSpeedLimitBorderColor,
  });

  /// Creates a copy with modified properties.
  NavigationWidgetColors copyWith({
    Color? turnPanelBackground,
    Color? turnPanelText,
    Color? speedBackground,
    Color? speedText,
    Color? speedOverLimit,
    Color? speedLimitBorder,
  }) {
    return NavigationWidgetColors(
      turnPanelBackground: turnPanelBackground ?? this.turnPanelBackground,
      turnPanelText: turnPanelText ?? this.turnPanelText,
      speedBackground: speedBackground ?? this.speedBackground,
      speedText: speedText ?? this.speedText,
      speedOverLimit: speedOverLimit ?? this.speedOverLimit,
      speedLimitBorder: speedLimitBorder ?? this.speedLimitBorder,
    );
  }

  @override
  String toString() => 'NavigationWidgetColors('
      'turnBg: $turnPanelBackground, '
      'speedBg: $speedBackground)';
}

/// Builder function for speed indicator widget.
///
/// Receives [SpeedWidgetData] containing current speed and limit information.
/// Return your custom widget implementation.
///
/// Example:
/// ```dart
/// SpeedWidgetBuilder speedBuilder = (data) => Container(
///   padding: EdgeInsets.all(16),
///   decoration: BoxDecoration(
///     color: data.isOverLimit ? Colors.red : Colors.white,
///     borderRadius: BorderRadius.circular(8),
///   ),
///   child: Text('${data.currentSpeedKmh.round()} km/h'),
/// );
/// ```
typedef SpeedWidgetBuilder = Widget Function(SpeedWidgetData data);

/// Builder function for ETA panel widget.
///
/// Receives [EtaWidgetData] with remaining time/distance and [onClose] callback.
/// The [onClose] callback should be invoked when user wants to exit navigation.
///
/// Example:
/// ```dart
/// EtaWidgetBuilder etaBuilder = (data, onClose) => Row(
///   children: [
///     Text('ETA: ${data.formattedEta}'),
///     Text('${data.formattedDistance} left'),
///     IconButton(icon: Icon(Icons.close), onPressed: onClose),
///   ],
/// );
/// ```
typedef EtaWidgetBuilder = Widget Function(
    EtaWidgetData data, VoidCallback? onClose);

/// Builder function for turn instruction panel widget.
///
/// Receives [TurnWidgetData] with maneuver details and instruction text.
///
/// Example:
/// ```dart
/// TurnWidgetBuilder turnBuilder = (data) => Card(
///   child: ListTile(
///     leading: ManeuverIcon(type: data.maneuver),
///     title: Text(data.instruction),
///     subtitle: Text(data.formattedDistance),
///   ),
/// );
/// ```
typedef TurnWidgetBuilder = Widget Function(TurnWidgetData data);

/// Builder function for recenter button widget.
///
/// Receives [RecenterWidgetData] and [onPressed] callback to recenter camera.
/// Check [data.isVisible] to determine if button should be shown.
///
/// Example:
/// ```dart
/// RecenterWidgetBuilder recenterBuilder = (data, onPressed) => Visibility(
///   visible: data.isVisible,
///   child: FloatingActionButton(
///     mini: true,
///     onPressed: onPressed,
///     child: Icon(Icons.my_location),
///   ),
/// );
/// ```
typedef RecenterWidgetBuilder = Widget Function(
    RecenterWidgetData data, VoidCallback onPressed);

/// Configuration for widget positioning and visibility.
///
/// Controls where a widget appears on screen and whether it's shown at all.
/// Use [alignment] and [padding] for positioning, [enabled] to toggle visibility.
///
/// Example:
/// ```dart
/// WidgetConfig(
///   alignment: Alignment.bottomLeft,
///   padding: EdgeInsets.all(16),
///   enabled: true,
/// )
/// ```
class WidgetConfig {
  /// Alignment within the parent container.
  ///
  /// Defaults vary by widget type to match standard navigation app layouts.
  final Alignment alignment;

  /// Padding around the widget.
  ///
  /// Applied inside SafeArea to avoid system UI overlaps.
  final EdgeInsets padding;

  /// Whether the widget is enabled and should be displayed.
  ///
  /// When false, the widget is completely hidden.
  final bool enabled;

  const WidgetConfig({
    this.alignment = Alignment.center,
    this.padding = EdgeInsets.zero,
    this.enabled = true,
  });

  /// Creates a copy with modified properties.
  WidgetConfig copyWith({
    Alignment? alignment,
    EdgeInsets? padding,
    bool? enabled,
  }) {
    return WidgetConfig(
      alignment: alignment ?? this.alignment,
      padding: padding ?? this.padding,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  String toString() =>
      'WidgetConfig(alignment: $alignment, padding: $padding, enabled: $enabled)';
}

/// Configuration for all navigation UI widgets.
///
/// Allows customization of appearance, positioning, and behavior of
/// navigation overlay widgets. Each widget can be:
/// - Completely replaced with a custom builder
/// - Repositioned using alignment and padding
/// - Disabled by setting enabled: false
///
/// Example:
/// ```dart
/// NavigationWidgetsConfig(
///   // Custom speed widget
///   speedWidgetBuilder: (data) => MyCustomSpeedWidget(data),
///   speedWidgetConfig: WidgetConfig(
///     alignment: Alignment.bottomRight,
///     padding: EdgeInsets.all(16),
///   ),
///
///   // Disable ETA panel
///   etaWidgetConfig: WidgetConfig(enabled: false),
///
///   // Reposition turn panel
///   turnWidgetConfig: WidgetConfig(
///     alignment: Alignment.topCenter,
///     padding: EdgeInsets.only(top: 60),
///   ),
/// )
/// ```
class NavigationWidgetsConfig {
  // === Colors ===

  /// Color theme for navigation widgets.
  ///
  /// Applies to default widgets (NextTurnPanel, SpeedIndicator).
  /// Custom builders should use these colors for consistency.
  final NavigationWidgetColors colors;

  // === Speed Widget ===

  /// Custom builder for speed indicator widget.
  ///
  /// When null, the default [SpeedIndicator] widget is used.
  final SpeedWidgetBuilder? speedWidgetBuilder;

  /// Configuration for speed widget positioning.
  ///
  /// Default: top-right corner (Yandex Navigator style).
  final WidgetConfig speedWidgetConfig;

  // === ETA Widget ===

  /// Custom builder for ETA panel widget.
  ///
  /// When null, the default [CompactEtaPanel] widget is used.
  final EtaWidgetBuilder? etaWidgetBuilder;

  /// Configuration for ETA panel positioning.
  ///
  /// Default: bottom-center, full width.
  final WidgetConfig etaWidgetConfig;

  // === Turn Widget ===

  /// Custom builder for turn instruction panel widget.
  ///
  /// When null, the default [NextTurnPanel] widget is used.
  final TurnWidgetBuilder? turnWidgetBuilder;

  /// Configuration for turn panel positioning.
  ///
  /// Default: top-left corner (Yandex Navigator style).
  final WidgetConfig turnWidgetConfig;

  // === Recenter Widget ===

  /// Custom builder for recenter button widget.
  ///
  /// When null, the default [RecenterButton] widget is used.
  final RecenterWidgetBuilder? recenterWidgetBuilder;

  /// Configuration for recenter button positioning.
  ///
  /// Default: bottom-right with 16px padding, 120px from bottom.
  final WidgetConfig recenterWidgetConfig;

  const NavigationWidgetsConfig({
    // Colors
    this.colors = const NavigationWidgetColors(),
    // Speed - top-right corner (Yandex Navigator style)
    this.speedWidgetBuilder,
    this.speedWidgetConfig = const WidgetConfig(
      alignment: Alignment.topRight,
      padding: EdgeInsets.only(right: 16, top: 16),
      enabled: true,
    ),
    // ETA
    this.etaWidgetBuilder,
    this.etaWidgetConfig = const WidgetConfig(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.zero,
      enabled: true,
    ),
    // Turn - top-left corner (Yandex Navigator style)
    this.turnWidgetBuilder,
    this.turnWidgetConfig = const WidgetConfig(
      alignment: Alignment.topLeft,
      padding: EdgeInsets.only(left: 16, top: 16),
      enabled: true,
    ),
    // Recenter
    this.recenterWidgetBuilder,
    this.recenterWidgetConfig = const WidgetConfig(
      alignment: Alignment.bottomRight,
      padding: EdgeInsets.only(right: 16, bottom: 120),
      enabled: true,
    ),
  });

  /// Log the configuration at debug level.
  void logConfig() {
    NavigationLogger.debug('NavigationWidgetsConfig', 'Configuration', {
      'colors': colors.toString(),
      'speedEnabled': speedWidgetConfig.enabled,
      'speedAlignment': speedWidgetConfig.alignment.toString(),
      'speedCustomBuilder': speedWidgetBuilder != null,
      'etaEnabled': etaWidgetConfig.enabled,
      'etaCustomBuilder': etaWidgetBuilder != null,
      'turnEnabled': turnWidgetConfig.enabled,
      'turnAlignment': turnWidgetConfig.alignment.toString(),
      'turnCustomBuilder': turnWidgetBuilder != null,
      'recenterEnabled': recenterWidgetConfig.enabled,
      'recenterCustomBuilder': recenterWidgetBuilder != null,
    });
  }

  /// Creates a copy with modified properties.
  NavigationWidgetsConfig copyWith({
    NavigationWidgetColors? colors,
    SpeedWidgetBuilder? speedWidgetBuilder,
    WidgetConfig? speedWidgetConfig,
    EtaWidgetBuilder? etaWidgetBuilder,
    WidgetConfig? etaWidgetConfig,
    TurnWidgetBuilder? turnWidgetBuilder,
    WidgetConfig? turnWidgetConfig,
    RecenterWidgetBuilder? recenterWidgetBuilder,
    WidgetConfig? recenterWidgetConfig,
  }) {
    return NavigationWidgetsConfig(
      colors: colors ?? this.colors,
      speedWidgetBuilder: speedWidgetBuilder ?? this.speedWidgetBuilder,
      speedWidgetConfig: speedWidgetConfig ?? this.speedWidgetConfig,
      etaWidgetBuilder: etaWidgetBuilder ?? this.etaWidgetBuilder,
      etaWidgetConfig: etaWidgetConfig ?? this.etaWidgetConfig,
      turnWidgetBuilder: turnWidgetBuilder ?? this.turnWidgetBuilder,
      turnWidgetConfig: turnWidgetConfig ?? this.turnWidgetConfig,
      recenterWidgetBuilder:
          recenterWidgetBuilder ?? this.recenterWidgetBuilder,
      recenterWidgetConfig: recenterWidgetConfig ?? this.recenterWidgetConfig,
    );
  }

  @override
  String toString() => 'NavigationWidgetsConfig('
      'speed: ${speedWidgetConfig.enabled}, '
      'eta: ${etaWidgetConfig.enabled}, '
      'turn: ${turnWidgetConfig.enabled}, '
      'recenter: ${recenterWidgetConfig.enabled})';
}
