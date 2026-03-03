import 'package:flutter/material.dart';
import '../navigation_options.dart';

/// Button to recenter the map on user location.
class RecenterButton extends StatelessWidget {
  final CameraTrackingMode currentMode;
  final VoidCallback onPressed;

  const RecenterButton({
    super.key,
    required this.currentMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if already tracking
    if (currentMode != CameraTrackingMode.free) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.my_location),
        color: Colors.blue,
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
