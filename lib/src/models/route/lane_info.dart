import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Direction indicators for a lane.
enum LaneDirection {
  /// Go straight.
  straight,

  /// Turn left.
  left,

  /// Turn right.
  right,

  /// Slight left turn.
  slightLeft,

  /// Slight right turn.
  slightRight,

  /// Sharp left turn.
  sharpLeft,

  /// Sharp right turn.
  sharpRight,

  /// U-turn.
  uturn,

  /// Merge to left lane.
  mergeToLeft,

  /// Merge to right lane.
  mergeToRight,

  /// No specific direction / unknown.
  none,
}

/// Extension for parsing LaneDirection from API strings.
extension LaneDirectionParsing on LaneDirection {
  /// Converts enum to API string format (snake_case).
  String toApiString() {
    switch (this) {
      case LaneDirection.straight:
        return 'straight';
      case LaneDirection.left:
        return 'left';
      case LaneDirection.right:
        return 'right';
      case LaneDirection.slightLeft:
        return 'slight_left';
      case LaneDirection.slightRight:
        return 'slight_right';
      case LaneDirection.sharpLeft:
        return 'sharp_left';
      case LaneDirection.sharpRight:
        return 'sharp_right';
      case LaneDirection.uturn:
        return 'uturn';
      case LaneDirection.mergeToLeft:
        return 'merge_to_left';
      case LaneDirection.mergeToRight:
        return 'merge_to_right';
      case LaneDirection.none:
        return 'none';
    }
  }

  /// Parses API string to LaneDirection enum.
  static LaneDirection fromApiString(String value) {
    switch (value) {
      case 'straight':
        return LaneDirection.straight;
      case 'left':
        return LaneDirection.left;
      case 'right':
        return LaneDirection.right;
      case 'slight_left':
        return LaneDirection.slightLeft;
      case 'slight_right':
        return LaneDirection.slightRight;
      case 'sharp_left':
        return LaneDirection.sharpLeft;
      case 'sharp_right':
        return LaneDirection.sharpRight;
      case 'uturn':
        return LaneDirection.uturn;
      case 'merge_to_left':
        return LaneDirection.mergeToLeft;
      case 'merge_to_right':
        return LaneDirection.mergeToRight;
      case 'none':
      default:
        debugPrint('[LaneDirection] Unknown direction: $value, defaulting to none');
        return LaneDirection.none;
    }
  }
}

/// Information about a single lane at a route step.
///
/// Contains direction indicators and validity status for navigation.
class LaneInfo extends Equatable {
  /// List of allowed directions for this lane.
  final List<LaneDirection> directions;

  /// Whether this lane is valid for the current maneuver.
  ///
  /// If true, the driver can use this lane to perform the upcoming turn.
  final bool valid;

  /// Whether this is the recommended/active lane.
  ///
  /// Note: Only available from Valhalla routing engine.
  /// OSRM always returns false for this field.
  final bool active;

  const LaneInfo({
    required this.directions,
    required this.valid,
    this.active = false,
  });

  /// Creates a LaneInfo from JSON data.
  factory LaneInfo.fromJson(Map<String, dynamic> json) {
    debugPrint('[LaneInfo.fromJson] Parsing lane info');

    final directionsJson = json['directions'] as List<dynamic>? ?? [];
    final directions = directionsJson
        .map((d) => LaneDirectionParsing.fromApiString(d as String))
        .toList();

    final valid = json['valid'] as bool? ?? false;
    final active = json['active'] as bool? ?? false;

    debugPrint('[LaneInfo.fromJson] directions: ${directions.map((d) => d.toApiString()).join(", ")}');
    debugPrint('[LaneInfo.fromJson] valid: $valid, active: $active');

    return LaneInfo(
      directions: directions,
      valid: valid,
      active: active,
    );
  }

  /// Converts this LaneInfo to JSON format.
  Map<String, dynamic> toJson() => {
        'directions': directions.map((d) => d.toApiString()).toList(),
        'valid': valid,
        'active': active,
      };

  /// Returns true if this lane has no direction indicators.
  bool get isEmpty => directions.isEmpty;

  /// Returns true if this lane has direction indicators.
  bool get isNotEmpty => directions.isNotEmpty;

  /// Returns true if this lane allows going straight.
  bool get allowsStraight => directions.contains(LaneDirection.straight);

  /// Returns true if this lane allows any left turn.
  bool get allowsLeft =>
      directions.contains(LaneDirection.left) ||
      directions.contains(LaneDirection.slightLeft) ||
      directions.contains(LaneDirection.sharpLeft);

  /// Returns true if this lane allows any right turn.
  bool get allowsRight =>
      directions.contains(LaneDirection.right) ||
      directions.contains(LaneDirection.slightRight) ||
      directions.contains(LaneDirection.sharpRight);

  @override
  List<Object?> get props => [directions, valid, active];

  @override
  String toString() =>
      'LaneInfo(directions: ${directions.map((d) => d.name).join(", ")}, valid: $valid, active: $active)';
}
