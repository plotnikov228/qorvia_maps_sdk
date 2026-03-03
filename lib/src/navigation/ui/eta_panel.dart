import 'package:flutter/material.dart';
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

  const CompactEtaPanel({
    super.key,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
            // Multi-waypoint progress indicator
            if (state.isMultiWaypoint)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _WaypointProgress(
                  currentLeg: state.currentLegIndex,
                  totalLegs: state.totalLegs,
                  nextWaypointDistance: state.formattedNextWaypointDistance,
                ),
              ),
            Row(
              children: [
                // Exit button
                _ExitButton(onTap: onTap),
                const SizedBox(width: 12),
                // Info columns
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoColumn(
                        value: state.formattedDurationRemaining,
                        label: 'Осталось',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _InfoColumn(
                        value: state.formattedDistanceRemaining,
                        label: 'Расстояние',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                      _InfoColumn(
                        value: state.formattedEta,
                        label: 'Прибытие',
                        highlighted: true,
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

class _ExitButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ExitButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 6),
              Text(
                'Выход',
                style: TextStyle(
                  color: Colors.red.shade700,
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

  const _WaypointProgress({
    required this.currentLeg,
    required this.totalLegs,
    required this.nextWaypointDistance,
  });

  @override
  Widget build(BuildContext context) {
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
                  ? Colors.green.shade400
                  : i == currentLeg
                      ? Colors.blue.shade400
                      : Colors.grey.shade300,
            ),
          ),
        ],
        const SizedBox(width: 8),
        // Leg label
        Text(
          'Точка ${currentLeg + 1} из $totalLegs',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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
              color: Colors.blue.shade600,
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

  const _InfoColumn({
    required this.value,
    required this.label,
    this.highlighted = false,
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
            color: highlighted ? Colors.green.shade700 : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
