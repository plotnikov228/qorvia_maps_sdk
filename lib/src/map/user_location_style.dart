import 'dart:developer' as dev;

import 'package:flutter/material.dart';

/// Style configuration for custom user location marker.
///
/// When provided to [MapOptions.userLocationStyle], the default blue dot
/// is replaced with a custom icon from assets. The icon automatically
/// rotates based on the user's heading/bearing.
///
/// Example:
/// ```dart
/// MapOptions(
///   showUserLocation: true,
///   userLocationStyle: UserLocationStyle(
///     iconAsset: 'assets/icons/my_car.png',
///     iconSize: 1.5,
///     showAccuracyCircle: true,
///   ),
/// )
/// ```
class UserLocationStyle {
  /// Path to PNG or SVG asset (e.g., 'assets/icons/my_location.png').
  ///
  /// The icon should point upward (north = 0°) as it will be rotated
  /// by MapLibre based on the user's heading.
  final String iconAsset;

  /// Icon size scale factor (default 1.0).
  ///
  /// Values > 1.0 make the icon larger, < 1.0 make it smaller.
  final double iconSize;

  /// Whether to show GPS accuracy circle around the user location.
  final bool showAccuracyCircle;

  /// Accuracy circle fill color.
  final Color accuracyCircleColor;

  /// Accuracy circle fill opacity (0.0 - 1.0).
  final double accuracyCircleOpacity;

  /// Accuracy circle stroke color.
  final Color accuracyCircleStrokeColor;

  /// Accuracy circle stroke width.
  final double accuracyCircleStrokeWidth;

  /// Accuracy circle stroke opacity (0.0 - 1.0).
  final double accuracyCircleStrokeOpacity;

  /// Minimum accuracy in meters to show the accuracy circle.
  /// Below this threshold, the circle is hidden.
  final double minAccuracyToShow;

  /// Creates a user location style configuration.
  ///
  /// [iconAsset] is required and must be a valid Flutter asset path.
  const UserLocationStyle({
    required this.iconAsset,
    this.iconSize = 1.0,
    this.showAccuracyCircle = true,
    this.accuracyCircleColor = const Color(0xFF6366F1),
    this.accuracyCircleOpacity = 0.1,
    this.accuracyCircleStrokeColor = const Color(0xFF6366F1),
    this.accuracyCircleStrokeWidth = 1.0,
    this.accuracyCircleStrokeOpacity = 0.3,
    this.minAccuracyToShow = 5.0,
  });

  /// Creates a copy with modified fields.
  UserLocationStyle copyWith({
    String? iconAsset,
    double? iconSize,
    bool? showAccuracyCircle,
    Color? accuracyCircleColor,
    double? accuracyCircleOpacity,
    Color? accuracyCircleStrokeColor,
    double? accuracyCircleStrokeWidth,
    double? accuracyCircleStrokeOpacity,
    double? minAccuracyToShow,
  }) {
    return UserLocationStyle(
      iconAsset: iconAsset ?? this.iconAsset,
      iconSize: iconSize ?? this.iconSize,
      showAccuracyCircle: showAccuracyCircle ?? this.showAccuracyCircle,
      accuracyCircleColor: accuracyCircleColor ?? this.accuracyCircleColor,
      accuracyCircleOpacity:
          accuracyCircleOpacity ?? this.accuracyCircleOpacity,
      accuracyCircleStrokeColor:
          accuracyCircleStrokeColor ?? this.accuracyCircleStrokeColor,
      accuracyCircleStrokeWidth:
          accuracyCircleStrokeWidth ?? this.accuracyCircleStrokeWidth,
      accuracyCircleStrokeOpacity:
          accuracyCircleStrokeOpacity ?? this.accuracyCircleStrokeOpacity,
      minAccuracyToShow: minAccuracyToShow ?? this.minAccuracyToShow,
    );
  }

  /// Logs style configuration (debug level).
  void logConfig() {
    dev.log(
      '[UserLocationStyle] config: '
      'iconAsset=$iconAsset, '
      'iconSize=$iconSize, '
      'showAccuracyCircle=$showAccuracyCircle, '
      'accuracyCircleColor=${accuracyCircleColor.toARGB32().toRadixString(16)}, '
      'minAccuracyToShow=$minAccuracyToShow',
      level: 500,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLocationStyle &&
        other.iconAsset == iconAsset &&
        other.iconSize == iconSize &&
        other.showAccuracyCircle == showAccuracyCircle &&
        other.accuracyCircleColor == accuracyCircleColor &&
        other.accuracyCircleOpacity == accuracyCircleOpacity &&
        other.accuracyCircleStrokeColor == accuracyCircleStrokeColor &&
        other.accuracyCircleStrokeWidth == accuracyCircleStrokeWidth &&
        other.accuracyCircleStrokeOpacity == accuracyCircleStrokeOpacity &&
        other.minAccuracyToShow == minAccuracyToShow;
  }

  @override
  int get hashCode {
    return Object.hash(
      iconAsset,
      iconSize,
      showAccuracyCircle,
      accuracyCircleColor,
      accuracyCircleOpacity,
      accuracyCircleStrokeColor,
      accuracyCircleStrokeWidth,
      accuracyCircleStrokeOpacity,
      minAccuracyToShow,
    );
  }

  @override
  String toString() {
    return 'UserLocationStyle('
        'iconAsset: $iconAsset, '
        'iconSize: $iconSize, '
        'showAccuracyCircle: $showAccuracyCircle'
        ')';
  }
}
