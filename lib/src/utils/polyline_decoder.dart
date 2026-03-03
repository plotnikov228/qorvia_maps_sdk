import 'dart:math' as math;
import '../models/coordinates.dart';

/// Decodes encoded polyline strings (Google Polyline Algorithm).
class PolylineDecoder {
  /// Decodes an encoded polyline string into a list of coordinates.
  ///
  /// The encoding algorithm is described here:
  /// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  ///
  /// [precision] - coordinate precision factor:
  ///   - 1e5 (100000) for Google / ORS format (default)
  ///   - 1e6 (1000000) for OSRM/Valhalla/Mapbox format
  static List<Coordinates> decode(String encoded, {double precision = 1e5}) {
    final List<Coordinates> points = [];
    int index = 0;
    int lat = 0;
    int lon = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final int deltaLat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      // Decode longitude
      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final int deltaLon = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lon += deltaLon;

      // Auto-detect precision mismatch on first point:
      // If decoded lat is outside valid range, the polyline likely uses
      // higher precision (1e6 instead of 1e5). Re-decode with 1e6.
      if (points.isEmpty) {
        final testLat = lat / precision;
        if (testLat.abs() > 90) {
          return decode(encoded, precision: precision * 10);
        }
      }

      points.add(Coordinates(
        lat: lat / precision,
        lon: lon / precision,
      ));
    }

    return points;
  }

  /// Encodes a list of coordinates into a polyline string.
  ///
  /// [precision] - coordinate precision factor (default 1e5 for Google/ORS format).
  static String encode(List<Coordinates> coordinates, {double precision = 1e5}) {
    final StringBuffer encoded = StringBuffer();
    int prevLat = 0;
    int prevLon = 0;

    for (final coord in coordinates) {
      final int lat = (coord.lat * precision).round();
      final int lon = (coord.lon * precision).round();

      _encodeValue(lat - prevLat, encoded);
      _encodeValue(lon - prevLon, encoded);

      prevLat = lat;
      prevLon = lon;
    }

    return encoded.toString();
  }

  static void _encodeValue(int value, StringBuffer encoded) {
    int v = value < 0 ? ~(value << 1) : (value << 1);

    while (v >= 0x20) {
      encoded.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }

    encoded.writeCharCode(v + 63);
  }

  /// Simplifies a polyline using Douglas-Peucker algorithm.
  ///
  /// [tolerance] is the maximum distance in meters a point can deviate.
  static List<Coordinates> simplify(
    List<Coordinates> points, {
    double tolerance = 10,
  }) {
    if (points.length <= 2) return points;

    // Find the point with maximum distance
    double maxDistance = 0;
    int maxIndex = 0;

    final first = points.first;
    final last = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than tolerance, recursively simplify
    if (maxDistance > tolerance) {
      final firstHalf = simplify(
        points.sublist(0, maxIndex + 1),
        tolerance: tolerance,
      );
      final secondHalf = simplify(
        points.sublist(maxIndex),
        tolerance: tolerance,
      );

      return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
    }

    return [first, last];
  }

  static double _perpendicularDistance(
    Coordinates point,
    Coordinates lineStart,
    Coordinates lineEnd,
  ) {
    final double dx = lineEnd.lon - lineStart.lon;
    final double dy = lineEnd.lat - lineStart.lat;

    if (dx == 0 && dy == 0) {
      return point.distanceTo(lineStart);
    }

    final double t = ((point.lon - lineStart.lon) * dx +
            (point.lat - lineStart.lat) * dy) /
        (dx * dx + dy * dy);

    final double clampedT = t.clamp(0.0, 1.0);

    final Coordinates closest = Coordinates(
      lat: lineStart.lat + clampedT * dy,
      lon: lineStart.lon + clampedT * dx,
    );

    return point.distanceTo(closest);
  }

  /// Smooths a polyline using Chaikin's corner-cutting algorithm.
  ///
  /// [iterations] - number of smoothing passes (1-3 recommended).
  /// [tension] - controls how much corners are cut (0.0-0.5, default 0.25).
  ///   Lower values = more aggressive smoothing.
  ///
  /// This algorithm preserves the start and end points while smoothing
  /// intermediate corners.
  static List<Coordinates> smooth(
    List<Coordinates> points, {
    int iterations = 2,
    double tension = 0.25,
  }) {
    if (points.length <= 2) return points;

    List<Coordinates> result = points;

    for (int iter = 0; iter < iterations; iter++) {
      result = _chaikinIteration(result, tension);
    }

    return result;
  }

  static List<Coordinates> _chaikinIteration(
    List<Coordinates> points,
    double tension,
  ) {
    if (points.length <= 2) return points;

    final List<Coordinates> smoothed = [];
    final double t1 = tension;
    final double t2 = 1.0 - tension;

    // Keep first point
    smoothed.add(points.first);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      // Calculate two new points that "cut" the corner
      final q = Coordinates(
        lat: (p0.lat * t2 + p1.lat * t1).clamp(-90.0, 90.0),
        lon: (p0.lon * t2 + p1.lon * t1).clamp(-180.0, 180.0),
      );
      final r = Coordinates(
        lat: (p0.lat * t1 + p1.lat * t2).clamp(-90.0, 90.0),
        lon: (p0.lon * t1 + p1.lon * t2).clamp(-180.0, 180.0),
      );

      // Skip Q for first segment to preserve start point
      if (i > 0) {
        smoothed.add(q);
      }
      // Skip R for last segment to preserve end point
      if (i < points.length - 2) {
        smoothed.add(r);
      }
    }

    // Keep last point
    smoothed.add(points.last);

    return smoothed;
  }

  /// Smooths a polyline with adaptive smoothing based on turn angles.
  ///
  /// Only smooths corners where the turn angle exceeds [minAngleDegrees].
  /// [smoothRadius] - distance in meters for the smoothing curve.
  static List<Coordinates> smoothAdaptive(
    List<Coordinates> points, {
    double minAngleDegrees = 30,
    double smoothRadius = 15,
    int pointsPerCorner = 5,
  }) {
    if (points.length <= 2) return points;

    final List<Coordinates> result = [points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      final angle = _calculateTurnAngle(prev, curr, next);

      if (angle.abs() >= minAngleDegrees) {
        // Add smoothed corner points
        final smoothedCorner = _smoothCorner(
          prev,
          curr,
          next,
          smoothRadius,
          pointsPerCorner,
        );
        result.addAll(smoothedCorner);
      } else {
        result.add(curr);
      }
    }

    result.add(points.last);
    return result;
  }

  static double _calculateTurnAngle(
    Coordinates prev,
    Coordinates curr,
    Coordinates next,
  ) {
    final dx1 = curr.lon - prev.lon;
    final dy1 = curr.lat - prev.lat;
    final dx2 = next.lon - curr.lon;
    final dy2 = next.lat - curr.lat;

    final angle1 = math.atan2(dy1, dx1);
    final angle2 = math.atan2(dy2, dx2);

    var delta = (angle2 - angle1) * (180.0 / math.pi);

    // Normalize to -180..180
    while (delta > 180) delta -= 360;
    while (delta < -180) delta += 360;

    return delta;
  }

  static List<Coordinates> _smoothCorner(
    Coordinates prev,
    Coordinates curr,
    Coordinates next,
    double radius,
    int numPoints,
  ) {
    // Convert radius from meters to approximate degrees
    // (very rough approximation, good enough for small distances)
    final radiusDeg = radius / 111000.0;

    // Vectors from corner
    final dx1 = prev.lon - curr.lon;
    final dy1 = prev.lat - curr.lat;
    final dx2 = next.lon - curr.lon;
    final dy2 = next.lat - curr.lat;

    // Normalize vectors
    final len1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
    final len2 = math.sqrt(dx2 * dx2 + dy2 * dy2);

    if (len1 == 0 || len2 == 0) return [curr];

    final ux1 = dx1 / len1;
    final uy1 = dy1 / len1;
    final ux2 = dx2 / len2;
    final uy2 = dy2 / len2;

    // Points on the edges at 'radius' distance from corner
    final p1 = Coordinates(
      lat: (curr.lat + uy1 * radiusDeg).clamp(-90.0, 90.0),
      lon: (curr.lon + ux1 * radiusDeg).clamp(-180.0, 180.0),
    );
    final p2 = Coordinates(
      lat: (curr.lat + uy2 * radiusDeg).clamp(-90.0, 90.0),
      lon: (curr.lon + ux2 * radiusDeg).clamp(-180.0, 180.0),
    );

    // Generate bezier curve points
    final List<Coordinates> curvePoints = [];
    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final point = _quadraticBezier(p1, curr, p2, t);
      curvePoints.add(point);
    }

    return curvePoints;
  }

  static Coordinates _quadraticBezier(
    Coordinates p0,
    Coordinates p1,
    Coordinates p2,
    double t,
  ) {
    final mt = 1.0 - t;
    final lat = mt * mt * p0.lat + 2 * mt * t * p1.lat + t * t * p2.lat;
    final lon = mt * mt * p0.lon + 2 * mt * t * p1.lon + t * t * p2.lon;
    return Coordinates(
      lat: lat.clamp(-90.0, 90.0),
      lon: lon.clamp(-180.0, 180.0),
    );
  }

}
