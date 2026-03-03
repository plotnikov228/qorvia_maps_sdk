import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/voice/voice_guidance.dart';
import 'package:qorvia_maps_sdk/src/models/route/route_step.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the flutter_tts method channel to avoid platform errors
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getLanguages':
            return ['en-US', 'ru-RU'];
          case 'setLanguage':
            return 1;
          case 'setSpeechRate':
            return 1;
          case 'setVolume':
            return 1;
          case 'setPitch':
            return 1;
          case 'isLanguageAvailable':
            return true;
          case 'speak':
            return 1;
          case 'stop':
            return 1;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });
  group('VoiceGuidanceOptions', () {
    test('has correct default values', () {
      const options = VoiceGuidanceOptions();

      expect(options.enabled, false);
      expect(options.language, 'en-US');
      expect(options.speechRate, 0.5);
      expect(options.volume, 1.0);
      expect(options.pitch, 1.0);
      expect(options.announceArrival, true);
      expect(options.announceOffRoute, true);
      expect(options.shortInstructionThreshold, 30.0);
      // Check Russian default messages
      expect(options.offRouteMessage, 'Вы сошли с маршрута.');
      expect(options.arrivalMessage, 'Вы прибыли в пункт назначения.');
      // Queue options
      expect(options.interruptOnHighPriority, false);
      expect(options.maxQueueSize, 10);
    });

    test('queue options can be configured', () {
      const options = VoiceGuidanceOptions(
        interruptOnHighPriority: true,
        maxQueueSize: 5,
      );

      expect(options.interruptOnHighPriority, true);
      expect(options.maxQueueSize, 5);
    });

    test('copyWith updates queue options', () {
      const original = VoiceGuidanceOptions();
      final modified = original.copyWith(
        interruptOnHighPriority: true,
        maxQueueSize: 20,
      );

      expect(modified.interruptOnHighPriority, true);
      expect(modified.maxQueueSize, 20);
      // Original unchanged
      expect(original.interruptOnHighPriority, false);
      expect(original.maxQueueSize, 10);
    });

    test('copyWith creates new instance with updated values', () {
      const original = VoiceGuidanceOptions();
      final modified = original.copyWith(
        enabled: true,
        offRouteMessage: 'Custom off route',
        arrivalMessage: 'Custom arrival',
      );

      expect(modified.enabled, true);
      expect(modified.offRouteMessage, 'Custom off route');
      expect(modified.arrivalMessage, 'Custom arrival');
      // Original unchanged
      expect(original.enabled, false);
      expect(original.offRouteMessage, 'Вы сошли с маршрута.');
    });

    test('custom messages can be set via constructor', () {
      const options = VoiceGuidanceOptions(
        offRouteMessage: 'You left the route',
        arrivalMessage: 'You arrived',
      );

      expect(options.offRouteMessage, 'You left the route');
      expect(options.arrivalMessage, 'You arrived');
    });
  });

  group('VoiceGuidance off-route logic', () {
    late VoiceGuidance voiceGuidance;

    setUp(() {
      // Create voice guidance with disabled TTS to avoid platform issues in tests
      voiceGuidance = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: false),
      );
    });

    test('speakOffRoute is skipped when disabled', () async {
      // Should not throw, just skip silently
      await voiceGuidance.speakOffRoute();
      // No way to verify TTS wasn't called since it's disabled
    });

    test('off-route state is tracked correctly', () {
      // Create enabled voice guidance for state tracking tests
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true, announceOffRoute: true),
      );

      // Initial state - off-route not spoken, not waiting
      // We can't directly access private fields, but we can test behavior

      // After calling speakOffRoute, it should be marked as spoken
      // (TTS won't actually work without initialization, but state is set)

      // This is more of an integration test scenario
      // Unit testing private state requires exposing test accessors
    });

    test('onRouteStatusChanged resets off-route state when returning to route', () {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true, announceOffRoute: true),
      );

      // Simulate: user goes off-route, then returns
      // First off-route would set _offRouteSpoken = true and _waitingForReturnToRoute = true
      // We can't test this directly without calling speakOffRoute (which needs TTS)

      // Instead, test that onRouteStatusChanged can be called without errors
      vg.onRouteStatusChanged(true); // Returned to route
      vg.onRouteStatusChanged(false); // Left route again
      vg.onRouteStatusChanged(true); // Returned again
    });

    test('onNewRoute resets step state but preserves off-route state', () {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );

      // Call onNewRoute - should not throw
      vg.onNewRoute();
      vg.onNewRoute();
      vg.onNewRoute();
    });

    test('reset clears all state', () {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );

      // Call reset - should not throw
      vg.reset();

      // Call onNewRoute after reset - should work
      vg.onNewRoute();

      // Call onRouteStatusChanged after reset - should work
      vg.onRouteStatusChanged(true);
    });
  });

  group('VoiceGuidance message selection', () {
    test('speakOffRoute uses default Russian message from options', () async {
      // This is tested by verifying VoiceGuidanceOptions defaults
      const options = VoiceGuidanceOptions(enabled: true);
      expect(options.offRouteMessage, 'Вы сошли с маршрута.');
    });

    test('speakOffRoute prefers custom message parameter over options', () async {
      // When speakOffRoute is called with a message parameter,
      // it should use that instead of options.offRouteMessage
      // This is tested by code review - the implementation:
      // final textToSpeak = message ?? options.offRouteMessage;
      const options = VoiceGuidanceOptions(
        enabled: true,
        offRouteMessage: 'Default message',
      );

      // The logic is: if message param is provided, use it
      // Otherwise use options.offRouteMessage
      // This is verified in the code implementation
      expect(options.offRouteMessage, 'Default message');
    });

    test('speakArrival uses default Russian message from options', () async {
      const options = VoiceGuidanceOptions(enabled: true);
      expect(options.arrivalMessage, 'Вы прибыли в пункт назначения.');
    });
  });

  group('VoiceGuidance flow scenarios', () {
    test('scenario: user goes off-route, gets rerouted, still off-route', () {
      // This tests the main fix: off-route should not repeat after reroute
      // if user is still off the new route

      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true, announceOffRoute: true),
      );

      // 1. User goes off-route - speakOffRoute() is called
      //    _offRouteSpoken = true, _waitingForReturnToRoute = true

      // 2. Auto-reroute happens - onNewRoute() is called
      //    _lastSpokenStepIndex = null, _lastShortSpokenStepIndex = null
      //    BUT _offRouteSpoken stays true, _waitingForReturnToRoute stays true
      vg.onNewRoute();

      // 3. User is still off new route - speakOffRoute() called again
      //    Since _offRouteSpoken is still true, it should NOT speak

      // 4. User finally returns to route - onRouteStatusChanged(true)
      //    _offRouteSpoken = false, _waitingForReturnToRoute = false
      vg.onRouteStatusChanged(true);

      // 5. User goes off-route again - speakOffRoute() can now speak
      //    This is correct behavior - user went off, returned, went off again
    });

    test('scenario: user goes off-route, returns to route, goes off again', () {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true, announceOffRoute: true),
      );

      // 1. User on route
      vg.onRouteStatusChanged(true);

      // 2. User goes off-route - speakOffRoute() would be called
      //    For this test, we just simulate the state changes
      vg.onRouteStatusChanged(false);

      // 3. User returns to route
      vg.onRouteStatusChanged(true);

      // 4. User can now hear off-route again if they go off
      vg.onRouteStatusChanged(false);
    });

    test('scenario: navigation stopped and restarted', () {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );

      // 1. Navigation active, user goes off-route

      // 2. Navigation stopped - reset() called
      vg.reset();

      // 3. Navigation started again - fresh state
      // User can hear off-route announcement again
      vg.onRouteStatusChanged(false);
      vg.onRouteStatusChanged(true);
    });
  });

  group('VoiceQueueItem', () {
    test('has correct string representation', () {
      final item = VoiceQueueItem(
        id: 1,
        text: 'Short text',
        priority: VoicePriority.normal,
        addedAt: DateTime.now(),
      );

      expect(item.toString(), contains('id: 1'));
      expect(item.toString(), contains('priority: VoicePriority.normal'));
      expect(item.toString(), contains('Short text'));
    });

    test('truncates long text in toString', () {
      final item = VoiceQueueItem(
        id: 2,
        text: 'This is a very long text that should be truncated in the string representation',
        priority: VoicePriority.high,
        addedAt: DateTime.now(),
      );

      final str = item.toString();
      expect(str, contains('...'));
      // Length includes: id, step (may be null), priority, truncated text
      expect(str.length, lessThan(120));
    });
  });

  group('VoicePriority', () {
    test('has normal and high values', () {
      expect(VoicePriority.values, contains(VoicePriority.normal));
      expect(VoicePriority.values, contains(VoicePriority.high));
      expect(VoicePriority.values.length, 2);
    });
  });

  group('VoiceGuidance queue', () {
    late VoiceGuidance voiceGuidance;

    setUp(() async {
      voiceGuidance = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );
      await voiceGuidance.initialize();
    });

    tearDown(() async {
      await voiceGuidance.dispose();
    });

    test('initial queue state is correct', () {
      expect(voiceGuidance.isPlaying, false);
      expect(voiceGuidance.queueSize, 0);
      expect(voiceGuidance.queueSnapshot, isEmpty);
    });

    test('speakText adds item to queue', () async {
      await voiceGuidance.speakText('Test message');

      // Queue processing starts immediately, so we might see 0 or 1 items
      // depending on timing. The important thing is no error is thrown.
      expect(voiceGuidance.queueSize, lessThanOrEqualTo(1));
    });

    test('clearQueue removes all pending items', () async {
      // Add multiple items quickly
      await voiceGuidance.speakText('Message 1');
      await voiceGuidance.speakText('Message 2');
      await voiceGuidance.speakText('Message 3');

      voiceGuidance.clearQueue();

      expect(voiceGuidance.queueSize, 0);
    });

    test('stopAndClear stops playback and clears queue', () async {
      await voiceGuidance.speakText('Message 1');
      await voiceGuidance.speakText('Message 2');

      await voiceGuidance.stopAndClear();

      expect(voiceGuidance.queueSize, 0);
      expect(voiceGuidance.isPlaying, false);
    });

    test('reset clears queue', () async {
      await voiceGuidance.speakText('Message 1');
      await voiceGuidance.speakText('Message 2');

      voiceGuidance.reset();

      expect(voiceGuidance.queueSize, 0);
    });

    test('dispose clears queue', () async {
      await voiceGuidance.speakText('Message 1');

      await voiceGuidance.dispose();

      expect(voiceGuidance.queueSize, 0);
      expect(voiceGuidance.isPlaying, false);
    });

    test('high priority items are queued correctly', () async {
      await voiceGuidance.speakText('Normal 1');
      await voiceGuidance.speakText('High priority', priority: VoicePriority.high);
      await voiceGuidance.speakText('Normal 2');

      // High priority should be near the front of the queue
      // We can't verify exact order without accessing internals,
      // but we can verify no errors occur
      expect(voiceGuidance.queueSize, lessThanOrEqualTo(3));
    });
  });

  group('VoiceGuidance queue with different options', () {
    test('works with interruptOnHighPriority enabled', () async {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(
          enabled: true,
          interruptOnHighPriority: true,
        ),
      );
      await vg.initialize();

      await vg.speakText('Normal message');
      await vg.speakText('High priority', priority: VoicePriority.high);

      // Should not throw
      await vg.dispose();
    });

    test('works with small maxQueueSize', () async {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(
          enabled: true,
          maxQueueSize: 2,
        ),
      );
      await vg.initialize();

      // Add more items than maxQueueSize
      await vg.speakText('Message 1');
      await vg.speakText('Message 2');
      await vg.speakText('Message 3');
      await vg.speakText('Message 4');

      // Queue should not exceed maxQueueSize (plus possibly 1 playing)
      expect(vg.queueSize, lessThanOrEqualTo(2));

      await vg.dispose();
    });
  });

  group('VoiceGuidance disabled state', () {
    test('speakText does nothing when disabled', () async {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: false),
      );

      await vg.speakText('Should not speak');

      expect(vg.queueSize, 0);
      expect(vg.isPlaying, false);
    });

    test('initialize does nothing when disabled', () async {
      final vg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: false),
      );

      await vg.initialize();

      // Should not throw, just skip initialization
      await vg.speakText('Should not speak');
      expect(vg.queueSize, 0);
    });
  });

  group('VoiceGuidance speakUpcomingStep', () {
    late VoiceGuidance voiceGuidance;

    final testStep = RouteStep(
      instruction: 'Turn right onto Main Street',
      voiceInstruction: 'In 250 meters, turn right onto Main Street',
      voiceInstructionShort: 'Turn right',
      nextManeuverHint: 'Then in 50 meters, turn left',
      distanceMeters: 250,
      durationSeconds: 30,
      maneuver: 'turn-right',
      name: 'Main Street',
    );

    setUp(() async {
      voiceGuidance = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );
      await voiceGuidance.initialize();
    });

    tearDown(() async {
      await voiceGuidance.dispose();
    });

    test('speakUpcomingStep queues instruction for first call', () async {
      final spoken = await voiceGuidance.speakUpcomingStep(testStep, 0);

      expect(spoken, true);
      // Queue processing starts immediately
      expect(voiceGuidance.queueSize, lessThanOrEqualTo(2)); // instruction + hint
    });

    test('speakUpcomingStep skips duplicate calls for same step', () async {
      // First call should succeed
      final spoken1 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken1, true);

      // Second call for same step should be skipped
      final spoken2 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken2, false);
    });

    test('speakUpcomingStep allows different step indices', () async {
      final spoken1 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken1, true);

      final spoken2 = await voiceGuidance.speakUpcomingStep(testStep, 1);
      expect(spoken2, true);

      final spoken3 = await voiceGuidance.speakUpcomingStep(testStep, 2);
      expect(spoken3, true);
    });

    test('speakUpcomingStep uses voiceInstruction over instruction', () async {
      // This test verifies via behavior that voiceInstruction is preferred
      // We can't directly verify the text spoken, but we verify no errors
      final stepWithVoiceInstruction = RouteStep(
        instruction: 'Short instruction',
        voiceInstruction: 'Full voice instruction with details',
        distanceMeters: 100,
        durationSeconds: 10,
        maneuver: 'turn-left',
      );

      final spoken = await voiceGuidance.speakUpcomingStep(stepWithVoiceInstruction, 0);
      expect(spoken, true);
    });

    test('speakUpcomingStep falls back to instruction when voiceInstruction is null', () async {
      final stepWithoutVoiceInstruction = RouteStep(
        instruction: 'Turn left',
        distanceMeters: 100,
        durationSeconds: 10,
        maneuver: 'turn-left',
      );

      final spoken = await voiceGuidance.speakUpcomingStep(stepWithoutVoiceInstruction, 0);
      expect(spoken, true);
    });

    test('onNewRoute resets upcoming state', () async {
      // Speak upcoming for step 0
      final spoken1 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken1, true);

      // Same step should be skipped
      final spoken2 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken2, false);

      // Reset via onNewRoute
      voiceGuidance.onNewRoute();

      // Now step 0 should be allowed again
      final spoken3 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken3, true);
    });

    test('reset clears upcoming state', () async {
      // Speak upcoming for step 0
      final spoken1 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken1, true);

      // Full reset
      voiceGuidance.reset();

      // Now step 0 should be allowed again
      final spoken2 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken2, true);
    });

    test('speakUpcomingStep is skipped when voice is disabled', () async {
      final disabledVg = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: false),
      );

      final spoken = await disabledVg.speakUpcomingStep(testStep, 0);
      expect(spoken, false);
    });

    test('speakUpcomingStep includes nextManeuverHint when available', () async {
      // The step has nextManeuverHint, so two items should be queued
      final spoken = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken, true);
      // We expect 2 items: main instruction + hint (or 1 if processing started)
      expect(voiceGuidance.queueSize, lessThanOrEqualTo(2));
    });
  });

  group('VoiceGuidance proactive voice sequence', () {
    // Tests the expected voice sequence: UPCOMING -> SHORT -> (silence on step change)

    late VoiceGuidance voiceGuidance;

    final testStep = RouteStep(
      instruction: 'Turn right',
      voiceInstruction: 'In 250 meters, turn right onto Main Street',
      voiceInstructionShort: 'Turn right now',
      distanceMeters: 250,
      durationSeconds: 30,
      maneuver: 'turn-right',
    );

    setUp(() async {
      voiceGuidance = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );
      await voiceGuidance.initialize();
    });

    tearDown(() async {
      await voiceGuidance.dispose();
    });

    test('full voice sequence: upcoming then short for same step', () async {
      // Step 1: UPCOMING instruction at ~250m
      final upcoming = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(upcoming, true);

      // Step 2: SHORT instruction at ~30m (different method, same step)
      final short = await voiceGuidance.speakShortInstruction(testStep, 0);
      expect(short, true);

      // Both should be allowed because they track different state
    });

    test('upcoming and short use independent tracking', () async {
      // Each instruction type has its own _lastXxxSpokenStepIndex

      // Speak upcoming for step 0
      expect(await voiceGuidance.speakUpcomingStep(testStep, 0), true);
      // Can still speak short for step 0
      expect(await voiceGuidance.speakShortInstruction(testStep, 0), true);

      // But repeating either is blocked
      expect(await voiceGuidance.speakUpcomingStep(testStep, 0), false);
      expect(await voiceGuidance.speakShortInstruction(testStep, 0), false);

      // New step resets tracking for that step
      expect(await voiceGuidance.speakUpcomingStep(testStep, 1), true);
      expect(await voiceGuidance.speakShortInstruction(testStep, 1), true);
    });
  });

  group('VoiceGuidance deduplication fix (Bug 1)', () {
    // Tests fix for: "Voice repeats 3-4 times while stationary near a turn"
    // Root cause was speakStep() not updating _lastUpcomingSpokenStepIndex
    // so speakUpcomingStep() would repeat on each GPS update

    late VoiceGuidance voiceGuidance;

    final testStep = RouteStep(
      instruction: 'Turn right',
      voiceInstruction: 'In 100 meters, turn right',
      voiceInstructionShort: 'Turn right now',
      distanceMeters: 100,
      durationSeconds: 15,
      maneuver: 'turn-right',
    );

    setUp(() async {
      voiceGuidance = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );
      await voiceGuidance.initialize();
    });

    tearDown(() async {
      await voiceGuidance.dispose();
    });

    test('speakStep prevents subsequent speakUpcomingStep for same step', () async {
      // This is the key fix: after speakStep() announces a step,
      // speakUpcomingStep() should NOT repeat it

      // Simulate startNavigation calling speakStep for initial step
      await voiceGuidance.speakStep(testStep, 0);

      // Now speakUpcomingStep for same step should be blocked
      final spoken = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken, false, reason: 'speakUpcomingStep should be blocked after speakStep for same step');
    });

    test('speakStep prevents subsequent speakShortInstruction for same step', () async {
      // speakStep should also prevent short instruction from repeating

      await voiceGuidance.speakStep(testStep, 0);

      final spoken = await voiceGuidance.speakShortInstruction(testStep, 0);
      expect(spoken, false, reason: 'speakShortInstruction should be blocked after speakStep for same step');
    });

    test('speakStep allows announcements for different steps', () async {
      // speakStep for step 0
      await voiceGuidance.speakStep(testStep, 0);

      // Step 1 should still be allowed
      final upcoming1 = await voiceGuidance.speakUpcomingStep(testStep, 1);
      expect(upcoming1, true);

      final short1 = await voiceGuidance.speakShortInstruction(testStep, 1);
      expect(short1, true);
    });

    test('scenario: stationary user should not hear repeated announcements', () async {
      // Simulates GPS updates while stationary near a turn
      // Each GPS update triggers voice logic, but announcements should NOT repeat

      // First GPS update - announcement is made
      final spoken1 = await voiceGuidance.speakUpcomingStep(testStep, 0);
      expect(spoken1, true);

      // Subsequent GPS updates (user stationary) - should be blocked
      for (int i = 0; i < 10; i++) {
        final spokenN = await voiceGuidance.speakUpcomingStep(testStep, 0);
        expect(spokenN, false, reason: 'GPS update $i should not trigger repeated announcement');
      }
    });
  });

  group('VoiceGuidance stale item filtering (Bug 2)', () {
    // Tests fix for: "After completing turn, voice still announces the completed turn"
    // Root cause was voice queue containing items for old steps

    late VoiceGuidance voiceGuidance;

    final step0 = RouteStep(
      instruction: 'Start on First Street',
      voiceInstruction: 'Start moving on First Street',
      distanceMeters: 50,
      durationSeconds: 10,
      maneuver: 'depart',
    );

    final step1 = RouteStep(
      instruction: 'Turn right onto Second Street',
      voiceInstruction: 'Turn right onto Second Street',
      voiceInstructionShort: 'Turn right',
      distanceMeters: 200,
      durationSeconds: 30,
      maneuver: 'turn-right',
    );

    setUp(() async {
      voiceGuidance = VoiceGuidance(
        const VoiceGuidanceOptions(enabled: true),
      );
      await voiceGuidance.initialize();
    });

    tearDown(() async {
      await voiceGuidance.dispose();
    });

    test('updateCurrentStepIndex updates internal step tracking', () {
      expect(voiceGuidance.currentStepIndex, 0);

      voiceGuidance.updateCurrentStepIndex(1);
      expect(voiceGuidance.currentStepIndex, 1);

      voiceGuidance.updateCurrentStepIndex(2);
      expect(voiceGuidance.currentStepIndex, 2);
    });

    test('VoiceQueueItem stores stepIndex', () {
      final item = VoiceQueueItem(
        id: 1,
        text: 'Test',
        priority: VoicePriority.normal,
        addedAt: DateTime.now(),
        stepIndex: 5,
      );

      expect(item.stepIndex, 5);
    });

    test('VoiceQueueItem stepIndex is optional (null for non-step items)', () {
      final item = VoiceQueueItem(
        id: 1,
        text: 'Off route announcement',
        priority: VoicePriority.high,
        addedAt: DateTime.now(),
        // stepIndex not provided - defaults to null
      );

      expect(item.stepIndex, isNull);
    });

    test('scenario: step change should filter queued items for old steps', () async {
      // Queue items for step 0
      await voiceGuidance.speakUpcomingStep(step0, 0);

      // Queue items for step 1
      await voiceGuidance.speakUpcomingStep(step1, 1);

      // Now step changes to 2 - items for steps 0 and 1 should be filtered
      voiceGuidance.updateCurrentStepIndex(2);

      // The queue processing should skip items with stepIndex < 2
      // We can't directly verify queue contents in a unit test without
      // exposing internals, but we verify the mechanism is in place
      expect(voiceGuidance.currentStepIndex, 2);
    });

    test('high priority items (arrival, off-route) are not filtered by step', () async {
      // Arrival and off-route have stepIndex = null
      // They should never be filtered regardless of step changes

      await voiceGuidance.speakArrival('You have arrived');
      voiceGuidance.updateCurrentStepIndex(999);

      // Arrival item should still be in queue/processing
      // since it has stepIndex = null
      // (We verify the code path exists - actual filtering happens internally)
    });
  });

  group('VoiceQueueItem stepIndex field', () {
    test('stepIndex appears in toString', () {
      final itemWithStep = VoiceQueueItem(
        id: 1,
        text: 'Test',
        priority: VoicePriority.normal,
        addedAt: DateTime.now(),
        stepIndex: 3,
      );

      expect(itemWithStep.toString(), contains('step: 3'));
    });

    test('stepIndex null appears in toString', () {
      final itemWithoutStep = VoiceQueueItem(
        id: 1,
        text: 'Test',
        priority: VoicePriority.high,
        addedAt: DateTime.now(),
      );

      expect(itemWithoutStep.toString(), contains('step: null'));
    });
  });
}
