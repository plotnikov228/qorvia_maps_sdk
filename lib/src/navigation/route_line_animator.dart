import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../map/qorvia_map_controller.dart';
import '../models/coordinates.dart';
import '../route_display/route_line.dart';

/// Log levels for RouteLineAnimator
enum _LogLevel { debug, info }

/// Internal logger for RouteLineAnimator
void _log(_LogLevel level, String message, [Map<String, dynamic>? data]) {
  if (!kDebugMode) return;
  final prefix = '[RouteLineAnimator]';
  final levelStr = level.name.toUpperCase();
  if (data != null) {
    dev.log('$prefix [$levelStr] $message: $data', level: level == _LogLevel.info ? 800 : 500);
  } else {
    dev.log('$prefix [$levelStr] $message', level: level == _LogLevel.info ? 800 : 500);
  }
}

/// Helper class for managing route line animations.
///
/// This class provides a high-level interface for animating route line
/// start positions, useful for making routes "follow" moving markers
/// (e.g., helper position in help request sessions).
///
/// Key features:
/// - Stores original route coordinates for reference
/// - Tracks current animated positions for continuous animation
/// - Handles animation cancellation and cleanup
/// - Uses the underlying [QorviaMapController] for actual rendering
///
/// Example usage:
/// ```dart
/// final animator = RouteLineAnimator(controller);
///
/// // Store the original route
/// animator.setRouteCoordinates('helper_route', routeCoordinates);
///
/// // Animate route start to follow helper marker
/// await animator.animateStartPosition(
///   'helper_route',
///   helperPosition,
///   duration: Duration(milliseconds: 400),
/// );
///
/// // Cleanup when done
/// animator.dispose();
/// ```
class RouteLineAnimator {
  /// The map controller used for rendering route updates.
  final QorviaMapController controller;

  /// Stores current animated start position per route.
  /// Used to continue animation from current position when new animation starts.
  final Map<String, Coordinates> _animatedStartPositions = {};

  /// Active animation timers per route.
  final Map<String, Timer> _animations = {};

  /// Original route coordinates (immutable reference).
  /// Used to reconstruct route with animated start + remaining original points.
  final Map<String, List<Coordinates>> _originalRoutes = {};

  /// Route line options per route for styling.
  final Map<String, RouteLineOptions> _routeOptions = {};

  /// Creates a new RouteLineAnimator.
  ///
  /// [controller] - The map controller to use for route updates.
  RouteLineAnimator(this.controller);

  /// Stores original route coordinates for animation reference.
  ///
  /// Call this when a new route is fetched or displayed. The coordinates
  /// are used to reconstruct the route with animated start position.
  ///
  /// [routeId] - Unique identifier for the route
  /// [coordinates] - Original route coordinates from API
  /// [options] - Optional route styling options
  void setRouteCoordinates(
    String routeId,
    List<Coordinates> coordinates, {
    RouteLineOptions? options,
  }) {
    if (coordinates.isEmpty) {
      _log(_LogLevel.debug, 'setRouteCoordinates: empty coordinates, ignoring', {
        'routeId': routeId,
      });
      return;
    }

    _originalRoutes[routeId] = List.unmodifiable(coordinates);
    if (options != null) {
      _routeOptions[routeId] = options;
    }

    _log(_LogLevel.info, 'setRouteCoordinates', {
      'routeId': routeId,
      'points': coordinates.length,
      'hasOptions': options != null,
    });
  }

  /// Gets the original route coordinates for a route.
  List<Coordinates>? getRouteCoordinates(String routeId) {
    return _originalRoutes[routeId];
  }

  /// Gets the current animated start position for a route.
  ///
  /// Returns null if the route has no active animation history.
  Coordinates? getAnimatedStartPosition(String routeId) {
    return _animatedStartPositions[routeId];
  }

  /// Checks if a route has stored coordinates.
  bool hasRoute(String routeId) {
    return _originalRoutes.containsKey(routeId);
  }

  /// Checks if a route animation is currently running.
  bool isAnimating(String routeId) {
    return _animations.containsKey(routeId);
  }

  /// Animates the route start position to a new location.
  ///
  /// The animation smoothly interpolates the first coordinate of the route
  /// from its current animated position (or original position if no previous
  /// animation) to [newStart].
  ///
  /// Returns a Future that completes when the animation finishes.
  /// The Future completes immediately if:
  /// - Route doesn't exist
  /// - Distance is negligible (< 1 meter)
  ///
  /// [routeId] - ID of the route to animate
  /// [newStart] - Target position for the route start
  /// [duration] - Animation duration (default 300ms)
  /// [curve] - Easing curve (default Curves.easeInOut)
  Future<void> animateStartPosition(
    String routeId,
    Coordinates newStart, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    // Check if route exists in controller first to prevent creating duplicate routes
    if (!controller.hasRoute(routeId)) {
      _log(_LogLevel.debug, 'animateStartPosition: route not in controller, skipping', {
        'routeId': routeId,
        'hasLocalCoords': _originalRoutes.containsKey(routeId),
      });
      return;
    }

    final originalCoords = _originalRoutes[routeId];
    if (originalCoords == null || originalCoords.isEmpty) {
      _log(_LogLevel.debug, 'animateStartPosition: route coords not found in animator', {
        'routeId': routeId,
      });
      return;
    }

    // Cancel any existing animation
    cancelAnimation(routeId);

    // Use current animated position as start, or original first point
    final startPosition = _animatedStartPositions[routeId] ?? originalCoords.first;
    final startLat = startPosition.lat;
    final startLon = startPosition.lon;
    final endLat = newStart.lat;
    final endLon = newStart.lon;

    // Skip animation if distance is negligible (< 0.00001 degrees ≈ 1 meter)
    final latDiff = (endLat - startLat).abs();
    final lonDiff = (endLon - startLon).abs();
    if (latDiff < 0.00001 && lonDiff < 0.00001) {
      _log(_LogLevel.debug, 'animateStartPosition: skipping - distance too small', {
        'routeId': routeId,
      });
      return;
    }

    _log(_LogLevel.info, 'animateStartPosition: START', {
      'routeId': routeId,
      'from': '(${startLat.toStringAsFixed(6)}, ${startLon.toStringAsFixed(6)})',
      'to': '(${endLat.toStringAsFixed(6)}, ${endLon.toStringAsFixed(6)})',
      'duration': '${duration.inMilliseconds}ms',
    });

    final completer = Completer<void>();

    // Use ~60fps for smooth animation
    const frameInterval = Duration(milliseconds: 16);
    final totalSteps = (duration.inMilliseconds / frameInterval.inMilliseconds).ceil();
    var currentStep = 0;
    final startTime = DateTime.now();

    // Keep remaining route coordinates (all except first)
    final remainingCoords = originalCoords.length > 1
        ? originalCoords.sublist(1)
        : <Coordinates>[];

    final options = _routeOptions[routeId];

    final timer = Timer.periodic(frameInterval, (timer) async {
      currentStep++;

      // Calculate progress using elapsed time for more accurate timing
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final rawProgress = elapsed / duration.inMilliseconds;
      final progress = rawProgress.clamp(0.0, 1.0);

      // Apply easing curve
      final easedProgress = curve.transform(progress);

      // Interpolate position
      final lat = startLat + (endLat - startLat) * easedProgress;
      final lon = startLon + (endLon - startLon) * easedProgress;
      final currentAnimatedStart = Coordinates(lat: lat, lon: lon);

      // Store current animated position for continuous animation
      _animatedStartPositions[routeId] = currentAnimatedStart;

      // Build new coordinates with animated start + remaining original coords
      final newCoordinates = [currentAnimatedStart, ...remainingCoords];

      // Update route line via controller
      try {
        await controller.updateRouteLine(routeId, newCoordinates, options: options);
      } catch (e) {
        _log(_LogLevel.debug, 'animateStartPosition: updateRouteLine error', {
          'routeId': routeId,
          'error': e.toString(),
        });
        timer.cancel();
        _animations.remove(routeId);
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
        return;
      }

      // Complete animation
      if (progress >= 1.0 || currentStep >= totalSteps) {
        timer.cancel();
        _animations.remove(routeId);
        _log(_LogLevel.info, 'animateStartPosition: COMPLETE', {
          'routeId': routeId,
          'steps': currentStep,
          'actualDuration': '${elapsed}ms',
        });
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    _animations[routeId] = timer;

    return completer.future;
  }

  /// Immediately snaps the route start to a new position without animation.
  ///
  /// Use this when you need instant update without smooth transition,
  /// for example when teleporting or after significant position jumps.
  ///
  /// [routeId] - ID of the route to update
  /// [newStart] - New position for the route start
  Future<void> snapStartPosition(String routeId, Coordinates newStart) async {
    // Check if route exists in controller first to prevent creating duplicate routes
    if (!controller.hasRoute(routeId)) {
      _log(_LogLevel.debug, 'snapStartPosition: route not in controller, skipping', {
        'routeId': routeId,
        'hasLocalCoords': _originalRoutes.containsKey(routeId),
      });
      return;
    }

    final originalCoords = _originalRoutes[routeId];
    if (originalCoords == null || originalCoords.isEmpty) {
      _log(_LogLevel.debug, 'snapStartPosition: route coords not found in animator', {
        'routeId': routeId,
      });
      return;
    }

    // Cancel any running animation
    cancelAnimation(routeId);

    // Store the new start position
    _animatedStartPositions[routeId] = newStart;

    // Build new coordinates with snapped start + remaining original coords
    final remainingCoords = originalCoords.length > 1
        ? originalCoords.sublist(1)
        : <Coordinates>[];
    final newCoordinates = [newStart, ...remainingCoords];

    final options = _routeOptions[routeId];
    await controller.updateRouteLine(routeId, newCoordinates, options: options);

    _log(_LogLevel.debug, 'snapStartPosition: done', {
      'routeId': routeId,
      'pos': '(${newStart.lat.toStringAsFixed(6)}, ${newStart.lon.toStringAsFixed(6)})',
    });
  }

  /// Cancels any running animation for a route.
  void cancelAnimation(String routeId) {
    final timer = _animations.remove(routeId);
    final wasAnimating = timer != null;
    timer?.cancel();

    if (wasAnimating) {
      _log(_LogLevel.debug, 'cancelAnimation', {
        'routeId': routeId,
        'wasAnimating': true,
      });
    }
  }

  /// Cancels all running route animations.
  void cancelAllAnimations() {
    if (_animations.isEmpty) return;

    final count = _animations.length;
    for (final timer in _animations.values) {
      timer.cancel();
    }
    _animations.clear();

    _log(_LogLevel.debug, 'cancelAllAnimations', {'cancelled': count});
  }

  /// Clears stored data for a specific route.
  ///
  /// Call this when a route is removed from the map.
  void clearRoute(String routeId) {
    cancelAnimation(routeId);
    _originalRoutes.remove(routeId);
    _animatedStartPositions.remove(routeId);
    _routeOptions.remove(routeId);

    _log(_LogLevel.debug, 'clearRoute', {'routeId': routeId});
  }

  /// Clears all stored route data.
  void clearAllRoutes() {
    cancelAllAnimations();
    _originalRoutes.clear();
    _animatedStartPositions.clear();
    _routeOptions.clear();

    _log(_LogLevel.debug, 'clearAllRoutes');
  }

  /// Disposes all resources.
  ///
  /// Call this when the animator is no longer needed.
  void dispose() {
    cancelAllAnimations();
    _originalRoutes.clear();
    _animatedStartPositions.clear();
    _routeOptions.clear();

    _log(_LogLevel.info, 'dispose');
  }
}
