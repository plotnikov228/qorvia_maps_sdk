import '../../models/coordinates.dart';
import '../../models/route/route_step.dart';
import '../navigation_logger.dart';
import '../navigation_options.dart';

/// Tracks user position relative to route polyline.
///
/// Responsibilities:
/// - Snap-to-route with hysteresis (enter 15m, exit 20m)
/// - Closest-point-on-route calculation (windowed search)
/// - Step progression detection with hysteresis
/// - Multi-leg/waypoint progress tracking
/// - Distance remaining calculation (per-leg and total)
/// - Off-route detection
class RouteTracker {
  final NavigationOptions options;
  final List<Coordinates> _polyline;
  final List<RouteStep> _steps;

  // Snap-to-route state
  bool _isSnapped = false;
  DateTime? _lastSnapChange;

  // Position on route
  int _closestSegmentIndex = 0;
  Coordinates? _snappedPosition;
  double _distanceFromRoute = 0;

  // Step tracking
  int _currentStepIndex = 0;
  int _currentLegIndex = 0;

  // Pre-computed cumulative distances per segment
  final List<double> _segmentCumulativeDistances = [];
  double _totalRouteDistance = 0;

  // Step boundary indices (segment index where each step starts)
  final List<int> _stepStartSegments = [];

  RouteTracker({
    required this.options,
    required List<Coordinates> polyline,
    required List<RouteStep> steps,
  })  : _polyline = polyline,
        _steps = steps {
    _precomputeDistances();
    _computeStepSegments();
  }

  // --- Public getters ---

  /// Whether the user is currently snapped to route.
  bool get isSnapped => _isSnapped;

  /// Snapped position on the route line (null if not snapped).
  Coordinates? get snappedPosition => _snappedPosition;

  /// Distance from user to the closest point on route, in meters.
  double get distanceFromRoute => _distanceFromRoute;

  /// Current step index (0-based).
  int get currentStepIndex => _currentStepIndex;

  /// Current leg index (0-based).
  int get currentLegIndex => _currentLegIndex;

  /// Current route step.
  RouteStep? get currentStep =>
      _currentStepIndex < _steps.length ? _steps[_currentStepIndex] : null;

  /// Closest segment index on the polyline.
  int get closestSegmentIndex => _closestSegmentIndex;

  /// Whether the user is off-route.
  bool get isOffRoute => _distanceFromRoute > options.offRouteThreshold;

  /// Total route distance in meters.
  double get totalRouteDistance => _totalRouteDistance;

  // --- Core update ---

  /// Updates tracking with a new user position.
  ///
  /// Returns a [RouteProgress] describing the current state.
  RouteProgress update(Coordinates userPosition, double speedMs) {
    // 1. Find closest point on route (windowed search)
    final closest = _findClosestPoint(userPosition);
    _closestSegmentIndex = closest.segmentIndex;
    _snappedPosition = closest.point;
    _distanceFromRoute = closest.distance;

    // 2. Update snap state with hysteresis
    _updateSnapState(closest.distance);

    // 3. Advance step (forward-only with hysteresis)
    _advanceStep(closest.segmentIndex, userPosition);

    // 4. Calculate distances
    final distanceTraveled = _closestSegmentIndex > 0
        ? _segmentCumulativeDistances[_closestSegmentIndex - 1] +
            (_polyline[_closestSegmentIndex].distanceTo(_snappedPosition!))
        : _polyline[0].distanceTo(_snappedPosition!);

    final distanceRemaining =
        (_totalRouteDistance - distanceTraveled).clamp(0.0, _totalRouteDistance);

    // 5. Calculate distance to next step
    final distanceToNextStep = _distanceToStepBoundary(_currentStepIndex + 1);

    // 6. Calculate leg-specific distances
    final legDistanceRemaining = _legDistanceRemaining();

    // 7. Effective position (snapped or raw)
    final effectivePosition = _isSnapped ? _snappedPosition! : userPosition;

    // 8. Route bearing at current segment
    final routeBearing = _routeBearingAt(_closestSegmentIndex);

    NavigationLogger.debug('RouteTracker', 'Update', {
      'step': _currentStepIndex,
      'leg': _currentLegIndex,
      'seg': _closestSegmentIndex,
      'offRoute': _distanceFromRoute,
      'snapped': _isSnapped,
      'remaining': distanceRemaining.round(),
    });

    return RouteProgress(
      effectivePosition: effectivePosition,
      snappedPosition: _snappedPosition!,
      routeBearing: routeBearing,
      isSnapped: _isSnapped,
      isOffRoute: isOffRoute,
      distanceFromRoute: _distanceFromRoute,
      currentStepIndex: _currentStepIndex,
      currentStep: currentStep,
      currentLegIndex: _currentLegIndex,
      distanceRemaining: distanceRemaining,
      distanceToNextStep: distanceToNextStep,
      legDistanceRemaining: legDistanceRemaining,
      closestSegmentIndex: _closestSegmentIndex,
    );
  }

  /// Resets tracker to initial state.
  void reset() {
    _isSnapped = false;
    _lastSnapChange = null;
    _closestSegmentIndex = 0;
    _snappedPosition = null;
    _distanceFromRoute = 0;
    _currentStepIndex = 0;
    _currentLegIndex = 0;
  }

  // --- Snap-to-route ---

  void _updateSnapState(double distance) {
    final now = DateTime.now();
    final cooldown = _lastSnapChange != null &&
        now.difference(_lastSnapChange!).inMilliseconds <
            options.snapTransitionDurationMs;

    if (cooldown) return; // hysteresis cooldown active

    if (!_isSnapped && distance <= options.snapToRouteThreshold) {
      _isSnapped = true;
      _lastSnapChange = now;
      NavigationLogger.debug('RouteTracker', 'Snap entered', {
        'distance': distance,
      });
    } else if (_isSnapped && distance > options.snapExitThreshold) {
      _isSnapped = false;
      _lastSnapChange = now;
      NavigationLogger.debug('RouteTracker', 'Snap exited', {
        'distance': distance,
      });
    }
  }

  // --- Closest point on route ---

  _ClosestPointResult _findClosestPoint(Coordinates point) {
    // Windowed search: only check segments near current index
    final windowSize = 20;
    final start = (_closestSegmentIndex - windowSize ~/ 2).clamp(0, _polyline.length - 2);
    final end = (_closestSegmentIndex + windowSize).clamp(0, _polyline.length - 1);

    double bestDist = double.infinity;
    int bestSeg = _closestSegmentIndex;
    Coordinates bestPoint = _polyline.isNotEmpty ? _polyline[0] : point;

    for (int i = start; i < end; i++) {
      final projected = _projectOntoSegment(point, _polyline[i], _polyline[i + 1]);
      final dist = point.distanceTo(projected);

      if (dist < bestDist) {
        bestDist = dist;
        bestSeg = i;
        bestPoint = projected;
      }
    }

    return _ClosestPointResult(
      point: bestPoint,
      segmentIndex: bestSeg,
      distance: bestDist,
    );
  }

  /// Projects a point onto a line segment, returning the closest point on segment.
  Coordinates _projectOntoSegment(
      Coordinates point, Coordinates segA, Coordinates segB) {
    final dx = segB.lon - segA.lon;
    final dy = segB.lat - segA.lat;

    if (dx == 0 && dy == 0) return segA;

    // Parameter t along the segment [0, 1]
    final t = ((point.lon - segA.lon) * dx + (point.lat - segA.lat) * dy) /
        (dx * dx + dy * dy);

    final clamped = t.clamp(0.0, 1.0);

    return Coordinates(
      lat: (segA.lat + clamped * dy).clamp(-90.0, 90.0),
      lon: (segA.lon + clamped * dx).clamp(-180.0, 180.0),
    );
  }

  // --- Step progression ---

  void _advanceStep(int segmentIndex, Coordinates userPosition) {
    if (_steps.isEmpty) return;

    // Find which step this segment belongs to
    int candidateStep = _currentStepIndex;
    for (int i = _currentStepIndex; i < _stepStartSegments.length; i++) {
      if (i + 1 < _stepStartSegments.length &&
          segmentIndex >= _stepStartSegments[i + 1]) {
        candidateStep = i + 1;
      } else {
        break;
      }
    }

    // Forward-only: step can only increase
    if (candidateStep <= _currentStepIndex) return;

    // Hysteresis: must be at least N meters past boundary
    if (candidateStep < _stepStartSegments.length) {
      final boundaryPoint = _polyline[_stepStartSegments[candidateStep]];
      final distPastBoundary = userPosition.distanceTo(boundaryPoint);

      // Only advance if we've passed the hysteresis distance
      // OR if we're well past the segment boundary
      if (distPastBoundary > options.stepTransitionHysteresis ||
          segmentIndex > _stepStartSegments[candidateStep] + 1) {
        final oldStep = _currentStepIndex;
        _currentStepIndex = candidateStep;

        // Update leg index
        final step = currentStep;
        if (step?.legIndex != null) {
          _currentLegIndex = step!.legIndex!;
        }

        NavigationLogger.info('RouteTracker', 'Step advanced', {
          'from': oldStep,
          'to': _currentStepIndex,
          'leg': _currentLegIndex,
        });
      }
    }
  }

  // --- Distance calculations ---

  double _distanceToStepBoundary(int stepIndex) {
    if (stepIndex >= _stepStartSegments.length) {
      // Distance to end of route
      return (_totalRouteDistance -
              (_closestSegmentIndex > 0
                  ? _segmentCumulativeDistances[_closestSegmentIndex - 1]
                  : 0))
          .clamp(0.0, _totalRouteDistance);
    }

    final targetSeg = _stepStartSegments[stepIndex];
    if (targetSeg <= _closestSegmentIndex) return 0;

    // Distance from current position to step boundary
    double dist = 0;
    if (_snappedPosition != null && _closestSegmentIndex + 1 < _polyline.length) {
      dist += _snappedPosition!.distanceTo(_polyline[_closestSegmentIndex + 1]);
    }
    for (int i = _closestSegmentIndex + 1; i < targetSeg && i + 1 < _polyline.length; i++) {
      dist += _polyline[i].distanceTo(_polyline[i + 1]);
    }
    return dist;
  }

  double _legDistanceRemaining() {
    // Find where current leg ends (next leg starts)
    for (int i = _currentStepIndex; i < _steps.length; i++) {
      final step = _steps[i];
      if (step.legIndex != null && step.legIndex! > _currentLegIndex) {
        // This step is in the next leg, so the boundary is at step i
        return _distanceToStepBoundary(i);
      }
    }
    // Current leg extends to end of route
    return _distanceToStepBoundary(_steps.length);
  }

  double _routeBearingAt(int segmentIndex) {
    if (segmentIndex + 1 >= _polyline.length) {
      return segmentIndex > 0
          ? _polyline[segmentIndex - 1].bearingTo(_polyline[segmentIndex])
          : 0;
    }
    return _polyline[segmentIndex].bearingTo(_polyline[segmentIndex + 1]);
  }

  // --- Pre-computation ---

  void _precomputeDistances() {
    _segmentCumulativeDistances.clear();
    double cumulative = 0;

    for (int i = 0; i < _polyline.length - 1; i++) {
      cumulative += _polyline[i].distanceTo(_polyline[i + 1]);
      _segmentCumulativeDistances.add(cumulative);
    }

    _totalRouteDistance = cumulative;

    NavigationLogger.debug('RouteTracker', 'Distances precomputed', {
      'segments': _polyline.length - 1,
      'totalDistance': _totalRouteDistance.round(),
    });
  }

  void _computeStepSegments() {
    // Approximate: distribute step start segments proportionally by distance
    _stepStartSegments.clear();
    if (_steps.isEmpty || _polyline.length < 2) return;

    // First step starts at segment 0
    _stepStartSegments.add(0);

    // For each subsequent step, estimate its start segment
    double cumulativeStepDist = 0;
    for (int i = 0; i < _steps.length - 1; i++) {
      cumulativeStepDist += _steps[i].distanceMeters;

      // Find the segment closest to this cumulative distance
      int seg = 0;
      for (int j = 0; j < _segmentCumulativeDistances.length; j++) {
        if (_segmentCumulativeDistances[j] >= cumulativeStepDist) {
          seg = j;
          break;
        }
        seg = j;
      }
      _stepStartSegments.add(seg.clamp(0, _polyline.length - 2));
    }

    NavigationLogger.debug('RouteTracker', 'Step segments computed', {
      'steps': _steps.length,
      'boundaries': _stepStartSegments.length,
    });
  }
}

/// Result of a route tracking update.
class RouteProgress {
  /// User position — snapped if on-route, raw if off-route.
  final Coordinates effectivePosition;

  /// Snapped position on route line.
  final Coordinates snappedPosition;

  /// Route bearing at the current position (degrees 0-360).
  final double routeBearing;

  /// Whether the user is snapped to route.
  final bool isSnapped;

  /// Whether the user is off-route.
  final bool isOffRoute;

  /// Distance from user to closest point on route (meters).
  final double distanceFromRoute;

  /// Current step index (0-based).
  final int currentStepIndex;

  /// Current route step (null if past all steps).
  final RouteStep? currentStep;

  /// Current leg index (0-based).
  final int currentLegIndex;

  /// Distance remaining to end of route (meters).
  final double distanceRemaining;

  /// Distance to the next step boundary (meters).
  final double distanceToNextStep;

  /// Distance remaining in the current leg (meters).
  final double legDistanceRemaining;

  /// Closest segment index on polyline.
  final int closestSegmentIndex;

  const RouteProgress({
    required this.effectivePosition,
    required this.snappedPosition,
    required this.routeBearing,
    required this.isSnapped,
    required this.isOffRoute,
    required this.distanceFromRoute,
    required this.currentStepIndex,
    required this.currentStep,
    required this.currentLegIndex,
    required this.distanceRemaining,
    required this.distanceToNextStep,
    required this.legDistanceRemaining,
    required this.closestSegmentIndex,
  });
}

/// Internal result of closest-point search.
class _ClosestPointResult {
  final Coordinates point;
  final int segmentIndex;
  final double distance;

  const _ClosestPointResult({
    required this.point,
    required this.segmentIndex,
    required this.distance,
  });
}
