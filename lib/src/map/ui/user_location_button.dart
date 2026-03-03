import 'package:flutter/material.dart';

import '../../navigation/navigation_logger.dart';

/// Default user location button widget.
///
/// Displays a button to toggle user location tracking.
/// Shows different states for tracking on/off.
///
/// Example:
/// ```dart
/// UserLocationButton(
///   isTracking: true,
///   onToggle: () => toggleTracking(),
/// )
/// ```
class UserLocationButton extends StatelessWidget {
  /// Whether location tracking is currently active.
  final bool isTracking;

  /// Called when the button is pressed to toggle tracking.
  final VoidCallback onToggle;

  /// Widget size in pixels.
  final double size;

  /// Background color when not tracking.
  final Color inactiveBackgroundColor;

  /// Background color when tracking.
  final Color activeBackgroundColor;

  /// Icon color when not tracking.
  final Color inactiveIconColor;

  /// Icon color when tracking.
  final Color activeIconColor;

  const UserLocationButton({
    super.key,
    required this.isTracking,
    required this.onToggle,
    this.size = 44,
    this.inactiveBackgroundColor = Colors.white,
    this.activeBackgroundColor = const Color(0xFF6366F1), // Indigo 500
    this.inactiveIconColor = Colors.grey,
    this.activeIconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        NavigationLogger.debug('UserLocationButton', 'Toggle pressed', {
          'wasTracking': isTracking,
          'willTrack': !isTracking,
        });
        onToggle();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isTracking ? activeBackgroundColor : inactiveBackgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isTracking ? Icons.my_location : Icons.location_searching,
            size: size * 0.5,
            color: isTracking ? activeIconColor : inactiveIconColor,
          ),
        ),
      ),
    );
  }
}
