import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Default scale bar widget showing map scale.
///
/// Displays a scale bar with distance label that adjusts based on zoom level.
/// Automatically chooses appropriate units (m or km).
///
/// Example:
/// ```dart
/// MapScaleBar(
///   metersPerPixel: 10.5,
///   zoom: 15.0,
/// )
/// ```
class MapScaleBar extends StatelessWidget {
  /// Meters per pixel at current zoom level.
  final double metersPerPixel;

  /// Current zoom level.
  final double zoom;

  /// Maximum width of the scale bar in pixels.
  final double maxWidth;

  /// Height of the scale bar line.
  final double barHeight;

  /// Color of the scale bar.
  final Color barColor;

  /// Text style for the distance label.
  final TextStyle? textStyle;

  const MapScaleBar({
    super.key,
    required this.metersPerPixel,
    required this.zoom,
    this.maxWidth = 100,
    this.barHeight = 3,
    this.barColor = Colors.black87,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final scaleInfo = _calculateScale();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance label
          Text(
            scaleInfo.label,
            style: textStyle ??
                TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: barColor,
                ),
          ),
          const SizedBox(height: 2),
          // Scale bar
          Container(
            width: scaleInfo.widthPixels,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate scale bar dimensions and label.
  _ScaleInfo _calculateScale() {
    // Target width for the scale bar (80% of max)
    final targetWidth = maxWidth * 0.8;

    // Calculate distance that would fit in target width
    final targetDistance = targetWidth * metersPerPixel;

    // Find the nearest "nice" distance value
    final niceDistance = _findNiceDistance(targetDistance);

    // Calculate actual width for this nice distance
    final actualWidth = niceDistance / metersPerPixel;

    // Format the label
    final label = _formatDistance(niceDistance);

    return _ScaleInfo(
      widthPixels: actualWidth.clamp(20.0, maxWidth),
      label: label,
    );
  }

  /// Find a "nice" round number for the scale.
  double _findNiceDistance(double distance) {
    // Nice values: 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, ...
    const niceValues = [1, 2, 5];

    // Find the order of magnitude
    final magnitude = math.pow(10, (math.log(distance) / math.ln10).floor());

    // Find the best nice value
    double best = magnitude.toDouble();
    double bestDiff = double.infinity;

    for (final nice in niceValues) {
      final value = nice * magnitude;
      final diff = (distance - value).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = value.toDouble();
      }
      // Also check 10x for the next magnitude
      final value10 = nice * magnitude * 10;
      final diff10 = (distance - value10).abs();
      if (diff10 < bestDiff) {
        bestDiff = diff10;
        best = value10.toDouble();
      }
    }

    return best.clamp(1.0, 100000.0); // 1m to 100km
  }

  /// Format distance with appropriate units.
  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      if (km == km.roundToDouble()) {
        return '${km.round()} km';
      }
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _ScaleInfo {
  final double widthPixels;
  final String label;

  _ScaleInfo({
    required this.widthPixels,
    required this.label,
  });
}
