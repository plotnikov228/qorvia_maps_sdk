import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

/// Custom ETA panel widget styled like Yandex Navigator.
///
/// Features:
/// - Distance | Duration | Arrival time row
/// - Progress bar with traffic colors
/// - Close button
class CustomEtaPanel extends StatelessWidget {
  final EtaWidgetData data;
  final VoidCallback? onClose;

  const CustomEtaPanel({
    super.key,
    required this.data,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main info row
              _buildInfoRow(),
              const SizedBox(height: 10),
              // Progress bar
              _buildProgressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        // Distance
        Expanded(
          child: _InfoItem(
            value: data.formattedDistance,
            showArrow: true,
          ),
        ),
        // Divider
        Container(
          width: 1,
          height: 24,
          color: Colors.grey.shade300,
        ),
        // Duration
        Expanded(
          child: _InfoItem(
            value: data.formattedDuration,
          ),
        ),
        // Divider
        Container(
          width: 1,
          height: 24,
          color: Colors.grey.shade300,
        ),
        // ETA
        Expanded(
          child: _InfoItem(
            value: data.formattedEta,
            isHighlighted: true,
          ),
        ),
        // Close button
        if (onClose != null) ...[
          const SizedBox(width: 8),
          _CloseButton(onTap: onClose!),
        ],
      ],
    );
  }

  Widget _buildProgressBar() {
    const activeColor = Color(0xFF2979FF); // Primary blue
    const traveledColor = Color(0xFFBDBDBD); // Gray

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final progress = data.progress.clamp(0.0, 1.0);

        return SizedBox(
          height: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              final cursorPosition = animatedProgress * barWidth;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Active/remaining route (full width, primary color)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    height: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Traveled portion (gray overlay)
                  Positioned(
                    left: 0,
                    top: 8,
                    height: 4,
                    child: Container(
                      width: cursorPosition,
                      decoration: const BoxDecoration(
                        color: traveledColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(2),
                          bottomLeft: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Sharp arrow cursor (navigator style)
                  Positioned(
                    left: cursorPosition - 6,
                    top: 2,
                    child: CustomPaint(
                      size: const Size(12, 16),
                      painter: _NavigatorArrowPainter(color: activeColor),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Sharp navigator-style arrow cursor painter.
class _NavigatorArrowPainter extends CustomPainter {
  final Color color;

  _NavigatorArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Sharp chevron/arrow pointing right
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(0, size.height)
      ..lineTo(size.width * 0.35, size.height * 0.5)
      ..close();

    // Add shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(path.shift(const Offset(1, 1)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NavigatorArrowPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _InfoItem extends StatelessWidget {
  final String value;
  final bool showArrow;
  final bool isHighlighted;

  const _InfoItem({
    required this.value,
    this.showArrow = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showArrow) ...[
          CustomPaint(
            size: const Size(8, 10),
            painter: _ArrowPainter(),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? Colors.black87 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            size: 20,
            color: Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

