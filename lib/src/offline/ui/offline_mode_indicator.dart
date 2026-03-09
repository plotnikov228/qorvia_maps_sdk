import 'dart:async';

import 'package:flutter/material.dart';

import '../../sdk_initializer.dart';
import '../connectivity/connectivity_service.dart';
import '../connectivity/network_status.dart';

/// Extension method for easy integration with QorviaMapView.
extension OfflineModeIndicatorExtension on Widget {
  /// Wraps this widget (usually a QorviaMapView) with an offline mode indicator.
  ///
  /// Example:
  /// ```dart
  /// QorviaMapView(...).withOfflineIndicator()
  /// ```
  Widget withOfflineIndicator({
    Alignment position = Alignment.topCenter,
    EdgeInsets padding = const EdgeInsets.only(top: 50),
    OfflineModeIndicatorStyle style = const OfflineModeIndicatorStyle(),
  }) {
    return Stack(
      children: [
        this,
        OfflineModeIndicator(
          position: position,
          padding: padding,
          style: style,
        ),
      ],
    );
  }
}

/// A widget that displays an indicator when the app is using offline mode.
///
/// This widget automatically monitors the SDK's offline mode state and
/// connectivity changes to show/hide the indicator.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     QorviaMapView(...),
///     OfflineModeIndicator(
///       position: Alignment.topCenter,
///       style: OfflineModeIndicatorStyle(
///         backgroundColor: Colors.orange,
///         textColor: Colors.white,
///       ),
///     ),
///   ],
/// )
/// ```
class OfflineModeIndicator extends StatefulWidget {
  /// Position of the indicator on the screen.
  final Alignment position;

  /// Padding around the indicator.
  final EdgeInsets padding;

  /// Visual style for the indicator.
  final OfflineModeIndicatorStyle style;

  /// Whether to animate the indicator appearance.
  final bool animate;

  /// Duration of show/hide animation.
  final Duration animationDuration;

  /// Custom child widget to display instead of default indicator.
  final Widget? child;

  /// Whether to show the indicator only when using offline tiles.
  ///
  /// When true, shows indicator when SDK is using offline tile style.
  /// When false, shows indicator whenever device is offline.
  final bool showOnlyForOfflineTiles;

  const OfflineModeIndicator({
    super.key,
    this.position = Alignment.topCenter,
    this.padding = const EdgeInsets.only(top: 50),
    this.style = const OfflineModeIndicatorStyle(),
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.child,
    this.showOnlyForOfflineTiles = true,
  });

  @override
  State<OfflineModeIndicator> createState() => _OfflineModeIndicatorState();
}

class _OfflineModeIndicatorState extends State<OfflineModeIndicator> {
  StreamSubscription<NetworkStatus>? _subscription;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _updateVisibility();
    _setupListener();
  }

  void _setupListener() {
    if (!QorviaMapsSDK.isInitialized) return;

    _subscription = ConnectivityService.instance.statusStream.listen((_) {
      _updateVisibility();
    });
  }

  void _updateVisibility() {
    final newVisible = _shouldShow();
    if (newVisible != _isVisible) {
      setState(() {
        _isVisible = newVisible;
      });
    }
  }

  bool _shouldShow() {
    if (!QorviaMapsSDK.isInitialized) return false;

    if (widget.showOnlyForOfflineTiles) {
      return QorviaMapsSDK.isUsingOfflineMode;
    } else {
      return !QorviaMapsSDK.isOnline;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indicator = widget.child ?? _DefaultOfflineIndicator(style: widget.style);

    Widget content = Align(
      alignment: widget.position,
      child: Padding(
        padding: widget.padding,
        child: SafeArea(
          child: indicator,
        ),
      ),
    );

    if (widget.animate) {
      content = AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: widget.animationDuration,
        child: AnimatedSlide(
          offset: _isVisible ? Offset.zero : const Offset(0, -1),
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !_isVisible,
            child: content,
          ),
        ),
      );
    } else if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return content;
  }
}

/// Visual style configuration for [OfflineModeIndicator].
class OfflineModeIndicatorStyle {
  /// Background color of the indicator.
  final Color backgroundColor;

  /// Text color.
  final Color textColor;

  /// Icon to display.
  final IconData icon;

  /// Icon color.
  final Color? iconColor;

  /// Text to display.
  final String text;

  /// Border radius.
  final BorderRadius borderRadius;

  /// Padding inside the indicator.
  final EdgeInsets contentPadding;

  /// Text style.
  final TextStyle? textStyle;

  /// Box shadow.
  final List<BoxShadow>? boxShadow;

  const OfflineModeIndicatorStyle({
    this.backgroundColor = const Color(0xFF424242),
    this.textColor = Colors.white,
    this.icon = Icons.cloud_off_rounded,
    this.iconColor,
    this.text = 'Offline Mode',
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.textStyle,
    this.boxShadow,
  });

  OfflineModeIndicatorStyle copyWith({
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Color? iconColor,
    String? text,
    BorderRadius? borderRadius,
    EdgeInsets? contentPadding,
    TextStyle? textStyle,
    List<BoxShadow>? boxShadow,
  }) {
    return OfflineModeIndicatorStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      text: text ?? this.text,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      textStyle: textStyle ?? this.textStyle,
      boxShadow: boxShadow ?? this.boxShadow,
    );
  }
}

/// Default indicator widget with icon and text.
class _DefaultOfflineIndicator extends StatelessWidget {
  final OfflineModeIndicatorStyle style;

  const _DefaultOfflineIndicator({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: style.borderRadius,
        boxShadow: style.boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      padding: style.contentPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            style.icon,
            color: style.iconColor ?? style.textColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            style.text,
            style: style.textStyle ??
                TextStyle(
                  color: style.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
