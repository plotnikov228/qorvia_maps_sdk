import 'package:flutter/material.dart';

import '../../models/route/lane_info.dart';

/// Widget that displays lane guidance information.
///
/// Shows lane arrows with colors indicating:
/// - Green: valid lanes for current maneuver
/// - Gray: invalid lanes
/// - Highlighted: active/recommended lane (Valhalla only)
class LanesIndicator extends StatelessWidget {
  /// List of lanes to display.
  final List<LaneInfo> lanes;

  /// Size of each lane icon.
  final double iconSize;

  /// Color for valid lanes.
  final Color validColor;

  /// Color for invalid lanes.
  final Color invalidColor;

  /// Color for active/recommended lane highlight.
  final Color activeColor;

  /// Background color of the indicator.
  final Color backgroundColor;

  /// Spacing between lane icons.
  final double spacing;

  const LanesIndicator({
    super.key,
    required this.lanes,
    this.iconSize = 24,
    this.validColor = const Color(0xFF4CAF50),
    this.invalidColor = const Color(0xFF9E9E9E),
    this.activeColor = const Color(0xFF2196F3),
    this.backgroundColor = const Color(0xE6FFFFFF),
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (lanes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: lanes.asMap().entries.map((entry) {
          final index = entry.key;
          final lane = entry.value;
          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? spacing : 0),
            child: _LaneIcon(
              lane: lane,
              size: iconSize,
              validColor: validColor,
              invalidColor: invalidColor,
              activeColor: activeColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LaneIcon extends StatelessWidget {
  final LaneInfo lane;
  final double size;
  final Color validColor;
  final Color invalidColor;
  final Color activeColor;

  const _LaneIcon({
    required this.lane,
    required this.size,
    required this.validColor,
    required this.invalidColor,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = lane.active ? activeColor : (lane.valid ? validColor : invalidColor);

    return Container(
      width: size,
      height: size,
      decoration: lane.active
          ? BoxDecoration(
              color: activeColor.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _LaneArrowPainter(
          directions: lane.directions,
          color: color,
        ),
      ),
    );
  }
}

class _LaneArrowPainter extends CustomPainter {
  final List<LaneDirection> directions;
  final Color color;

  _LaneArrowPainter({
    required this.directions,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (directions.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final arrowLength = size.height * 0.35;

    for (final direction in directions) {
      _drawArrow(canvas, center, arrowLength, direction, paint);
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset center,
    double length,
    LaneDirection direction,
    Paint paint,
  ) {
    final path = Path();
    final headSize = length * 0.4;

    switch (direction) {
      case LaneDirection.straight:
        // Straight up arrow
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy - length);
        // Arrow head
        path.moveTo(center.dx - headSize, center.dy - length + headSize);
        path.lineTo(center.dx, center.dy - length);
        path.lineTo(center.dx + headSize, center.dy - length + headSize);
        break;

      case LaneDirection.left:
        // Left turn arrow
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy);
        path.lineTo(center.dx - length, center.dy);
        // Arrow head
        path.moveTo(center.dx - length + headSize, center.dy - headSize);
        path.lineTo(center.dx - length, center.dy);
        path.lineTo(center.dx - length + headSize, center.dy + headSize);
        break;

      case LaneDirection.right:
        // Right turn arrow
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy);
        path.lineTo(center.dx + length, center.dy);
        // Arrow head
        path.moveTo(center.dx + length - headSize, center.dy - headSize);
        path.lineTo(center.dx + length, center.dy);
        path.lineTo(center.dx + length - headSize, center.dy + headSize);
        break;

      case LaneDirection.slightLeft:
        // Slight left arrow (45 degrees)
        final dx = length * 0.7;
        final dy = length * 0.7;
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy);
        path.lineTo(center.dx - dx, center.dy - dy);
        // Arrow head
        path.moveTo(center.dx - dx + headSize, center.dy - dy);
        path.lineTo(center.dx - dx, center.dy - dy);
        path.lineTo(center.dx - dx, center.dy - dy + headSize);
        break;

      case LaneDirection.slightRight:
        // Slight right arrow (45 degrees)
        final dx = length * 0.7;
        final dy = length * 0.7;
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy);
        path.lineTo(center.dx + dx, center.dy - dy);
        // Arrow head
        path.moveTo(center.dx + dx - headSize, center.dy - dy);
        path.lineTo(center.dx + dx, center.dy - dy);
        path.lineTo(center.dx + dx, center.dy - dy + headSize);
        break;

      case LaneDirection.sharpLeft:
        // Sharp left (almost 90 degrees back)
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy);
        path.lineTo(center.dx - length, center.dy + length * 0.5);
        // Arrow head
        path.moveTo(center.dx - length + headSize, center.dy + length * 0.5 - headSize);
        path.lineTo(center.dx - length, center.dy + length * 0.5);
        path.lineTo(center.dx - length + headSize, center.dy + length * 0.5 + headSize);
        break;

      case LaneDirection.sharpRight:
        // Sharp right (almost 90 degrees back)
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy);
        path.lineTo(center.dx + length, center.dy + length * 0.5);
        // Arrow head
        path.moveTo(center.dx + length - headSize, center.dy + length * 0.5 - headSize);
        path.lineTo(center.dx + length, center.dy + length * 0.5);
        path.lineTo(center.dx + length - headSize, center.dy + length * 0.5 + headSize);
        break;

      case LaneDirection.uturn:
        // U-turn arrow (left)
        final radius = length * 0.4;
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy - length + radius);
        path.arcToPoint(
          Offset(center.dx - radius * 2, center.dy - length + radius),
          radius: Radius.circular(radius),
          clockwise: false,
        );
        path.lineTo(center.dx - radius * 2, center.dy);
        // Arrow head
        path.moveTo(center.dx - radius * 2 - headSize, center.dy - headSize);
        path.lineTo(center.dx - radius * 2, center.dy);
        path.lineTo(center.dx - radius * 2 + headSize, center.dy - headSize);
        break;

      case LaneDirection.mergeToLeft:
        // Merge left
        path.moveTo(center.dx + length * 0.3, center.dy + length);
        path.lineTo(center.dx - length * 0.3, center.dy - length);
        // Arrow head
        path.moveTo(center.dx - length * 0.3 + headSize * 0.7, center.dy - length + headSize);
        path.lineTo(center.dx - length * 0.3, center.dy - length);
        path.lineTo(center.dx - length * 0.3 - headSize * 0.3, center.dy - length + headSize);
        break;

      case LaneDirection.mergeToRight:
        // Merge right
        path.moveTo(center.dx - length * 0.3, center.dy + length);
        path.lineTo(center.dx + length * 0.3, center.dy - length);
        // Arrow head
        path.moveTo(center.dx + length * 0.3 + headSize * 0.3, center.dy - length + headSize);
        path.lineTo(center.dx + length * 0.3, center.dy - length);
        path.lineTo(center.dx + length * 0.3 - headSize * 0.7, center.dy - length + headSize);
        break;

      case LaneDirection.none:
        // No direction - draw a simple vertical line
        path.moveTo(center.dx, center.dy + length);
        path.lineTo(center.dx, center.dy - length);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LaneArrowPainter oldDelegate) {
    return oldDelegate.directions != directions || oldDelegate.color != color;
  }
}
