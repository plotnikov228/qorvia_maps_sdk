import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../navigation_options.dart';

/// Widget displaying the user's direction arrow.
class UserArrowWidget extends StatefulWidget {
  final UserArrowStyle style;
  final double? heading;
  final double accuracy;
  final bool showAccuracyCircle;

  const UserArrowWidget({
    super.key,
    required this.style,
    this.heading,
    this.accuracy = 10,
    this.showAccuracyCircle = true,
  });

  @override
  State<UserArrowWidget> createState() => _UserArrowWidgetState();
}

class _UserArrowWidgetState extends State<UserArrowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.style.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.style.size * 2,
      height: widget.style.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Accuracy circle
          if (widget.showAccuracyCircle)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: widget.style.size * _pulseAnimation.value,
                  height: widget.style.size * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.style.color.withAlpha(51),
                  ),
                );
              },
            ),
          // Direction arrow
          Transform.rotate(
            angle: (widget.heading ?? 0) * math.pi / 180,
            child: CustomPaint(
              size: Size(widget.style.size, widget.style.size),
              painter: _ArrowPainter(
                color: widget.style.color,
                borderColor: widget.style.borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _ArrowPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final arrowSize = size.width * 0.4;

    // Arrow pointing up
    path.moveTo(centerX, centerY - arrowSize);
    path.lineTo(centerX - arrowSize * 0.6, centerY + arrowSize * 0.5);
    path.lineTo(centerX, centerY + arrowSize * 0.2);
    path.lineTo(centerX + arrowSize * 0.6, centerY + arrowSize * 0.5);
    path.close();

    // Draw shadow
    canvas.drawPath(
      path.shift(const Offset(1, 1)),
      Paint()
        ..color = Colors.black.withAlpha(51)
        ..style = PaintingStyle.fill,
    );

    // Draw arrow
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Draw center dot
    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * 0.08,
      Paint()..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return color != oldDelegate.color || borderColor != oldDelegate.borderColor;
  }
}
