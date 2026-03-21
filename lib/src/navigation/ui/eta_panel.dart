import 'package:flutter/material.dart';
import '../navigation_logger.dart';
import '../navigation_state.dart';

/// Panel showing ETA, remaining distance and time.
class EtaPanel extends StatelessWidget {
  final NavigationState state;
  final VoidCallback? onTap;
  final VoidCallback? onCloseTap;

  const EtaPanel({
    super.key,
    required this.state,
    this.onTap,
    this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ETA
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.formattedEta,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.formattedDurationRemaining} · ${state.formattedDistanceRemaining}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button
          if (onCloseTap != null)
            IconButton(
              onPressed: onCloseTap,
              icon: const Icon(Icons.close),
              color: Colors.grey.shade600,
              iconSize: 24,
            ),
        ],
      ),
    );
  }
}

/// Compact ETA panel for bottom of screen.
class CompactEtaPanel extends StatelessWidget {
  final NavigationState state;
  final VoidCallback? onTap;

  /// Primary color for active route portion.
  final Color activeColor;

  /// Color for traveled route portion.
  final Color traveledColor;

  /// Background color for the panel.
  final Color backgroundColor;

  /// Primary text color (values like time, distance).
  final Color textColor;

  /// Secondary text color (labels).
  final Color secondaryColor;

  /// Divider color between info columns.
  final Color dividerColor;

  /// Highlighted text color (e.g., arrival time).
  final Color highlightColor;

  /// Background color for exit button.
  final Color exitButtonBackground;

  /// Border color for exit button.
  final Color exitButtonBorder;

  /// Text/icon color for exit button.
  final Color exitButtonText;

  const CompactEtaPanel({
    super.key,
    required this.state,
    this.onTap,
    this.activeColor = const Color(0xFF2979FF),
    this.traveledColor = const Color(0xFFBDBDBD),
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xDD000000), // Colors.black87
    this.secondaryColor = const Color(0xFF757575), // Grey shade 600
    this.dividerColor = const Color(0xFFE0E0E0), // Grey shade 300
    this.highlightColor = const Color(0xFF388E3C), // Green shade 700
    this.exitButtonBackground = const Color(0xFFFFEBEE), // Red shade 50
    this.exitButtonBorder = const Color(0xFFEF9A9A), // Red shade 200
    this.exitButtonText = const Color(0xFFD32F2F), // Red shade 700
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Route progress track
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RouteProgressTrack(
                progress: state.progress,
                activeColor: activeColor,
                traveledColor: traveledColor,
              ),
            ),
            // Multi-waypoint progress indicator
            if (state.isMultiWaypoint)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _WaypointProgress(
                  currentLeg: state.currentLegIndex,
                  totalLegs: state.totalLegs,
                  nextWaypointDistance: state.formattedNextWaypointDistance,
                  activeColor: activeColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            Row(
              children: [
                // Exit button
                _ExitButton(
                  onTap: onTap,
                  backgroundColor: exitButtonBackground,
                  borderColor: exitButtonBorder,
                  textColor: exitButtonText,
                ),
                const SizedBox(width: 12),
                // Info columns
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoColumn(
                        value: state.formattedDurationRemaining,
                        label: 'Осталось',
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: dividerColor,
                      ),
                      _InfoColumn(
                        value: state.formattedDistanceRemaining,
                        label: 'Расстояние',
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: dividerColor,
                      ),
                      _InfoColumn(
                        value: state.formattedEta,
                        label: 'Прибытие',
                        highlighted: true,
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                        highlightColor: highlightColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Route progress track with animated arrow cursor.
class _RouteProgressTrack extends StatelessWidget {
  final double progress;
  final Color activeColor;
  final Color traveledColor;

  const _RouteProgressTrack({
    required this.progress,
    required this.activeColor,
    required this.traveledColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;

          // Animate progress changes smoothly
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, animatedProgress, child) {
              final cursorPosition = trackWidth * animatedProgress;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track background (active/remaining portion)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 10,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Traveled portion overlay (animated)
                  Positioned(
                    left: 0,
                    top: 10,
                    child: Container(
                      width: cursorPosition,
                      height: 4,
                      decoration: BoxDecoration(
                        color: traveledColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          bottomLeft: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Arrow cursor (animated)
                  Positioned(
                    left: cursorPosition - 12,
                    top: 0,
                    child: CustomPaint(
                      size: const Size(24, 24),
                      painter: _ArrowCursorPainter(color: activeColor),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Custom painter for arrow-shaped cursor with 3D effect.
class _ArrowCursorPainter extends CustomPainter {
  final Color color;

  _ArrowCursorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final tipX = size.width;
    final tipY = size.height * 0.5;

    // Top half (lighter)
    final topPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final topPath = Path()
      ..moveTo(0, 0) // Top-left
      ..lineTo(tipX, tipY) // Sharp tip
      ..lineTo(0, tipY) // Center-left
      ..close();

    canvas.drawPath(topPath, topPaint);

    // Bottom half (darker for 3D effect)
    final bottomPaint = Paint()
      ..color = Color.lerp(color, Colors.black, 0.2)!
      ..style = PaintingStyle.fill;

    final bottomPath = Path()
      ..moveTo(0, tipY) // Center-left
      ..lineTo(tipX, tipY) // Sharp tip
      ..lineTo(0, size.height) // Bottom-left
      ..close();

    canvas.drawPath(bottomPath, bottomPaint);
  }

  @override
  bool shouldRepaint(_ArrowCursorPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _ExitButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _ExitButton({
    this.onTap,
    this.backgroundColor = const Color(0xFFFFEBEE), // Red shade 50
    this.borderColor = const Color(0xFFEF9A9A), // Red shade 200
    this.textColor = const Color(0xFFD32F2F), // Red shade 700
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          NavigationLogger.info('EtaPanel', 'Exit button tapped');
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: textColor, size: 20),
              const SizedBox(width: 6),
              Text(
                'Выход',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaypointProgress extends StatelessWidget {
  final int currentLeg;
  final int totalLegs;
  final String nextWaypointDistance;
  final Color activeColor;
  final Color secondaryColor;

  const _WaypointProgress({
    required this.currentLeg,
    required this.totalLegs,
    required this.nextWaypointDistance,
    this.activeColor = const Color(0xFF2979FF),
    this.secondaryColor = const Color(0xFF757575),
  });

  @override
  Widget build(BuildContext context) {
    // Completed leg color (green tint of active color)
    final completedColor = Color.lerp(activeColor, Colors.green, 0.5)!;
    // Inactive leg color (dimmed secondary)
    final inactiveColor = secondaryColor.withAlpha(100);

    return Row(
      children: [
        // Dot indicators for legs
        for (int i = 0; i < totalLegs; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Container(
            width: i <= currentLeg ? 12 : 8,
            height: i <= currentLeg ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < currentLeg
                  ? completedColor
                  : i == currentLeg
                      ? activeColor
                      : inactiveColor,
            ),
          ),
        ],
        const SizedBox(width: 8),
        // Leg label
        Text(
          'Точка ${currentLeg + 1} из $totalLegs',
          style: TextStyle(
            fontSize: 12,
            color: secondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        // Distance to next waypoint
        if (currentLeg < totalLegs - 1)
          Text(
            'До точки: $nextWaypointDistance',
            style: TextStyle(
              fontSize: 12,
              color: activeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String value;
  final String label;
  final bool highlighted;
  final Color textColor;
  final Color secondaryColor;
  final Color highlightColor;

  const _InfoColumn({
    required this.value,
    required this.label,
    this.highlighted = false,
    this.textColor = const Color(0xDD000000), // Colors.black87
    this.secondaryColor = const Color(0xFF757575), // Grey shade 600
    this.highlightColor = const Color(0xFF388E3C), // Green shade 700
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: highlighted ? highlightColor : textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }
}
