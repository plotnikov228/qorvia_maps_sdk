import '../../models/coordinates.dart';
import '../navigation_logger.dart';

/// Smooths position values using exponential moving average
/// with speed-adaptive alpha and dead zone filtering.
///
/// At low speeds, GPS jitter dominates so lower alpha (more smoothing).
/// At high speeds, position changes are real so higher alpha (more responsive).
class PositionSmoother {
  Coordinates? _smoothed;

  // Configuration
  final double alphaMin;
  final double alphaMax;
  final double deadZoneMeters;
  final double lowSpeedMs;
  final double highSpeedMs;

  PositionSmoother({
    this.alphaMin = 0.12,
    this.alphaMax = 0.28,
    this.deadZoneMeters = 0.15,
    this.lowSpeedMs = 2.0,
    this.highSpeedMs = 15.0,
  });

  /// Current smoothed position.
  Coordinates? get position => _smoothed;

  /// Smooths a raw position value.
  ///
  /// [raw] the new GPS position
  /// [speedMs] current speed in m/s
  ///
  /// Returns smoothed position. May return the previous position if
  /// the change is within the dead zone.
  Coordinates smooth(Coordinates raw, double speedMs) {
    if (_smoothed == null) {
      _smoothed = raw;
      return raw;
    }

    // Dead zone: skip micro-movements
    final delta = _smoothed!.distanceTo(raw);
    if (delta < deadZoneMeters) {
      NavigationLogger.debug('PositionSmoother', 'Dead zone skip', {
        'delta': delta,
        'threshold': deadZoneMeters,
      });
      return _smoothed!;
    }

    // Speed-adaptive alpha
    final speedFactor =
        ((speedMs - lowSpeedMs) / (highSpeedMs - lowSpeedMs)).clamp(0.0, 1.0);
    final alpha = alphaMin + (alphaMax - alphaMin) * speedFactor;

    // EMA: smoothed = smoothed + alpha * (raw - smoothed)
    final newLat = _smoothed!.lat + alpha * (raw.lat - _smoothed!.lat);
    final newLon = _smoothed!.lon + alpha * (raw.lon - _smoothed!.lon);

    _smoothed = Coordinates(lat: newLat, lon: newLon);
    return _smoothed!;
  }

  /// Resets smoother state.
  void reset() {
    _smoothed = null;
  }
}
