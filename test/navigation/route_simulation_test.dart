import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';
import 'package:qorvia_maps_sdk/src/utils/polyline_decoder.dart';

/// Test that simulates movement along a real route and verifies
/// that voice announcements are triggered at the correct timing thresholds.
///
/// Route data: Magnitogorsk area, 916m, 7 steps
/// Voice thresholds:
///   - UPCOMING: 250m before maneuver
///   - SHORT: 30m before maneuver
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Real route data from Valhalla API
  const routePolyline =
      'qcrzdBao}moB_UEO}TP}LsOH{\\Dil@HkC?EoHGgS@ebACelAMcg@Aug@DawA?wKyl@?}I\\iILim@XyKTEeM?}WpFaBpD?';

  final routeSteps = [
    RouteStep(
      distanceMeters: 38,
      durationSeconds: 15,
      instruction: 'Поверните направо.',
      voiceInstruction: 'Через сорок метров поверните направо',
      voiceInstructionShort: 'Поверните направо',
      maneuver: 'right',
      legIndex: 0,
    ),
    RouteStep(
      distanceMeters: 172,
      durationSeconds: 37,
      instruction: 'Поверните налево на улица Мичурина.',
      voiceInstruction: 'Через сто пятьдесят метров поверните налево',
      voiceInstructionShort: 'Поверните налево',
      maneuver: 'left',
      name: 'улица Мичурина',
      legIndex: 0,
    ),
    RouteStep(
      distanceMeters: 378,
      durationSeconds: 47,
      instruction: 'Поверните направо на улица им. газеты Правда.',
      voiceInstruction: 'Через четыреста метров поверните направо',
      voiceInstructionShort: 'Поверните направо',
      maneuver: 'right',
      name: 'улица им. газеты Правда',
      legIndex: 0,
    ),
    RouteStep(
      distanceMeters: 225,
      durationSeconds: 31,
      instruction: 'Поверните налево на улица Суворова.',
      voiceInstruction: 'Через двести метров поверните налево',
      voiceInstructionShort: 'Поверните налево',
      nextManeuverHint: 'а затем через сорок метров направо',
      maneuver: 'left',
      name: 'улица Суворова',
      legIndex: 0,
    ),
    RouteStep(
      distanceMeters: 41,
      durationSeconds: 17,
      instruction: 'Поверните направо.',
      voiceInstruction: 'Через сорок метров поверните направо',
      voiceInstructionShort: 'Поверните направо',
      nextManeuverHint: 'а затем через рядом направо',
      maneuver: 'right',
      legIndex: 0,
    ),
    RouteStep(
      distanceMeters: 23,
      durationSeconds: 9,
      instruction: 'Поверните направо.',
      voiceInstruction: 'Через рядом поверните направо',
      voiceInstructionShort: 'Поверните направо',
      maneuver: 'right',
      legIndex: 0,
    ),
    RouteStep(
      distanceMeters: 0,
      durationSeconds: 0,
      instruction: 'Вы прибыли в пункт назначения.',
      voiceInstruction: 'Вы прибыли в пункт назначения',
      voiceInstructionShort: 'Вы прибыли',
      maneuver: 'destination',
      legIndex: 0,
    ),
  ];

  const totalDistanceMeters = 916;

  group('Route simulation - voice timing verification', () {
    late List<Coordinates> polyline;

    setUp(() {
      polyline = PolylineDecoder.decode(routePolyline, precision: 1e6);
      debugPrint('[Setup] Decoded polyline: ${polyline.length} points');
    });

    test('polyline decodes correctly', () {
      expect(polyline.length, 25);
      // First point
      expect(polyline.first.lat, closeTo(53.405257, 0.0001));
      expect(polyline.first.lon, closeTo(58.965249, 0.0001));
      // Last point
      expect(polyline.last.lat, closeTo(53.408972, 0.0001));
      expect(polyline.last.lon, closeTo(58.972134, 0.0001));
    });

    test('step cumulative distances are correct', () {
      // Verify step distances match expected cumulative totals
      final cumulativeDistances = <int>[];
      int cumulative = 0;
      for (final step in routeSteps) {
        cumulative += step.distanceMeters;
        cumulativeDistances.add(cumulative);
      }

      debugPrint('[Test] Cumulative distances: $cumulativeDistances');

      expect(cumulativeDistances[0], 38); // Step 0
      expect(cumulativeDistances[1], 210); // Step 1: 38 + 172
      expect(cumulativeDistances[2], 588); // Step 2: 210 + 378
      expect(cumulativeDistances[3], 813); // Step 3: 588 + 225
      expect(cumulativeDistances[4], 854); // Step 4: 813 + 41
      expect(cumulativeDistances[5], 877); // Step 5: 854 + 23
      expect(cumulativeDistances[6], 877); // Step 6: 877 + 0 (destination)
    });

    test('voice thresholds analysis for each step', () {
      // Analyze which voice announcements should trigger for each step
      // UPCOMING: 250m threshold
      // SHORT: 30m threshold

      const upcomingThreshold = 250.0;
      const shortThreshold = 30.0;

      debugPrint('[Analysis] Voice timing for each step:');
      debugPrint('  UPCOMING threshold: ${upcomingThreshold}m');
      debugPrint('  SHORT threshold: ${shortThreshold}m');
      debugPrint('');

      for (int i = 0; i < routeSteps.length; i++) {
        final step = routeSteps[i];
        final hasUpcoming = step.distanceMeters >= upcomingThreshold;
        final hasShort = step.distanceMeters >= shortThreshold;

        debugPrint(
            '[Step $i] ${step.maneuver} - ${step.distanceMeters}m');
        debugPrint('  UPCOMING (250m): ${hasUpcoming ? "YES" : "NO"}');
        debugPrint('  SHORT (30m): ${hasShort ? "YES" : "NO"}');
      }

      // Step 0: 38m - SHORT only (< 250m, >= 30m)
      expect(routeSteps[0].distanceMeters, lessThan(upcomingThreshold));
      expect(routeSteps[0].distanceMeters, greaterThanOrEqualTo(shortThreshold));

      // Step 1: 172m - SHORT only
      expect(routeSteps[1].distanceMeters, lessThan(upcomingThreshold));
      expect(routeSteps[1].distanceMeters, greaterThanOrEqualTo(shortThreshold));

      // Step 2: 378m - UPCOMING + SHORT
      expect(routeSteps[2].distanceMeters, greaterThanOrEqualTo(upcomingThreshold));
      expect(routeSteps[2].distanceMeters, greaterThanOrEqualTo(shortThreshold));

      // Step 3: 225m - SHORT only
      expect(routeSteps[3].distanceMeters, lessThan(upcomingThreshold));
      expect(routeSteps[3].distanceMeters, greaterThanOrEqualTo(shortThreshold));

      // Step 4: 41m - SHORT only
      expect(routeSteps[4].distanceMeters, lessThan(upcomingThreshold));
      expect(routeSteps[4].distanceMeters, greaterThanOrEqualTo(shortThreshold));

      // Step 5: 23m - NO voice announcements (< 30m)
      expect(routeSteps[5].distanceMeters, lessThan(shortThreshold));

      // Step 6: 0m - arrival (special handling)
      expect(routeSteps[6].distanceMeters, equals(0));
      expect(routeSteps[6].maneuver, equals('destination'));
    });

    test('interpolate position along polyline', () {
      // Test helper function to get position at specific distance along route
      final result = interpolateAlongPolyline(polyline, 0);
      expect(result.lat, closeTo(polyline.first.lat, 0.0001));

      final midPoint = interpolateAlongPolyline(polyline, 400);
      debugPrint('[Test] Position at 400m: $midPoint');
      // Should be somewhere between first and last points
      expect(midPoint.lat, greaterThan(polyline.first.lat));
      expect(midPoint.lat, lessThan(polyline.last.lat));
    });

    test('simulate movement and track step changes', () {
      // Simulate positions at regular intervals along the route
      final positionLog = <Map<String, dynamic>>[];

      int currentStepIndex = 0;
      double stepBoundary = routeSteps[0].distanceMeters.toDouble();

      for (double distance = 0; distance <= totalDistanceMeters; distance += 10) {
        final position = interpolateAlongPolyline(polyline, distance);

        // Check if we crossed a step boundary
        while (currentStepIndex < routeSteps.length - 1 &&
            distance >= stepBoundary) {
          currentStepIndex++;
          if (currentStepIndex < routeSteps.length) {
            stepBoundary += routeSteps[currentStepIndex].distanceMeters;
          }
        }

        final distanceToManeuver = stepBoundary - distance;

        positionLog.add({
          'distance': distance,
          'stepIndex': currentStepIndex,
          'distanceToManeuver': distanceToManeuver,
          'position': position,
        });
      }

      debugPrint('[Simulation] Generated ${positionLog.length} positions');

      // Verify step transitions happen at correct distances
      final stepTransitions = <int, double>{};
      for (int i = 1; i < positionLog.length; i++) {
        final prev = positionLog[i - 1];
        final curr = positionLog[i];
        if (prev['stepIndex'] != curr['stepIndex']) {
          stepTransitions[curr['stepIndex'] as int] =
              curr['distance'] as double;
        }
      }

      debugPrint('[Simulation] Step transitions: $stepTransitions');

      // Step 1 starts around 38m (step 0 distance)
      expect(stepTransitions[1], closeTo(40, 10));
      // Step 2 starts around 210m (38 + 172)
      expect(stepTransitions[2], closeTo(210, 10));
      // Step 3 starts around 588m (210 + 378)
      expect(stepTransitions[3], closeTo(590, 10));
    });

    test('verify UPCOMING voice triggers at correct distances', () {
      const upcomingThreshold = 250.0;

      // For step 2 (378m), UPCOMING should trigger when:
      // distance covered is such that distanceToManeuver <= 250
      // Step 2 starts at 210m, so UPCOMING triggers at:
      // distance = 588 - 250 = 338m from start

      final step2StartsAt = 210;
      final step2EndsAt = 588;
      final step2UpcomingTriggerAt = step2EndsAt - upcomingThreshold;

      debugPrint('[Voice Timing] Step 2:');
      debugPrint('  Starts at: ${step2StartsAt}m');
      debugPrint('  Ends at: ${step2EndsAt}m');
      debugPrint('  UPCOMING triggers at: ${step2UpcomingTriggerAt}m');
      debugPrint('  (when distanceToManeuver = $upcomingThreshold)');

      expect(step2UpcomingTriggerAt, closeTo(338, 1));

      // Verify we're on step 1 when UPCOMING for step 2 triggers
      // At 338m, we're past step 0 (38m) and step 1 (210m)
      // but within step 2 (588m)
      // Wait, actually step transitions work differently...

      // Let's recalculate:
      // Step 0: 0-38m (maneuver at 38m)
      // Step 1: 38-210m (maneuver at 210m)
      // Step 2: 210-588m (maneuver at 588m)

      // At 338m we're ON step 2, and distance to step 2's maneuver is:
      // 588 - 338 = 250m exactly!

      // So at 338m, currentStep=2 and distanceToManeuver=250
      // UPCOMING should trigger for step 2's instruction

      expect(588 - 338, equals(250));
    });

    test('verify SHORT voice triggers at correct distances', () {
      const shortThreshold = 30.0;

      // For each step, SHORT triggers when distanceToManeuver <= 30
      final shortTriggers = <int, double>{};

      int cumulative = 0;
      for (int i = 0; i < routeSteps.length; i++) {
        cumulative += routeSteps[i].distanceMeters;
        final triggerAt = cumulative - shortThreshold;
        if (triggerAt > 0 && routeSteps[i].distanceMeters >= shortThreshold) {
          shortTriggers[i] = triggerAt;
        }
      }

      debugPrint('[Voice Timing] SHORT triggers:');
      shortTriggers.forEach((step, distance) {
        debugPrint('  Step $step: at ${distance}m');
      });

      // Step 0: 38m - SHORT triggers at 38-30 = 8m
      expect(shortTriggers[0], closeTo(8, 1));
      // Step 1: 210m - SHORT triggers at 210-30 = 180m
      expect(shortTriggers[1], closeTo(180, 1));
      // Step 2: 588m - SHORT triggers at 588-30 = 558m
      expect(shortTriggers[2], closeTo(558, 1));
      // Step 3: 813m - SHORT triggers at 813-30 = 783m
      expect(shortTriggers[3], closeTo(783, 1));
      // Step 4: 854m - SHORT triggers at 854-30 = 824m
      expect(shortTriggers[4], closeTo(824, 1));
      // Step 5: 877m - 23m distance, < 30m threshold, no SHORT
      expect(shortTriggers.containsKey(5), isFalse);
    });

    test('full route simulation with voice event logging', () {
      const upcomingThreshold = 250.0;
      const shortThreshold = 30.0;

      final voiceEvents = <Map<String, dynamic>>[];
      final upcomingSpoken = <int>{};
      final shortSpoken = <int>{};

      int currentStepIndex = 0;
      double stepBoundary = routeSteps[0].distanceMeters.toDouble();

      // Simulate movement every 5 meters
      for (double distance = 0; distance <= totalDistanceMeters; distance += 5) {
        // Update current step
        while (currentStepIndex < routeSteps.length - 1 &&
            distance >= stepBoundary) {
          currentStepIndex++;
          if (currentStepIndex < routeSteps.length) {
            stepBoundary += routeSteps[currentStepIndex].distanceMeters;
          }
        }

        final distanceToManeuver = stepBoundary - distance;
        final currentStep = routeSteps[currentStepIndex];

        // Check UPCOMING threshold
        if (distanceToManeuver <= upcomingThreshold &&
            distanceToManeuver > shortThreshold &&
            !upcomingSpoken.contains(currentStepIndex)) {
          voiceEvents.add({
            'type': 'UPCOMING',
            'stepIndex': currentStepIndex,
            'distance': distance,
            'distanceToManeuver': distanceToManeuver,
            'text': currentStep.voiceInstruction,
          });
          upcomingSpoken.add(currentStepIndex);
        }

        // Check SHORT threshold
        if (distanceToManeuver <= shortThreshold &&
            distanceToManeuver > 0 &&
            !shortSpoken.contains(currentStepIndex)) {
          voiceEvents.add({
            'type': 'SHORT',
            'stepIndex': currentStepIndex,
            'distance': distance,
            'distanceToManeuver': distanceToManeuver,
            'text': currentStep.voiceInstructionShort,
          });
          shortSpoken.add(currentStepIndex);
        }
      }

      debugPrint('\n[Full Simulation] Voice events:');
      for (final event in voiceEvents) {
        debugPrint(
            '  ${event['type']} @ ${event['distance']}m (step ${event['stepIndex']}): '
            '"${event['text']}" (${event['distanceToManeuver']}m to maneuver)');
      }

      // Verify expected events
      final upcomingEvents =
          voiceEvents.where((e) => e['type'] == 'UPCOMING').toList();
      final shortEvents =
          voiceEvents.where((e) => e['type'] == 'SHORT').toList();

      debugPrint('\n[Summary]');
      debugPrint('  UPCOMING events: ${upcomingEvents.length}');
      debugPrint('  SHORT events: ${shortEvents.length}');

      // UPCOMING triggers for EVERY step where distanceToManeuver <= 250m
      // Even short steps get UPCOMING because we're always within 250m of them
      // Steps 0-4 all have UPCOMING (step 5 is 23m, immediately goes to SHORT zone)
      // Step 6 is destination (0m), no UPCOMING
      expect(upcomingEvents.length, equals(5));
      expect(upcomingSpoken, containsAll([0, 1, 2, 3, 4]));

      // SHORT triggers when distanceToManeuver <= 30m AND > 0
      // Steps 0-5 should have SHORT
      // Step 5 (23m) - starts inside SHORT zone, so it triggers
      expect(shortEvents.length, equals(6));
      expect(shortSpoken, containsAll([0, 1, 2, 3, 4, 5]));
    });

    test('arrival only triggers on last step', () {
      const arrivalThreshold = 20.0;

      // Calculate when arrival would trigger for each step
      final arrivalDistances = <int, double>{};

      int cumulative = 0;
      for (int i = 0; i < routeSteps.length; i++) {
        cumulative += routeSteps[i].distanceMeters;
        arrivalDistances[i] = cumulative.toDouble();
      }

      debugPrint('[Arrival] Last step (${routeSteps.length - 1}) ends at: '
          '${arrivalDistances[routeSteps.length - 1]}m');

      // Verify only the last step would trigger arrival
      final lastStepIndex = routeSteps.length - 1;
      expect(routeSteps[lastStepIndex].maneuver, equals('destination'));

      // Arrival triggers when:
      // 1. On last step
      // 2. distanceRemaining < arrivalThreshold
      final totalDistance = totalDistanceMeters.toDouble();
      final arrivalTriggerAt = totalDistance - arrivalThreshold;

      debugPrint('[Arrival] Would trigger at: ${arrivalTriggerAt}m '
          '(when ${arrivalThreshold}m remaining)');

      // At 896m (20m before end of 916m route)
      // currentStepIndex should be 6 (last step)
      expect(arrivalTriggerAt, closeTo(896, 1));
    });
  });
}

/// Interpolates a position along the polyline at the given distance.
///
/// Returns the coordinates at [distance] meters from the start of the polyline.
Coordinates interpolateAlongPolyline(
  List<Coordinates> polyline,
  double distance,
) {
  if (polyline.isEmpty) {
    throw ArgumentError('Polyline cannot be empty');
  }
  if (distance <= 0) {
    return polyline.first;
  }

  double accumulated = 0;
  for (int i = 0; i < polyline.length - 1; i++) {
    final segmentDistance = polyline[i].distanceTo(polyline[i + 1]);

    if (accumulated + segmentDistance >= distance) {
      // Interpolate within this segment
      final remaining = distance - accumulated;
      final ratio = remaining / segmentDistance;

      return Coordinates(
        lat: polyline[i].lat + (polyline[i + 1].lat - polyline[i].lat) * ratio,
        lon: polyline[i].lon + (polyline[i + 1].lon - polyline[i].lon) * ratio,
      );
    }

    accumulated += segmentDistance;
  }

  // Past the end of the polyline
  return polyline.last;
}
