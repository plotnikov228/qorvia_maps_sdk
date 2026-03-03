import 'package:flutter/material.dart';

import '../../navigation/navigation_logger.dart';

/// Default zoom controls widget with +/- buttons.
///
/// Displays a vertical column with zoom in and zoom out buttons.
/// Can be replaced with a custom implementation using [ZoomControlsBuilder].
///
/// Example:
/// ```dart
/// ZoomControls(
///   currentZoom: 15.0,
///   minZoom: 2,
///   maxZoom: 20,
///   onZoomIn: () => controller.zoomIn(),
///   onZoomOut: () => controller.zoomOut(),
/// )
/// ```
class ZoomControls extends StatelessWidget {
  /// Current zoom level.
  final double currentZoom;

  /// Minimum allowed zoom level.
  final double minZoom;

  /// Maximum allowed zoom level.
  final double maxZoom;

  /// Called when zoom in button is pressed.
  final VoidCallback onZoomIn;

  /// Called when zoom out button is pressed.
  final VoidCallback onZoomOut;

  /// Button size in pixels.
  final double buttonSize;

  /// Icon size in pixels.
  final double iconSize;

  /// Background color for buttons.
  final Color backgroundColor;

  /// Icon color for buttons.
  final Color iconColor;

  /// Icon color when disabled.
  final Color disabledIconColor;

  const ZoomControls({
    super.key,
    required this.currentZoom,
    required this.onZoomIn,
    required this.onZoomOut,
    this.minZoom = 0,
    this.maxZoom = 22,
    this.buttonSize = 44,
    this.iconSize = 24,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black87,
    this.disabledIconColor = Colors.grey,
  });

  bool get _canZoomIn => currentZoom < maxZoom;
  bool get _canZoomOut => currentZoom > minZoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in button
          _ZoomButton(
            icon: Icons.add,
            enabled: _canZoomIn,
            onPressed: () {
              NavigationLogger.debug('ZoomControls', 'Zoom in pressed', {
                'currentZoom': currentZoom,
                'canZoomIn': _canZoomIn,
              });
              onZoomIn();
            },
            size: buttonSize,
            iconSize: iconSize,
            iconColor: _canZoomIn ? iconColor : disabledIconColor,
          ),
          // Divider
          Container(
            width: buttonSize * 0.7,
            height: 1,
            color: Colors.grey.shade300,
          ),
          // Zoom out button
          _ZoomButton(
            icon: Icons.remove,
            enabled: _canZoomOut,
            onPressed: () {
              NavigationLogger.debug('ZoomControls', 'Zoom out pressed', {
                'currentZoom': currentZoom,
                'canZoomOut': _canZoomOut,
              });
              onZoomOut();
            },
            size: buttonSize,
            iconSize: iconSize,
            iconColor: _canZoomOut ? iconColor : disabledIconColor,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color iconColor;

  const _ZoomButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.size,
    required this.iconSize,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
