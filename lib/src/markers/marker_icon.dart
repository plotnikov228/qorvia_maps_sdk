import 'package:flutter/material.dart';

/// Base class for marker icons.
abstract class MarkerIcon {
  const MarkerIcon();
}

/// SVG marker icon.
class SvgMarkerIcon extends MarkerIcon {
  /// Path to the SVG asset.
  final String assetPath;

  /// Size of the icon.
  final double size;

  /// Optional color to apply to the SVG.
  final Color? color;

  const SvgMarkerIcon(
    this.assetPath, {
    this.size = 32,
    this.color,
  });
}

/// Asset image marker icon (PNG, JPG, etc.).
class AssetMarkerIcon extends MarkerIcon {
  /// Path to the asset.
  final String assetPath;

  /// Width of the icon.
  final double width;

  /// Height of the icon.
  final double height;

  const AssetMarkerIcon(
    this.assetPath, {
    this.width = 32,
    this.height = 32,
  });
}

/// Network image marker icon.
class NetworkMarkerIcon extends MarkerIcon {
  /// URL of the image.
  final String url;

  /// Width of the icon.
  final double width;

  /// Height of the icon.
  final double height;

  const NetworkMarkerIcon(
    this.url, {
    this.width = 32,
    this.height = 32,
  });
}

/// Widget marker icon (any Flutter widget).
class WidgetMarkerIcon extends MarkerIcon {
  /// The widget to display as marker.
  final Widget child;

  /// Width of the container.
  final double width;

  /// Height of the container.
  final double height;

  const WidgetMarkerIcon(
    this.child, {
    this.width = 32,
    this.height = 32,
  });
}

/// Marker color palette matching the app design system.
class MarkerColors {
  MarkerColors._();

  /// Primary marker color (Indigo 500).
  static const Color primary = Color(0xFF6366F1);

  /// Start point color (Green 500).
  static const Color start = Color(0xFF22C55E);

  /// End point color (Red 500).
  static const Color end = Color(0xFFEF4444);

  /// Warning color (Amber 500).
  static const Color warning = Color(0xFFF59E0B);

  /// Info color (Sky 500).
  static const Color info = Color(0xFF0EA5E9);

  /// Teal color (Teal 500).
  static const Color teal = Color(0xFF14B8A6);

  /// Purple color (Purple 500).
  static const Color purple = Color(0xFF8B5CF6);

  /// Pink color (Pink 500).
  static const Color pink = Color(0xFFEC4899);
}

/// Marker style variants for DefaultMarkerIcon.
enum MarkerStyle {
  /// Classic pin style with rounded head and pointed tail.
  classic,

  /// Modern flat style with subtle gradients and glassmorphism effect.
  modern,

  /// Minimal dot style for less intrusive markers.
  minimal,
}

/// Default pin marker icon.
class DefaultMarkerIcon extends MarkerIcon {
  /// Color of the pin.
  final Color color;

  /// Size of the pin.
  final double size;

  /// Visual style of the marker.
  final MarkerStyle style;

  /// Whether to show a shadow beneath the marker.
  final bool showShadow;

  /// Secondary/accent color for gradient effects.
  final Color? accentColor;

  /// Border width for the marker outline.
  final double borderWidth;

  /// Icon to display inside the marker (optional).
  final IconData? innerIcon;

  /// Inner icon color (defaults to white).
  final Color innerIconColor;

  const DefaultMarkerIcon({
    this.color = MarkerColors.primary,
    this.size = 48,
    this.style = MarkerStyle.modern,
    this.showShadow = true,
    this.accentColor,
    this.borderWidth = 2.0,
    this.innerIcon,
    this.innerIconColor = Colors.white,
  });

  /// Creates a copy with modified properties.
  DefaultMarkerIcon copyWith({
    Color? color,
    double? size,
    MarkerStyle? style,
    bool? showShadow,
    Color? accentColor,
    double? borderWidth,
    IconData? innerIcon,
    Color? innerIconColor,
  }) {
    return DefaultMarkerIcon(
      color: color ?? this.color,
      size: size ?? this.size,
      style: style ?? this.style,
      showShadow: showShadow ?? this.showShadow,
      accentColor: accentColor ?? this.accentColor,
      borderWidth: borderWidth ?? this.borderWidth,
      innerIcon: innerIcon ?? this.innerIcon,
      innerIconColor: innerIconColor ?? this.innerIconColor,
    );
  }

  /// Primary indigo pin marker (modern style).
  static const DefaultMarkerIcon primary = DefaultMarkerIcon(
    color: MarkerColors.primary,
    style: MarkerStyle.modern,
  );

  /// Red pin marker.
  static const DefaultMarkerIcon red = DefaultMarkerIcon(
    color: MarkerColors.end,
    style: MarkerStyle.modern,
  );

  /// Blue pin marker (uses primary indigo).
  static const DefaultMarkerIcon blue = DefaultMarkerIcon(
    color: MarkerColors.primary,
    style: MarkerStyle.modern,
  );

  /// Green pin marker.
  static const DefaultMarkerIcon green = DefaultMarkerIcon(
    color: MarkerColors.start,
    style: MarkerStyle.modern,
  );

  /// Orange/warning pin marker.
  static const DefaultMarkerIcon orange = DefaultMarkerIcon(
    color: MarkerColors.warning,
    style: MarkerStyle.modern,
  );

  /// Start point marker (green with flag icon).
  static const DefaultMarkerIcon start = DefaultMarkerIcon(
    color: MarkerColors.start,
    style: MarkerStyle.modern,
    innerIcon: Icons.flag_rounded,
  );

  /// End point marker (red with location icon).
  static const DefaultMarkerIcon end = DefaultMarkerIcon(
    color: MarkerColors.end,
    style: MarkerStyle.modern,
    innerIcon: Icons.place_rounded,
  );

  /// Waypoint marker (primary with circle icon).
  static const DefaultMarkerIcon waypoint = DefaultMarkerIcon(
    color: MarkerColors.primary,
    style: MarkerStyle.modern,
    innerIcon: Icons.circle,
  );

  /// Classic style presets (for backwards compatibility).
  static const DefaultMarkerIcon classicPrimary = DefaultMarkerIcon(
    color: MarkerColors.primary,
    style: MarkerStyle.classic,
  );

  static const DefaultMarkerIcon classicRed = DefaultMarkerIcon(
    color: MarkerColors.end,
    style: MarkerStyle.classic,
  );

  static const DefaultMarkerIcon classicGreen = DefaultMarkerIcon(
    color: MarkerColors.start,
    style: MarkerStyle.classic,
  );

  /// Minimal style presets.
  static const DefaultMarkerIcon minimalPrimary = DefaultMarkerIcon(
    color: MarkerColors.primary,
    style: MarkerStyle.minimal,
    size: 24,
  );

  static const DefaultMarkerIcon minimalRed = DefaultMarkerIcon(
    color: MarkerColors.end,
    style: MarkerStyle.minimal,
    size: 24,
  );

  static const DefaultMarkerIcon minimalGreen = DefaultMarkerIcon(
    color: MarkerColors.start,
    style: MarkerStyle.minimal,
    size: 24,
  );
}

/// Animation effect types for AnimatedMarkerIcon.
enum MarkerAnimationType {
  /// Pulsing scale effect (breathing animation).
  pulse,

  /// Drop-in from above with bounce.
  dropIn,

  /// Ripple effect radiating outward.
  ripple,

  /// Combination of pulse and ripple.
  pulseRipple,
}

/// Animated marker icon with various animation effects.
///
/// This marker supports animations like pulsing, drop-in, and ripple effects.
/// The animation automatically starts when the widget is mounted.
///
/// Example:
/// ```dart
/// AnimatedMarkerIcon(
///   color: MarkerColors.primary,
///   animationType: MarkerAnimationType.pulse,
/// )
/// ```
class AnimatedMarkerIcon extends MarkerIcon {
  /// Color of the marker.
  final Color color;

  /// Size of the marker.
  final double size;

  /// Type of animation to apply.
  final MarkerAnimationType animationType;

  /// Visual style of the marker (same as DefaultMarkerIcon).
  final MarkerStyle style;

  /// Animation duration for one cycle.
  final Duration animationDuration;

  /// Whether the animation should repeat.
  final bool repeat;

  /// Whether to show shadow.
  final bool showShadow;

  /// Icon to display inside the marker (optional).
  final IconData? innerIcon;

  /// Ripple color (defaults to marker color with reduced opacity).
  final Color? rippleColor;

  /// Maximum ripple radius multiplier (relative to marker size).
  final double rippleMaxRadius;

  const AnimatedMarkerIcon({
    this.color = MarkerColors.primary,
    this.size = 48,
    this.animationType = MarkerAnimationType.pulse,
    this.style = MarkerStyle.modern,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.repeat = true,
    this.showShadow = true,
    this.innerIcon,
    this.rippleColor,
    this.rippleMaxRadius = 1.5,
  });

  /// Creates a copy with modified properties.
  AnimatedMarkerIcon copyWith({
    Color? color,
    double? size,
    MarkerAnimationType? animationType,
    MarkerStyle? style,
    Duration? animationDuration,
    bool? repeat,
    bool? showShadow,
    IconData? innerIcon,
    Color? rippleColor,
    double? rippleMaxRadius,
  }) {
    return AnimatedMarkerIcon(
      color: color ?? this.color,
      size: size ?? this.size,
      animationType: animationType ?? this.animationType,
      style: style ?? this.style,
      animationDuration: animationDuration ?? this.animationDuration,
      repeat: repeat ?? this.repeat,
      showShadow: showShadow ?? this.showShadow,
      innerIcon: innerIcon ?? this.innerIcon,
      rippleColor: rippleColor ?? this.rippleColor,
      rippleMaxRadius: rippleMaxRadius ?? this.rippleMaxRadius,
    );
  }

  /// Pulsing primary marker.
  static const AnimatedMarkerIcon pulsingPrimary = AnimatedMarkerIcon(
    color: MarkerColors.primary,
    animationType: MarkerAnimationType.pulse,
  );

  /// Pulsing red marker (for alerts/important locations).
  static const AnimatedMarkerIcon pulsingRed = AnimatedMarkerIcon(
    color: MarkerColors.end,
    animationType: MarkerAnimationType.pulse,
  );

  /// Drop-in green marker (for start points).
  static const AnimatedMarkerIcon dropInStart = AnimatedMarkerIcon(
    color: MarkerColors.start,
    animationType: MarkerAnimationType.dropIn,
    innerIcon: Icons.flag_rounded,
    repeat: false,
  );

  /// Drop-in red marker (for end points).
  static const AnimatedMarkerIcon dropInEnd = AnimatedMarkerIcon(
    color: MarkerColors.end,
    animationType: MarkerAnimationType.dropIn,
    innerIcon: Icons.place_rounded,
    repeat: false,
  );

  /// Ripple effect marker (for user location or active points).
  static const AnimatedMarkerIcon rippleLocation = AnimatedMarkerIcon(
    color: MarkerColors.info,
    animationType: MarkerAnimationType.ripple,
    style: MarkerStyle.minimal,
    size: 24,
  );

  /// Combined pulse and ripple marker.
  static const AnimatedMarkerIcon pulseRipple = AnimatedMarkerIcon(
    color: MarkerColors.primary,
    animationType: MarkerAnimationType.pulseRipple,
  );
}

/// Marker icon that displays a circular avatar with optional heading indicator.
///
/// Used for rendering friend/driver markers on the map with their profile
/// pictures. Falls back to a placeholder icon when avatar URL is null.
class AvatarMarkerIcon extends MarkerIcon {
  /// URL of the avatar image. If null, shows placeholder.
  final String? avatarUrl;

  /// Size of the avatar circle (diameter).
  final double size;

  /// Color of the border and heading indicator arrow.
  final Color borderColor;

  /// Border width around the avatar.
  final double borderWidth;

  /// Heading direction in degrees (0-360).
  /// 0 = North, 90 = East, 180 = South, 270 = West.
  /// If null, no heading indicator is shown.
  final double? heading;

  /// Whether to show the heading indicator arrow.
  final bool showHeadingIndicator;

  /// Size of the heading indicator arrow.
  final double arrowSize;

  /// Whether to show shadow beneath the marker.
  final bool showShadow;

  /// Placeholder icon when avatarUrl is null or fails to load.
  final IconData placeholderIcon;

  /// Background color for placeholder.
  final Color placeholderBackgroundColor;

  /// Icon color for placeholder.
  final Color placeholderIconColor;

  const AvatarMarkerIcon({
    this.avatarUrl,
    this.size = 48,
    this.borderColor = MarkerColors.primary,
    this.borderWidth = 3.0,
    this.heading,
    this.showHeadingIndicator = true,
    this.arrowSize = 12.0,
    this.showShadow = true,
    this.placeholderIcon = Icons.person,
    this.placeholderBackgroundColor = const Color(0xFFE5E7EB),
    this.placeholderIconColor = const Color(0xFF9CA3AF),
  });

  /// Total size including arrow indicator (only when heading is provided).
  /// Arrow can point in any direction, so we need space on all sides.
  double get totalSize =>
      size + (showHeadingIndicator && heading != null ? arrowSize * 2 : 0);
}

/// A cached marker icon that stores a pre-rendered image for performance.
///
/// Use this when displaying many markers with the same appearance.
/// The marker is rendered once and reused, improving performance
/// on maps with hundreds of markers.
///
/// Example:
/// ```dart
/// // Create cached version of a marker
/// final cachedMarker = CachedMarkerIcon(
///   baseIcon: DefaultMarkerIcon.primary,
/// );
///
/// // Use in multiple markers
/// for (final point in points) {
///   markers.add(Marker(position: point, icon: cachedMarker));
/// }
/// ```
class CachedMarkerIcon extends MarkerIcon {
  /// The base marker icon to cache.
  final MarkerIcon baseIcon;

  /// Device pixel ratio for rendering (defaults to 2.0 for retina).
  final double devicePixelRatio;

  const CachedMarkerIcon({
    required this.baseIcon,
    this.devicePixelRatio = 2.0,
  });

  /// Creates a cached version of a DefaultMarkerIcon.
  factory CachedMarkerIcon.fromDefault({
    Color color = MarkerColors.primary,
    double size = 48,
    MarkerStyle style = MarkerStyle.modern,
    double devicePixelRatio = 2.0,
  }) {
    return CachedMarkerIcon(
      baseIcon: DefaultMarkerIcon(
        color: color,
        size: size,
        style: style,
      ),
      devicePixelRatio: devicePixelRatio,
    );
  }

  /// Creates a cached primary marker.
  static CachedMarkerIcon primary({double devicePixelRatio = 2.0}) =>
      CachedMarkerIcon(
        baseIcon: DefaultMarkerIcon.primary,
        devicePixelRatio: devicePixelRatio,
      );

  /// Creates a cached red marker.
  static CachedMarkerIcon red({double devicePixelRatio = 2.0}) =>
      CachedMarkerIcon(
        baseIcon: DefaultMarkerIcon.red,
        devicePixelRatio: devicePixelRatio,
      );

  /// Creates a cached green marker.
  static CachedMarkerIcon green({double devicePixelRatio = 2.0}) =>
      CachedMarkerIcon(
        baseIcon: DefaultMarkerIcon.green,
        devicePixelRatio: devicePixelRatio,
      );
}

/// A marker icon that displays a number inside.
///
/// Useful for showing ordered points, waypoints, or numbered locations.
///
/// Example:
/// ```dart
/// // Single digit
/// NumberedMarkerIcon(number: 1)
///
/// // Multiple digits
/// NumberedMarkerIcon(number: 42, color: MarkerColors.end)
///
/// // With letter
/// NumberedMarkerIcon.letter('A')
/// ```
class NumberedMarkerIcon extends MarkerIcon {
  /// The number to display (1-999).
  final int? number;

  /// A letter or short text to display (max 2 characters).
  final String? text;

  /// Color of the marker.
  final Color color;

  /// Size of the marker.
  final double size;

  /// Visual style of the marker.
  final MarkerStyle style;

  /// Whether to show shadow.
  final bool showShadow;

  /// Text color (defaults to white for dark backgrounds).
  final Color textColor;

  /// Font weight for the number/text.
  final FontWeight fontWeight;

  const NumberedMarkerIcon({
    this.number,
    this.text,
    this.color = MarkerColors.primary,
    this.size = 48,
    this.style = MarkerStyle.modern,
    this.showShadow = true,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.bold,
  }) : assert(number != null || text != null,
            'Either number or text must be provided');

  /// Creates a numbered marker with the given number.
  factory NumberedMarkerIcon.withNumber(
    int number, {
    Color color = MarkerColors.primary,
    double size = 48,
    MarkerStyle style = MarkerStyle.modern,
  }) {
    return NumberedMarkerIcon(
      number: number,
      color: color,
      size: size,
      style: style,
    );
  }

  /// Creates a marker with a letter.
  factory NumberedMarkerIcon.letter(
    String letter, {
    Color color = MarkerColors.primary,
    double size = 48,
    MarkerStyle style = MarkerStyle.modern,
    Color? textColor,
  }) {
    return NumberedMarkerIcon(
      text: letter.substring(0, letter.length.clamp(0, 2)),
      color: color,
      size: size,
      textColor: textColor ?? Colors.white,
      style: style,
    );
  }

  /// The display text (number converted to string or the text).
  String get displayText => text ?? (number?.toString() ?? '');

  /// Creates a copy with modified properties.
  NumberedMarkerIcon copyWith({
    int? number,
    String? text,
    Color? color,
    double? size,
    MarkerStyle? style,
    bool? showShadow,
    Color? textColor,
    FontWeight? fontWeight,
  }) {
    return NumberedMarkerIcon(
      number: number ?? this.number,
      text: text ?? this.text,
      color: color ?? this.color,
      size: size ?? this.size,
      style: style ?? this.style,
      showShadow: showShadow ?? this.showShadow,
      textColor: textColor ?? this.textColor,
      fontWeight: fontWeight ?? this.fontWeight,
    );
  }

  /// Creates numbered markers for a sequence of waypoints.
  static List<NumberedMarkerIcon> sequence(
    int count, {
    Color color = MarkerColors.primary,
    double size = 48,
    int startFrom = 1,
  }) {
    return List.generate(
      count,
      (index) => NumberedMarkerIcon(
        number: startFrom + index,
        color: color,
        size: size,
      ),
    );
  }

  /// Creates lettered markers A, B, C, etc.
  static List<NumberedMarkerIcon> letters(
    int count, {
    Color color = MarkerColors.primary,
    double size = 48,
  }) {
    return List.generate(
      count.clamp(0, 26),
      (index) => NumberedMarkerIcon.letter(
        String.fromCharCode('A'.codeUnitAt(0) + index),
        color: color,
        size: size,
      ),
    );
  }
}
