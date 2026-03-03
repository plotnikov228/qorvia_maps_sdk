import 'package:flutter/material.dart';
import '../navigation_logger.dart';
import '../navigation_state.dart';
import 'lanes_indicator.dart';
import 'maneuver_icons.dart';
import 'traffic_signal_indicator.dart';

/// Default blue color for turn panel (Yandex Navigator style).
const Color kDefaultTurnPanelBlue = Color(0xFF2979FF);

/// Panel showing the next turn instruction.
///
/// Designed in Yandex Navigator style with:
/// - Blue background
/// - Compact layout
/// - Maneuver icon on the left
/// - Distance and street name
class NextTurnPanel extends StatelessWidget {
  final NavigationState state;
  final VoidCallback? onTap;

  /// Background color for the panel.
  final Color backgroundColor;

  /// Text color for the panel.
  final Color textColor;

  const NextTurnPanel({
    super.key,
    required this.state,
    this.onTap,
    this.backgroundColor = kDefaultTurnPanelBlue,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep;
    if (step == null) return const SizedBox.shrink();

    // Prefer verbalDistance if available, otherwise use formatted distance
    final displayDistance =
        step.verbalDistance ?? state.formattedDistanceToManeuver;

    NavigationLogger.debug('NextTurnPanel', 'Building panel', {
      'maneuver': step.maneuver,
      'distance': displayDistance,
      'roadName': step.name,
      'hasLanes': step.lanes.isNotEmpty,
      'hasTrafficSignal': step.hasTrafficSignal,
    });

    final hasRoadName = step.name != null && step.name!.isNotEmpty;
    final hasLanes = step.lanes.isNotEmpty;
    final hasTrafficSignal = step.hasTrafficSignal;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 280,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main instruction row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Maneuver icon with optional traffic signal
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ManeuverIcons.getIconWidget(
                        step.maneuver,
                        size: 32,
                        color: textColor,
                      ),
                      if (hasTrafficSignal)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: TrafficSignalIndicator(
                            hasTrafficSignal: true,
                            signalCount: step.trafficSignalCount,
                            showCount: false,
                            iconSize: 14,
                            iconColor: Colors.amber,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Distance (large) and instruction
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distance - large and bold
                        Text(
                          displayDistance,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Road name (if available)
            if (hasRoadName)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text(
                  step.name!,
                  style: TextStyle(
                    color: textColor.withAlpha(230),
                    fontSize: 14,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Lanes indicator (if available)
            if (hasLanes)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: LanesIndicator(
                  lanes: step.lanes,
                  iconSize: 24,
                  validColor: textColor,
                  invalidColor: textColor.withAlpha(102),
                  activeColor: Colors.amber,
                  backgroundColor: textColor.withAlpha(26),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact version of NextTurnPanel for smaller displays.
class CompactNextTurnPanel extends StatelessWidget {
  final NavigationState state;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;

  const CompactNextTurnPanel({
    super.key,
    required this.state,
    this.onTap,
    this.backgroundColor = kDefaultTurnPanelBlue,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep;
    if (step == null) return const SizedBox.shrink();

    final displayDistance =
        step.verbalDistance ?? state.formattedDistanceToManeuver;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ManeuverIcons.getIconWidget(
              step.maneuver,
              size: 28,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(
              displayDistance,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
