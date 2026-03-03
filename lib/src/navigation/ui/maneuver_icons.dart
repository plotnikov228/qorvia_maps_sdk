import 'package:flutter/material.dart';
import '../../models/route/route_step.dart';

/// Provides icons for navigation maneuvers.
class ManeuverIcons {
  /// Returns an icon for the given maneuver type.
  static IconData getIcon(String maneuver) {
    switch (maneuver) {
      case Maneuvers.depart:
        return Icons.trip_origin;
      case Maneuvers.arrive:
        return Icons.flag;
      case Maneuvers.turnLeft:
        return Icons.turn_left;
      case Maneuvers.turnRight:
        return Icons.turn_right;
      case Maneuvers.turnSlightLeft:
        return Icons.turn_slight_left;
      case Maneuvers.turnSlightRight:
        return Icons.turn_slight_right;
      case Maneuvers.turnSharpLeft:
        return Icons.turn_sharp_left;
      case Maneuvers.turnSharpRight:
        return Icons.turn_sharp_right;
      case Maneuvers.uturn:
        return Icons.u_turn_left;
      case Maneuvers.straight:
        return Icons.straight;
      case Maneuvers.merge:
        return Icons.merge;
      case Maneuvers.rampLeft:
        return Icons.ramp_left;
      case Maneuvers.rampRight:
        return Icons.ramp_right;
      case Maneuvers.fork:
        return Icons.fork_right;
      case Maneuvers.roundabout:
      case Maneuvers.rotary:
        return Icons.roundabout_left;
      case Maneuvers.exitRoundabout:
        return Icons.roundabout_right;
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
