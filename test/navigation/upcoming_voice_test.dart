import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/navigation_options.dart';
import 'package:qorvia_maps_sdk/src/navigation/voice/voice_guidance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationOptions upcomingInstructionThreshold', () {
    test('has default value of 250.0 meters', () {
      const options = NavigationOptions();

      expect(options.upcomingInstructionThreshold, 250.0);
    });

    test('can be configured via constructor', () {
      const options = NavigationOptions(
        upcomingInstructionThreshold: 300.0,
      );

      expect(options.upcomingInstructionThreshold, 300.0);
    });

    test('copyWith updates upcomingInstructionThreshold', () {
      const original = NavigationOptions();
      final modified = original.copyWith(
        upcomingInstructionThreshold: 400.0,
      );

      expect(modified.upcomingInstructionThreshold, 400.0);
      // Original unchanged
      expect(original.upcomingInstructionThreshold, 250.0);
    });

    test('default is greater than shortInstructionThreshold', () {
      const navOptions = NavigationOptions();

      // upcomingInstructionThreshold (250m) should be > shortInstructionThreshold (30m)
      expect(
        navOptions.upcomingInstructionThreshold,
        greaterThan(navOptions.voiceGuidanceOptions.shortInstructionThreshold),
      );
    });

    test('provides reasonable advance notice at typical speeds', () {
      const options = NavigationOptions();
      final threshold = options.upcomingInstructionThreshold;

      // At 60 km/h (16.67 m/s), 250m gives ~15 seconds notice
      const speed60kmh = 16.67; // m/s
      final timeAt60 = threshold / speed60kmh;
      expect(timeAt60, greaterThan(10)); // At least 10 seconds

      // At 30 km/h (8.33 m/s), 250m gives ~30 seconds notice
      const speed30kmh = 8.33; // m/s
      final timeAt30 = threshold / speed30kmh;
      expect(timeAt30, greaterThan(25)); // At least 25 seconds
    });
  });

  group('NavigationOptions voice timing integration', () {
    test('driving options have appropriate thresholds', () {
      final options = NavigationOptions.driving();

      // Default driving options should have default thresholds
      expect(options.upcomingInstructionThreshold, 250.0);
      expect(options.voiceGuidanceOptions.shortInstructionThreshold, 30.0);
    });

    test('walking options can have different thresholds', () {
      // Walking is slower, so thresholds could be adjusted
      final walking = NavigationOptions.walking();

      // Default walking still uses standard thresholds
      expect(walking.upcomingInstructionThreshold, 250.0);

      // But can be customized for pedestrian navigation
      final customWalking = walking.copyWith(
        upcomingInstructionThreshold: 100.0, // Shorter for walking
      );
      expect(customWalking.upcomingInstructionThreshold, 100.0);
    });

    test('all voice-related options work together', () {
      const options = NavigationOptions(
        enableVoiceInstructions: true,
        upcomingInstructionThreshold: 300.0,
        voiceGuidanceOptions: VoiceGuidanceOptions(
          enabled: true,
          shortInstructionThreshold: 50.0,
        ),
      );

      expect(options.enableVoiceInstructions, true);
      expect(options.upcomingInstructionThreshold, 300.0);
      expect(options.voiceGuidanceOptions.enabled, true);
      expect(options.voiceGuidanceOptions.shortInstructionThreshold, 50.0);
    });
  });

  group('Voice announcement timing scenarios', () {
    // These tests document the expected behavior of the voice timing system

    test('thresholds define non-overlapping zones', () {
      const options = NavigationOptions();
      final upcoming = options.upcomingInstructionThreshold;
      final short = options.voiceGuidanceOptions.shortInstructionThreshold;

      // UPCOMING zone: from upcoming threshold to short threshold
      // SHORT zone: from short threshold to 0
      // Zones should not overlap

      expect(upcoming, greaterThan(short));

      // There should be a gap between zones for safety
      expect(upcoming - short, greaterThan(100)); // At least 100m gap
    });

    test('documentation: expected voice sequence', () {
      // This test documents the expected voice sequence for a maneuver

      const options = NavigationOptions();

      // Distance zones:
      // 250m -> short threshold: UPCOMING zone (full instruction)
      // short threshold -> 0m: SHORT zone (short reminder)
      // step change (0m): NO VOICE (already announced)

      expect(options.upcomingInstructionThreshold, 250.0);
      expect(options.voiceGuidanceOptions.shortInstructionThreshold, 30.0);

      // Expected sequence:
      // 1. At ~250m: "In 250 meters, turn right onto Main Street"
      // 2. At ~30m: "Turn right"
      // 3. At 0m (step change): (silence - driver already turned)
    });
  });
}
