import 'package:flutter/material.dart';
import '../../models/route/route_step.dart';

/// Provides icons for navigation maneuvers.
///
/// Handles both standard SDK maneuver types (e.g., "turn-left") and
/// short-form API aliases (e.g., "left") as a defensive measure.
class ManeuverIcons {
  /// Returns an icon for the given maneuver type.
  ///
  /// Accepts both standard SDK formats ("turn-left") and short API forms ("left").
  static IconData getIcon(String maneuver) {
    switch (maneuver) {
      // === Depart / Arrive ===
      case Maneuvers.depart:
        return Icons.trip_origin;
      case Maneuvers.arrive:
        return Icons.flag;

      // === Left turns (standard + API aliases) ===
      case Maneuvers.turnLeft:
      case Maneuvers.left: // API alias
        return Icons.turn_left;

      // === Right turns (standard + API aliases) ===
      case Maneuvers.turnRight:
      case Maneuvers.right: // API alias
        return Icons.turn_right;

      // === Slight left (standard + API aliases) ===
      case Maneuvers.turnSlightLeft:
      case Maneuvers.slightLeft: // API alias
      case 'slight_left': // underscore variant
        return Icons.turn_slight_left;

      // === Slight right (standard + API aliases) ===
      case Maneuvers.turnSlightRight:
      case Maneuvers.slightRight: // API alias
      case 'slight_right': // underscore variant
        return Icons.turn_slight_right;

      // === Sharp left (standard + API aliases) ===
      case Maneuvers.turnSharpLeft:
      case Maneuvers.sharpLeft: // API alias
      case 'sharp_left': // underscore variant
        return Icons.turn_sharp_left;

      // === Sharp right (standard + API aliases) ===
      case Maneuvers.turnSharpRight:
      case Maneuvers.sharpRight: // API alias
      case 'sharp_right': // underscore variant
        return Icons.turn_sharp_right;

      // === U-turn (standard + API aliases) ===
      case Maneuvers.uturn:
      case Maneuvers.uTurn: // API alias
      case 'u_turn': // underscore variant
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;

      // === Straight ===
      case Maneuvers.straight:
        return Icons.straight;

      // === Merge ===
      case Maneuvers.merge:
        return Icons.merge;

      // === Ramps ===
      case Maneuvers.rampLeft:
        return Icons.ramp_left;
      case Maneuvers.rampRight:
        return Icons.ramp_right;

      // === Fork ===
      case Maneuvers.fork:
        return Icons.fork_right;

      // === Roundabout ===
      case Maneuvers.roundabout:
      case Maneuvers.rotary:
        return Icons.roundabout_left;
      case Maneuvers.exitRoundabout:
        return Icons.roundabout_right;

      // === Default fallback ===
      default:
        return Icons.straight;
    }
  }

  /// Returns a widget with maneuver icon.
  static Widget getIconWidget(
    String maneuver, {
    double size = 32,
    Color color = Colors.white,
  }) {
    return Icon(
      getIcon(maneuver),
      size: size,
      color: color,
    );
  }
}
