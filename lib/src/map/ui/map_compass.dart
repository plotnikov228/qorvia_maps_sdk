import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../navigation/navigation_logger.dart';

/// Default compass widget that rotates with map bearing.
///
/// Displays a compass icon that rotates to match the map's bearing.
/// Tap to reset the map bearing to north (0 degrees).
/// Automatically hides when bearing is close to north.
///
/// Example:
/// ```dart
/// MapCompass(
///   bearing: 45.0,
///   onReset: () => controller.resetBearing(),
/// )
/// ```
class MapCompass extends StatelessWidget {
  /// Current map bearing in degrees (0-360).
  final double bearing;

  /// Called when compass is tapped to reset bearing to north.
  final VoidCallback onReset;

  /// Threshold in degrees - hide compass when bearing is within this of north.
  final double hideThreshold;

  /// Widget size in pixels.
  final double size;

  /// Background color.
  final Color backgroundColor;

  /// Compass needle color for north.
  final Color northColor;

  /// Compass needle color for south.
  final Color southColor;

  const MapCompass({
    super.key,
    required this.bearing,
    required this.onReset,
    this.hideThreshold = 1.0,
    this.size = 44,
    this.backgroundColor = Colors.white,
    this.northColor = Colors.red,
    this.southColor = Colors.grey,
  });

  /// Whether the compass should be visible.
  bool get isVisible => bearing.abs() > hideThreshold;

  @override
  Widget build(BuildContext context) {
    // Auto-hide when close to north
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        NavigationLogger.debug('MapCompass', 'Reset bearing pressed', {
          'currentBearing': bearing,
        });
        onReset();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -bearing * (math.pi / 180),
          child: CustomPaint(
            size: Size(size, size),
            painter: _CompassPainter(
              northColor: northColor,
              southColor: southColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final Color northColor;
  final Color southColor;

  _CompassPainter({
    required this.northColor,
    required this.southColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // North needle (pointing up)
    final northPaint = Paint()
      ..color = northColor
      ..style = PaintingStyle.fill;

    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx - radius * 0.3, center.dy)
      ..lineTo(center.dx, center.dy - radius * 0.15)
      ..lineTo(center.dx + radius * 0.3, center.dy)
      ..close();

    canvas.drawPath(northPath, northPaint);

    // South needle (pointing down)
    final southPaint = Paint()
      ..color = southColor
      ..style = PaintingStyle.fill;

    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.3, center.dy)
      ..lineTo(center.dx, center.dy + radius * 0.15)
      ..lineTo(center.dx + radius * 0.3, center.dy)
      ..close();

    canvas.drawPath(southPath, southPaint);

    // Center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.15, centerPaint);

    final centerBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.15, centerBorderPaint);
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) =>
      northColor != oldDelegate.northColor ||
      southColor != oldDelegate.southColor;
}
