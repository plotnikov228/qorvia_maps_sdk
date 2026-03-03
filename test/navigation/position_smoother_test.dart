import 'package:flutter_test/flutter_test.dart';
import 'package:qorvia_maps_sdk/src/navigation/tracking/position_smoother.dart';
import 'package:qorvia_maps_sdk/src/models/coordinates.dart';

void main() {
  group('PositionSmoother', () {
    late PositionSmoother smoother;

    setUp(() {
      smoother = PositionSmoother();
    });

    test('first position passes through unchanged', () {
      final raw = const Coordinates(lat: 50.0, lon: 30.0);
      final result = smoother.smooth(raw, 10.0);
      expect(result.lat, 50.0);
      expect(result.lon, 30.0);
    });

    test('dead zone filters micro-movements', () {
      final pos1 = const Coordinates(lat: 50.0, lon: 30.0);
      smoother.smooth(pos1, 5.0);

      // Move less than dead zone (0.15m)
      final pos2 = const Coordinates(lat: 50.000001, lon: 30.000001);
      final result = smoother.smooth(pos2, 5.0);

      // Should return the previous smoothed position
      expect(result.lat, 50.0);
      expect(result.lon, 30.0);
    });

    test('smooths position beyond dead zone', () {
      final pos1 = const Coordinates(lat: 50.0, lon: 30.0);
      smoother.smooth(pos1, 10.0);

      // Move well beyond dead zone
      final pos2 = const Coordinates(lat: 50.001, lon: 30.001);
      final result = smoother.smooth(pos2, 10.0);

      // Result should be between pos1 and pos2 (smoothed)
      expect(result.lat, greaterThan(50.0));
      expect(result.lat, lessThan(50.001));
      expect(result.lon, greaterThan(30.0));
      expect(result.lon, lessThan(30.001));
    });

    test('reset clears state', () {
      smoother.smooth(const Coordinates(lat: 50.0, lon: 30.0), 10.0);
      smoother.reset();
      expect(smoother.position, isNull);
    });

    test('high speed uses more responsive alpha', () {
      // Low speed: more smoothing
      final lowSmoother = PositionSmoother();
      lowSmoother.smooth(const Coordinates(lat: 50.0, lon: 30.0), 1.0);
      final lowResult = lowSmoother.smooth(
        const Coordinates(lat: 50.01, lon: 30.01),
        1.0,
      );

      // High speed: less smoothing (closer to raw)
      final highSmoother = PositionSmoother();
      highSmoother.smooth(const Coordinates(lat: 50.0, lon: 30.0), 20.0);
      final highResult = highSmoother.smooth(
        const Coordinates(lat: 50.01, lon: 30.01),
        20.0,
      );

      // High speed result should be closer to the target
      final lowDelta = (50.01 - lowResult.lat).abs();
      final highDelta = (50.01 - highResult.lat).abs();
      expect(highDelta, lessThan(lowDelta));
    });
  });
}
