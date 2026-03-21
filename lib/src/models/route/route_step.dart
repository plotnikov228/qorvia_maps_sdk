import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'lane_info.dart';

/// A single step in a route with navigation instruction.
class RouteStep extends Equatable {
  /// Human-readable instruction for this step.
  final String instruction;

  /// Full voice instruction for TTS (e.g., "Приготовьтесь повернуть налево через двести метров").
  final String? voiceInstruction;

  /// Short voice instruction for TTS (e.g., "Через 200 м налево").
  final String? voiceInstructionShort;

  /// Hint about the next maneuver (e.g., "а затем через 50 метров направо").
  final String? nextManeuverHint;

  /// Distance in words (e.g., "двести метров").
  final String? verbalDistance;

  /// Distance of this step in meters.
  final int distanceMeters;

  /// Duration of this step in seconds.
  final int durationSeconds;

  /// Type of maneuver (e.g., "turn-right", "depart", "arrive").
  final String maneuver;

  /// Name of the road/street.
  final String? name;

  /// Speed limit in km/h for this step (null if data not available in OSM).
  final int? speedLimit;

  /// Lane information for this step.
  ///
  /// Empty list if lane data is not available.
  final List<LaneInfo> lanes;

  /// Whether there is a traffic signal at this step.
  ///
  /// Note: Only available from Valhalla routing engine.
  /// OSRM always returns false.
  final bool hasTrafficSignal;

  /// Number of traffic signals at this step.
  ///
  /// Note: Only available from Valhalla routing engine.
  /// OSRM always returns 0.
  final int trafficSignalCount;

  /// Index of the route leg (segment) this step belongs to.
  ///
  /// For routes with waypoints:
  /// - leg_index=0: origin → waypoint[0]
  /// - leg_index=1: waypoint[0] → waypoint[1]
  /// - leg_index=N: waypoint[N-1] → destination
  ///
  /// Null for routes without waypoints.
  final int? legIndex;

  /// Index of the waypoint reached at this step.
  ///
  /// Present only on the last step of each leg (except the final destination).
  /// For example, if waypoint_index=0, the user has reached the first waypoint.
  ///
  /// Null for steps that don't mark waypoint arrival.
  final int? waypointIndex;

  const RouteStep({
    required this.instruction,
    this.voiceInstruction,
    this.voiceInstructionShort,
    this.nextManeuverHint,
    this.verbalDistance,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuver,
    this.name,
    this.speedLimit,
    this.lanes = const [],
    this.hasTrafficSignal = false,
    this.trafficSignalCount = 0,
    this.legIndex,
    this.waypointIndex,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    debugPrint('[RouteStep.fromJson] Parsing step: ${json['maneuver']}');

    final voiceInstruction = json['voice_instruction'] as String?;
    final voiceInstructionShort = json['voice_instruction_short'] as String?;
    final nextManeuverHint = json['next_maneuver_hint'] as String?;
    final verbalDistance = json['verbal_distance'] as String?;
    final speedLimit = json['speed_limit'] as int?;

    if (voiceInstruction == null) {
      debugPrint('[RouteStep.fromJson] voice_instruction missing, using null');
    }
    if (voiceInstructionShort == null) {
      debugPrint('[RouteStep.fromJson] voice_instruction_short missing, using null');
    }
    if (speedLimit != null) {
      debugPrint('[RouteStep.fromJson] speed_limit: $speedLimit km/h');
    } else {
      debugPrint('[RouteStep.fromJson] speed_limit not available (OSM data missing)');
    }

    // Parse lanes
    final lanesJson = json['lanes'] as List<dynamic>? ?? [];
    final lanes = lanesJson
        .map((l) => LaneInfo.fromJson(l as Map<String, dynamic>))
        .toList();
    if (lanes.isNotEmpty) {
      debugPrint('[RouteStep.fromJson] lanes: ${lanes.length} lane(s)');
    }

    // Parse traffic signal info
    final hasTrafficSignal = json['has_traffic_signal'] as bool? ?? false;
    final trafficSignalCount = json['traffic_signal_count'] as int? ?? 0;
    if (hasTrafficSignal) {
      debugPrint('[RouteStep.fromJson] traffic_signal: $trafficSignalCount signal(s)');
    }

    // Parse waypoint leg info
    final legIndex = json['leg_index'] as int?;
    final waypointIndex = json['waypoint_index'] as int?;
    if (legIndex != null) {
      debugPrint('[RouteStep.fromJson] leg_index: $legIndex');
    }
    if (waypointIndex != null) {
      debugPrint('[RouteStep.fromJson] waypoint_index: $waypointIndex (reached waypoint)');
    }

    // Normalize maneuver to SDK-expected format
    final rawManeuver = json['maneuver'] as String;
    final maneuver = _normalizeManeuver(rawManeuver);

    return RouteStep(
      instruction: json['instruction'] as String,
      voiceInstruction: voiceInstruction,
      voiceInstructionShort: voiceInstructionShort,
      nextManeuverHint: nextManeuverHint,
      verbalDistance: verbalDistance,
      distanceMeters: json['distance_meters'] as int,
      durationSeconds: json['duration_seconds'] as int,
      maneuver: maneuver,
      name: json['name'] as String?,
      speedLimit: speedLimit,
      lanes: lanes,
      hasTrafficSignal: hasTrafficSignal,
      trafficSignalCount: trafficSignalCount,
      legIndex: legIndex,
      waypointIndex: waypointIndex,
    );
  }

  /// Normalizes API maneuver values to SDK-expected format.
  ///
  /// Some APIs return short forms like "left", "right" while SDK expects
  /// "turn-left", "turn-right". This method maps all known variations.
  static String _normalizeManeuver(String maneuver) {
    // Mapping of short-form API values to SDK-expected format
    const maneuverMap = {
      // Basic turns - API returns "left"/"right", SDK expects "turn-left"/"turn-right"
      'left': Maneuvers.turnLeft,
      'right': Maneuvers.turnRight,
      // Slight turns
      'slight-left': Maneuvers.turnSlightLeft,
      'slight_left': Maneuvers.turnSlightLeft,
      'slight-right': Maneuvers.turnSlightRight,
      'slight_right': Maneuvers.turnSlightRight,
      // Sharp turns
      'sharp-left': Maneuvers.turnSharpLeft,
      'sharp_left': Maneuvers.turnSharpLeft,
      'sharp-right': Maneuvers.turnSharpRight,
      'sharp_right': Maneuvers.turnSharpRight,
      // U-turn variations
      'u-turn': Maneuvers.uturn,
      'u_turn': Maneuvers.uturn,
      'uturn-left': Maneuvers.uturn,
      'uturn-right': Maneuvers.uturn,
    };

    final normalized = maneuverMap[maneuver] ?? maneuver;

    // Log only when normalization actually happens
    if (normalized != maneuver) {
      debugPrint(
          '[RouteStep._normalizeManeuver] Normalized "$maneuver" → "$normalized"');
    }

    return normalized;
  }

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        if (voiceInstruction != null) 'voice_instruction': voiceInstruction,
        if (voiceInstructionShort != null)
          'voice_instruction_short': voiceInstructionShort,
        if (nextManeuverHint != null) 'next_maneuver_hint': nextManeuverHint,
        if (verbalDistance != null) 'verbal_distance': verbalDistance,
        'distance_meters': distanceMeters,
        'duration_seconds': durationSeconds,
        'maneuver': maneuver,
        if (name != null) 'name': name,
        if (speedLimit != null) 'speed_limit': speedLimit,
        if (lanes.isNotEmpty) 'lanes': lanes.map((l) => l.toJson()).toList(),
        if (hasTrafficSignal) 'has_traffic_signal': hasTrafficSignal,
        if (trafficSignalCount > 0) 'traffic_signal_count': trafficSignalCount,
        if (legIndex != null) 'leg_index': legIndex,
        if (waypointIndex != null) 'waypoint_index': waypointIndex,
      };

  @override
  List<Object?> get props => [
        instruction,
        voiceInstruction,
        voiceInstructionShort,
        nextManeuverHint,
        verbalDistance,
        distanceMeters,
        durationSeconds,
        maneuver,
        name,
        speedLimit,
        lanes,
        hasTrafficSignal,
        trafficSignalCount,
        legIndex,
        waypointIndex,
      ];
}

/// Maneuver types for navigation.
///
/// Standard SDK maneuver values are used internally. Some APIs return
/// short-form aliases (e.g., "left" instead of "turn-left") which are
/// normalized by [RouteStep.fromJson].
abstract class Maneuvers {
  // === Standard SDK maneuver types ===
  static const String depart = 'depart';
  static const String arrive = 'arrive';
  static const String turnLeft = 'turn-left';
  static const String turnRight = 'turn-right';
  static const String turnSlightLeft = 'turn-slight-left';
  static const String turnSlightRight = 'turn-slight-right';
  static const String turnSharpLeft = 'turn-sharp-left';
  static const String turnSharpRight = 'turn-sharp-right';
  static const String uturn = 'uturn';
  static const String straight = 'straight';
  static const String merge = 'merge';
  static const String rampLeft = 'ramp-left';
  static const String rampRight = 'ramp-right';
  static const String fork = 'fork';
  static const String roundabout = 'roundabout';
  static const String rotary = 'rotary';
  static const String exitRoundabout = 'exit-roundabout';

  // === API aliases (short forms returned by some routing APIs) ===
  // These are normalized to standard forms in RouteStep.fromJson()
  static const String left = 'left'; // → turnLeft
  static const String right = 'right'; // → turnRight
  static const String slightLeft = 'slight-left'; // → turnSlightLeft
  static const String slightRight = 'slight-right'; // → turnSlightRight
  static const String sharpLeft = 'sharp-left'; // → turnSharpLeft
  static const String sharpRight = 'sharp-right'; // → turnSharpRight
  static const String uTurn = 'u-turn'; // → uturn
}
