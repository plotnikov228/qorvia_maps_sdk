import 'package:flutter/material.dart';

/// Widget that displays a traffic signal indicator.
///
/// Shows a traffic light icon when approaching a traffic signal,
/// with an optional badge showing the number of signals.
class TrafficSignalIndicator extends StatelessWidget {
  /// Whether there is a traffic signal ahead.
  final bool hasTrafficSignal;

  /// Number of traffic signals (0 if not available).
  final int signalCount;

  /// Whether to show the signal count badge.
  final bool showCount;

  /// Size of the traffic light icon.
  final double iconSize;

  /// Color of the traffic light icon.
  final Color iconColor;

  /// Background color of the indicator.
  final Color backgroundColor;

  /// Badge background color.
  final Color badgeColor;

  /// Badge text color.
  final Color badgeTextColor;

  const TrafficSignalIndicator({
    super.key,
    required this.hasTrafficSignal,
    this.signalCount = 0,
    this.showCount = true,
    this.iconSize = 20,
    this.iconColor = const Color(0xFFFF9800),
    this.backgroundColor = Colors.transparent,
    this.badgeColor = const Color(0xFFFF9800),
    this.badgeTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasTrafficSignal) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: backgroundColor != Colors.transparent
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(iconSize, iconSize),
            painter: _TrafficLightPainter(color: iconColor),
          ),
          if (showCount && signalCount > 1)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  '$signalCount',
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrafficLightPainter extends CustomPainter {
  final Color color;

  _TrafficLightPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Traffic light housing (vertical rectangle with rounded corners)
    final housingRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.5,
        size.height * 0.8,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(housingRect, strokePaint);

    // Traffic light pole
    final poleRect = Rect.fromLTWH(
      size.width * 0.42,
      size.height * 0.85,
      size.width * 0.16,
      size.height * 0.15,
    );
    canvas.drawRect(poleRect, paint);

    // Three lights (circles)
    final lightRadius = size.width * 0.1;
    final centerX = size.width * 0.5;

    // Top light (red position)
    canvas.drawCircle(
      Offset(centerX, size.height * 0.2),
      lightRadius,
      strokePaint,
    );

    // Middle light (yellow position - filled to indicate active)
    canvas.drawCircle(
      Offset(centerX, size.height * 0.45),
      lightRadius,
      paint,
    );

    // Bottom light (green position)
    canvas.drawCircle(
      Offset(centerX, size.height * 0.7),
      lightRadius,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrafficLightPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
