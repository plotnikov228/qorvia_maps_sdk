import '../navigation_logger.dart';

/// Smooths bearing values using exponential moving average with
/// shortest-angle-delta and velocity limiting.
///
/// Features:
/// - Shortest-angle interpolation (handles 359° → 1° correctly)
/// - Velocity limiting (configurable max °/sec by speed)
/// - Speed-adaptive alpha (less smoothing at high speed)
class BearingSmoother {
  double? _smoothedBearing;
  double _angularVelocity = 0.0;

  // Configuration
  final double alphaMin;
  final double alphaMax;
  final double maxVelocityLowSpeed;
  final double maxVelocityHighSpeed;
  final double lowSpeedThreshold;
  final double highSpeedThreshold;

  BearingSmoother({
    this.alphaMin = 0.08,
    this.alphaMax = 0.15,
    this.maxVelocityLowSpeed = 30.0,
    this.maxVelocityHighSpeed = 60.0,
    this.lowSpeedThreshold = 5.0,
    this.highSpeedThreshold = 10.0,
  });

  /// Current smoothed bearing (null until first value fed).
  double? get bearing => _smoothedBearing;

  /// Smooths a raw bearing value.
  ///
  /// [rawBearing] in degrees (0-360)
  /// [speedMs] current speed in m/s (for adaptive alpha)
  /// [dt] time since last call
  ///
  /// Returns smoothed bearing in degrees (0-360).
  double smooth(double rawBearing, double speedMs, Duration dt) {
    if (_smoothedBearing == null) {
      _smoothedBearing = rawBearing;
      return rawBearing;
    }

    final dtSec = dt.inMicroseconds / 1e6;
    if (dtSec <= 0) return _smoothedBearing!;

    // Compute shortest-angle delta
    double delta = shortestAngleDelta(_smoothedBearing!, rawBearing);

    // Speed-adaptive alpha
    final speedFactor = ((speedMs - lowSpeedThreshold) /
            (highSpeedThreshold - lowSpeedThreshold))
        .clamp(0.0, 1.0);
    final alpha = alphaMin + (alphaMax - alphaMin) * speedFactor;

    // Velocity limiting — boost for large bearing deltas so real turns
    // track faster while GPS noise (< 20°) stays unchanged.
    var maxVelocity = maxVelocityLowSpeed +
        (maxVelocityHighSpeed - maxVelocityLowSpeed) * speedFactor;
    final absDelta = delta.abs();
    if (absDelta > 20.0) {
      maxVelocity *= 1.0 + (absDelta / 90.0);
    }
    final maxDelta = maxVelocity * dtSec;

    // Target angular velocity
    final targetVelocity = delta / dtSec;

    // Smooth angular velocity (damped spring-like)
    _angularVelocity = 0.8 * _angularVelocity + 0.2 * targetVelocity;

    // Clamp angular velocity
    final clampedVelocity = _angularVelocity.clamp(-maxVelocity, maxVelocity);

    // Apply clamped angular velocity instead of raw alpha*delta — this uses
    // the already-computed damped velocity for smoother, more predictable output.
    final velocityDelta = (clampedVelocity * dtSec).clamp(-maxDelta, maxDelta);
    final smoothedDelta = (alpha * delta).clamp(-maxDelta, maxDelta);

    // Blend: use velocity-based delta for large turns, alpha-based for small corrections
    final blend = (absDelta / 45.0).clamp(0.0, 1.0);
    final finalDelta = smoothedDelta * (1.0 - blend) + velocityDelta * blend;

    _smoothedBearing = (_smoothedBearing! + finalDelta) % 360;
    if (_smoothedBearing! < 0) _smoothedBearing = _smoothedBearing! + 360;

    NavigationLogger.debug('BearingSmoother', 'Smooth', {
      'input': rawBearing,
      'output': _smoothedBearing,
      'delta': delta,
      'alpha': alpha,
      'velocity': clampedVelocity,
    });

    return _smoothedBearing!;
  }

  /// Resets smoother state.
  void reset() {
    _smoothedBearing = null;
    _angularVelocity = 0.0;
  }

  /// Computes the shortest angle delta from [from] to [to] in degrees.
  /// Result is in range [-180, 180].
  static double shortestAngleDelta(double from, double to) {
    double delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return delta;
  }
}
