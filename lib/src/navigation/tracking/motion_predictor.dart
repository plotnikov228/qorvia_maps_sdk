import 'dart:math' as math;

import '../../models/coordinates.dart';
import '../../location/location_data.dart';

/// Physics-based position prediction using kinematic model.
///
/// Uses the equation: p = p0 + v*t + 0.5*a*t²
///
/// Features:
/// - Circular buffer of GPS samples
/// - Velocity and acceleration estimation
/// - Jerk detection for confidence scoring
/// - Route-constrained prediction
class MotionPredictor {
  final int bufferSize;
  final double maxJerkThreshold;
  final double minConfidence;
  final double maxPredictionTimeSec;
  final double maxPredictionDistanceM;

  final List<_MotionSample> _samples = [];

  MotionPredictor({
    this.bufferSize = 8,
    this.maxJerkThreshold = 5.0,
    this.minConfidence = 0.3,
    this.maxPredictionTimeSec = 2.0,
    this.maxPredictionDistanceM = 30.0,
  });

  /// Adds a GPS sample to the prediction buffer.
  void addSample(LocationData location) {
    _samples.add(_MotionSample(
      position: location.coordinates,
      speed: location.speed ?? 0,
      heading: location.heading ?? 0,
      timestamp: location.timestamp,
    ));

    // Keep buffer at max size
    while (_samples.length > bufferSize) {
      _samples.removeAt(0);
    }
  }

  /// Predicts position [ahead] duration into the future.
  ///
  /// Returns null if not enough samples or data is stale.
  PredictedPosition? predict(Duration ahead) {
    if (_samples.length < 2) return null;

    final latest = _samples.last;
    final now = DateTime.now();
    final staleness = now.difference(latest.timestamp);

    // Check if data is too stale (> 3 seconds)
    if (staleness.inMilliseconds > 3000) {
      return null;
    }

    // Total prediction time = staleness + ahead
    final totalAhead =
        staleness + ahead;
    var t = totalAhead.inMicroseconds / 1e6;

    // Clamp prediction time
    t = t.clamp(0, maxPredictionTimeSec);

    // Estimate velocity from last two samples
    final prev = _samples[_samples.length - 2];
    final dt = latest.timestamp.difference(prev.timestamp).inMicroseconds / 1e6;
    if (dt <= 0) return null;

    // Velocity in lat/lon degrees per second
    final vLat = (latest.position.lat - prev.position.lat) / dt;
    final vLon = (latest.position.lon - prev.position.lon) / dt;

    // Acceleration estimation from 3+ samples
    double aLat = 0, aLon = 0;
    double jerk = 0;
    if (_samples.length >= 3) {
      final prevPrev = _samples[_samples.length - 3];
      final dt2 =
          prev.timestamp.difference(prevPrev.timestamp).inMicroseconds / 1e6;
      if (dt2 > 0) {
        final vLatPrev = (prev.position.lat - prevPrev.position.lat) / dt2;
        final vLonPrev = (prev.position.lon - prevPrev.position.lon) / dt2;
        aLat = (vLat - vLatPrev) / dt;
        aLon = (vLon - vLonPrev) / dt;

        // Jerk estimation (change in acceleration)
        // Convert to approximate m/s³ using latitude scale
        final aMeters =
            math.sqrt(aLat * aLat + aLon * aLon) * 111000; // rough deg→m
        jerk = aMeters / dt;
      }
    }

    // Kinematic prediction: p = p0 + v*t + 0.5*a*t²
    var predLat = latest.position.lat + vLat * t + 0.5 * aLat * t * t;
    var predLon = latest.position.lon + vLon * t + 0.5 * aLon * t * t;

    // Clamp prediction distance
    final predDistance = Coordinates(lat: predLat, lon: predLon)
        .distanceTo(latest.position);
    if (predDistance > maxPredictionDistanceM) {
      final scale = maxPredictionDistanceM / predDistance;
      predLat = latest.position.lat +
          (predLat - latest.position.lat) * scale;
      predLon = latest.position.lon +
          (predLon - latest.position.lon) * scale;
    }

    // Clamp coordinates to valid range
    predLat = predLat.clamp(-90.0, 90.0);
    predLon = predLon.clamp(-180.0, 180.0);

    // Confidence scoring
    double confidence = 1.0;

    // Reduce confidence for few samples
    if (_samples.length < 4) {
      confidence *= 0.5 + 0.5 * (_samples.length / 4);
    }

    // Reduce confidence for stale data
    if (staleness.inMilliseconds > 500) {
      confidence *= math.max(
          0.3, 1.0 - (staleness.inMilliseconds - 500) / 2500);
    }

    // Reduce confidence for high jerk
    if (jerk > maxJerkThreshold) {
      confidence *= math.max(0.2, 1.0 - (jerk - maxJerkThreshold) / 20);
    }

    confidence = confidence.clamp(0.0, 1.0);

    // Predict bearing from velocity vector
    final bearing = _velocityBearing(vLat, vLon, latest.heading);

    final predicted = PredictedPosition(
      position: Coordinates(lat: predLat, lon: predLon),
      bearing: bearing,
      confidence: confidence,
      speed: latest.speed,
    );

    return confidence >= minConfidence ? predicted : null;
  }

  /// Predicts position constrained to the route geometry.
  ///
  /// Instead of free-space prediction, walks along the route polyline
  /// by the predicted distance.
  PredictedPosition? predictAlongRoute(
    Duration ahead,
    List<Coordinates> polyline,
    int currentSegmentIndex,
  ) {
    if (_samples.length < 2) return null;

    final latest = _samples.last;
    final speed = latest.speed;
    if (speed < 0.5) return null; // Too slow to predict

    final now = DateTime.now();
    final staleness = now.difference(latest.timestamp);
    final totalAhead = staleness + ahead;
    final t = (totalAhead.inMicroseconds / 1e6).clamp(0.0, maxPredictionTimeSec);

    // Distance to walk along route
    final distance = (speed * t).clamp(0.0, maxPredictionDistanceM);

    // Walk along route from current segment
    double remaining = distance;
    int segIdx = currentSegmentIndex.clamp(0, polyline.length - 2);
    Coordinates pos = latest.position;
    // Use route segment bearing (stable) instead of GPS heading (noisy)
    double bearing = segIdx < polyline.length - 1
        ? polyline[segIdx].bearingTo(polyline[segIdx + 1])
        : latest.heading;

    while (remaining > 0 && segIdx < polyline.length - 1) {
      final segEnd = polyline[segIdx + 1];
      final segDist = pos.distanceTo(segEnd);

      if (segDist >= remaining) {
        // Partial segment: interpolate
        final fraction = remaining / segDist;
        pos = Coordinates(
          lat: pos.lat + (segEnd.lat - pos.lat) * fraction,
          lon: pos.lon + (segEnd.lon - pos.lon) * fraction,
        );
        bearing = pos.bearingTo(segEnd);
        remaining = 0;
      } else {
        // Full segment consumed
        pos = segEnd;
        remaining -= segDist;
        segIdx++;
        if (segIdx < polyline.length - 1) {
          bearing = pos.bearingTo(polyline[segIdx + 1]);
        }
      }
    }

    // Confidence for route-constrained is generally higher
    double confidence = 0.9;
    if (_samples.length < 4) confidence *= 0.7;

    final staleSec = staleness.inMicroseconds / 1e6;
    if (staleSec > 0.5) {
      confidence *= math.max(0.4, 1.0 - (staleSec - 0.5) / 2.0);
    }

    return PredictedPosition(
      position: pos,
      bearing: bearing,
      confidence: confidence.clamp(0.0, 1.0),
      speed: speed,
    );
  }

  /// Whether the data is stale (> 2 seconds since last sample).
  bool get isStale {
    if (_samples.isEmpty) return true;
    return DateTime.now().difference(_samples.last.timestamp).inMilliseconds >
        2000;
  }

  /// Number of samples in buffer.
  int get sampleCount => _samples.length;

  /// Estimated current speed from last sample.
  double get estimatedSpeed =>
      _samples.isNotEmpty ? _samples.last.speed : 0;

  /// Resets the prediction buffer.
  void reset() {
    _samples.clear();
  }

  double _velocityBearing(double vLat, double vLon, double fallback) {
    final speed = math.sqrt(vLat * vLat + vLon * vLon);
    if (speed < 1e-9) return fallback;
    // atan2 with lon=x, lat=y for geographic bearing
    final rad = math.atan2(vLon, vLat);
    return (rad * 180 / math.pi + 360) % 360;
  }
}

/// Result of a position prediction.
class PredictedPosition {
  final Coordinates position;
  final double bearing;
  final double confidence;
  final double speed;

  const PredictedPosition({
    required this.position,
    required this.bearing,
    required this.confidence,
    required this.speed,
  });
}

class _MotionSample {
  final Coordinates position;
  final double speed;
  final double heading;
  final DateTime timestamp;

  const _MotionSample({
    required this.position,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });
}
