import 'package:flutter/material.dart';
import '../models/coordinates.dart';

/// Route line color palette matching the app design system.
class RouteColors {
  RouteColors._();

  /// Primary route color (Indigo 500).
  static const Color primary = Color(0xFF6366F1);

  /// Primary route outline color (Indigo 600).
  static const Color primaryOutline = Color(0xFF4F46E5);

  /// Alternative route color (Slate 400).
  static const Color alternative = Color(0xFF94A3B8);

  /// Walked/completed route color (Green 500).
  static const Color walked = Color(0xFF22C55E);
}

/// Configuration for route line display.
class RouteLineOptions {
  /// Color of the route line.
  final Color color;

  /// Width of the route line in pixels.
  final double width;

  /// Line pattern (solid, dashed, dotted).
  final RouteLinePattern pattern;

  /// Opacity of the route line (0-1).
  final double opacity;

  /// Whether to show direction arrows on the line.
  final bool showArrows;

  /// Color of the outline/border.
  final Color? outlineColor;

  /// Width of the outline/border.
  final double outlineWidth;

  const RouteLineOptions({
    this.color = RouteColors.primary,
    this.width = 5,
    this.pattern = RouteLinePattern.solid,
    this.opacity = 1.0,
    this.showArrows = false,
    this.outlineColor,
    this.outlineWidth = 1,
  });

  /// Creates options for the main route.
  factory RouteLineOptions.primary() {
    return const RouteLineOptions(
      color: RouteColors.primary,
      width: 6,
      outlineColor: RouteColors.primaryOutline,
      outlineWidth: 2,
    );
  }

  /// Creates options for an alternative route.
  factory RouteLineOptions.alternative() {
    return const RouteLineOptions(
      color: RouteColors.alternative,
      width: 5,
      opacity: 0.7,
    );
  }

  /// Creates options for a walked/completed portion of the route.
  factory RouteLineOptions.walked() {
    return const RouteLineOptions(
      color: RouteColors.walked,
      width: 6,
      pattern: RouteLinePattern.dashed,
    );
  }

  RouteLineOptions copyWith({
    Color? color,
    double? width,
    RouteLinePattern? pattern,
    double? opacity,
    bool? showArrows,
    Color? outlineColor,
    double? outlineWidth,
  }) {
    return RouteLineOptions(
      color: color ?? this.color,
      width: width ?? this.width,
      pattern: pattern ?? this.pattern,
      opacity: opacity ?? this.opacity,
      showArrows: showArrows ?? this.showArrows,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
    );
  }
}

/// Pattern for route line drawing.
enum RouteLinePattern {
  /// Solid continuous line.
  solid,

  /// Dashed line.
  dashed,

  /// Dotted line.
  dotted,
}

/// Represents a route line to be displayed on the map.
class RouteLine {
  /// Unique identifier for this route line.
  final String id;

  /// List of coordinates forming the route.
  final List<Coordinates> coordinates;

  /// Display options for the line.
  final RouteLineOptions options;

  /// Whether this route line is visible.
  final bool visible;

  const RouteLine({
    required this.id,
    required this.coordinates,
    this.options = const RouteLineOptions(),
    this.visible = true,
  });

  RouteLine copyWith({
    String? id,
    List<Coordinates>? coordinates,
    RouteLineOptions? options,
    bool? visible,
  }) {
    return RouteLine(
      id: id ?? this.id,
      coordinates: coordinates ?? this.coordinates,
      options: options ?? this.options,
      visible: visible ?? this.visible,
    );
  }

  /// Creates a route line from a route response.
  factory RouteLine.fromCoordinates(
    String id,
    List<Coordinates> coordinates, {
    RouteLineOptions? options,
  }) {
    return RouteLine(
      id: id,
      coordinates: coordinates,
      options: options ?? RouteLineOptions.primary(),
    );
  }
}
