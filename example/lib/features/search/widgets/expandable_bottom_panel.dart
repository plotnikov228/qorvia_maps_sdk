import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Snap point configuration for the panel.
class PanelSnapPoint {
  final String name;
  final double height;

  const PanelSnapPoint({required this.name, required this.height});

  @override
  String toString() => 'PanelSnapPoint($name: $height)';
}

/// Expandable bottom panel with scroll-to-expand behavior.
///
/// When dragging:
/// - If panel is not at max and dragging up → expand panel
/// - If panel is at max and dragging up → scroll content
/// - If panel is not at min and scroll is at top and dragging down → shrink panel
/// - If scroll is not at top and dragging down → scroll content
class ExpandableBottomPanel extends StatefulWidget {
  /// Child widget builder that receives isCollapsed state.
  final Widget Function(bool isCollapsed, VoidCallback expandPanel)? childBuilder;

  /// Static child widget (used if childBuilder is null).
  final Widget? child;

  final double minHeight;
  final double initialHeight;
  final double maxHeight;
  final ValueChanged<double>? onHeightChanged;
  final ValueChanged<PanelSnapPoint>? onSnapChanged;

  /// Callback when collapsed state changes.
  final ValueChanged<bool>? onCollapsedChanged;

  final List<double>? snapPoints;
  final Duration snapAnimationDuration;
  final bool enableGlassmorphism;
  final double borderRadius;

  /// Height threshold to consider panel as collapsed.
  /// Defaults to minHeight + 50 pixels.
  final double? collapsedThreshold;

  const ExpandableBottomPanel({
    super.key,
    this.child,
    this.childBuilder,
    required this.minHeight,
    required this.initialHeight,
    required this.maxHeight,
    this.onHeightChanged,
    this.onSnapChanged,
    this.onCollapsedChanged,
    this.snapPoints,
    this.snapAnimationDuration = const Duration(milliseconds: 300),
    this.enableGlassmorphism = true,
    this.borderRadius = 32.0,
    this.collapsedThreshold,
  }) : assert(minHeight <= initialHeight && initialHeight <= maxHeight),
       assert(child != null || childBuilder != null, 'Either child or childBuilder must be provided');

  @override
  State<ExpandableBottomPanel> createState() => _ExpandableBottomPanelState();
}

class _ExpandableBottomPanelState extends State<ExpandableBottomPanel>
    with SingleTickerProviderStateMixin {
  late double _currentHeight;
  late AnimationController _animationController;
  Animation<double>? _heightAnimation;
  bool _isCollapsed = true;

  final ScrollController _scrollController = ScrollController();
  bool _isDragging = false;
  double _dragStartY = 0;
  double _dragStartHeight = 0;

  bool get _isAtMaxHeight => (_currentHeight - widget.maxHeight).abs() < 1.0;
  bool get _isAtMinHeight => (_currentHeight - widget.minHeight).abs() < 1.0;
  bool get _isScrollAtTop => _scrollController.offset <= 0;

  /// Threshold below which the panel is considered collapsed.
  double get _collapsedThreshold =>
      widget.collapsedThreshold ?? (widget.minHeight + 50);

  List<PanelSnapPoint> get _allSnapPoints {
    final points = <PanelSnapPoint>[
      PanelSnapPoint(name: 'min', height: widget.minHeight),
      PanelSnapPoint(name: 'initial', height: widget.initialHeight),
      PanelSnapPoint(name: 'max', height: widget.maxHeight),
    ];

    if (widget.snapPoints != null) {
      for (int i = 0; i < widget.snapPoints!.length; i++) {
        final height = widget.snapPoints![i];
        if (height > widget.minHeight && height < widget.maxHeight) {
          points.add(PanelSnapPoint(name: 'custom_$i', height: height));
        }
      }
    }

    points.sort((a, b) => a.height.compareTo(b.height));

    final unique = <PanelSnapPoint>[];
    for (final point in points) {
      if (unique.isEmpty || (unique.last.height - point.height).abs() > 1.0) {
        unique.add(point);
      }
    }

    return unique;
  }

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
    _isCollapsed = _currentHeight <= _collapsedThreshold;

    _animationController = AnimationController(
      vsync: this,
      duration: widget.snapAnimationDuration,
    );

    _animationController.addListener(_onAnimationTick);

    // Notify initial height and collapsed state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHeightChanged?.call(_currentHeight);
      widget.onCollapsedChanged?.call(_isCollapsed);
    });

    _log('Initialized', {
      'minHeight': widget.minHeight,
      'initialHeight': widget.initialHeight,
      'maxHeight': widget.maxHeight,
      'isCollapsed': _isCollapsed,
      'collapsedThreshold': _collapsedThreshold,
    });
  }

  @override
  void dispose() {
    _animationController.removeListener(_onAnimationTick);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (_heightAnimation != null) {
      setState(() {
        _currentHeight = _heightAnimation!.value;
      });
      widget.onHeightChanged?.call(_currentHeight);
      _updateCollapsedState();
    }
  }

  /// Updates the collapsed state based on current height.
  void _updateCollapsedState() {
    final newCollapsed = _currentHeight <= _collapsedThreshold;
    if (newCollapsed != _isCollapsed) {
      _log('Collapsed state changed', {
        'wasCollapsed': _isCollapsed,
        'isCollapsed': newCollapsed,
        'currentHeight': _currentHeight,
        'threshold': _collapsedThreshold,
      });
      setState(() {
        _isCollapsed = newCollapsed;
      });
      widget.onCollapsedChanged?.call(newCollapsed);
    }
  }

  /// Expands the panel to initial height.
  void _expandPanel() {
    _log('Expand panel requested');
    final targetPoint = _allSnapPoints.firstWhere(
      (p) => p.name == 'initial',
      orElse: () => _allSnapPoints.last,
    );
    _animateToHeight(targetPoint);
  }

  void _onPointerDown(PointerDownEvent event) {
    _isDragging = true;
    _dragStartY = event.position.dy;
    _dragStartHeight = _currentHeight;
    _animationController.stop();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging) return;

    final deltaY = event.position.dy - _dragStartY;
    // Negative deltaY = finger moving up = want to expand or scroll up
    // Positive deltaY = finger moving down = want to shrink or scroll down

    if (deltaY < 0) {
      // Dragging up
      if (!_isAtMaxHeight) {
        // Expand panel
        final newHeight = (_dragStartHeight - deltaY).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
        if (newHeight != _currentHeight) {
          setState(() => _currentHeight = newHeight);
          widget.onHeightChanged?.call(_currentHeight);
          _updateCollapsedState();
        }
      }
      // If at max, let scroll handle it naturally
    } else {
      // Dragging down
      if (_isScrollAtTop && !_isAtMinHeight) {
        // Shrink panel
        final newHeight = (_dragStartHeight - deltaY).clamp(
          widget.minHeight,
          widget.maxHeight,
        );
        if (newHeight != _currentHeight) {
          setState(() => _currentHeight = newHeight);
          widget.onHeightChanged?.call(_currentHeight);
          _updateCollapsedState();
        }
      }
      // If not at scroll top, let scroll handle it naturally
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isDragging) return;
    _isDragging = false;
    _snapToNearestPoint(0);
  }

  void _snapToNearestPoint(double velocity) {
    final snapPoints = _allSnapPoints;
    if (snapPoints.isEmpty) return;

    PanelSnapPoint targetPoint;

    if (velocity.abs() > 500) {
      if (velocity < 0) {
        targetPoint = snapPoints.lastWhere(
          (p) => p.height > _currentHeight,
          orElse: () => snapPoints.last,
        );
      } else {
        targetPoint = snapPoints.firstWhere(
          (p) => p.height < _currentHeight,
          orElse: () => snapPoints.first,
        );
      }
    } else {
      double minDistance = double.infinity;
      targetPoint = snapPoints.first;

      for (final point in snapPoints) {
        final distance = (point.height - _currentHeight).abs();
        if (distance < minDistance) {
          minDistance = distance;
          targetPoint = point;
        }
      }
    }

    _animateToHeight(targetPoint);
  }

  void _animateToHeight(PanelSnapPoint target) {
    if ((target.height - _currentHeight).abs() < 1.0) {
      widget.onSnapChanged?.call(target);
      return;
    }

    _heightAnimation = Tween<double>(
      begin: _currentHeight,
      end: target.height,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0).then((_) {
      widget.onSnapChanged?.call(target);
    });
  }

  void _log(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' $data' : '';
    developer.log('[ExpandableBottomPanel] $message$dataStr');
  }

  @override
  Widget build(BuildContext context) {
    // Build child using builder or static child
    final childWidget = widget.childBuilder != null
        ? widget.childBuilder!(_isCollapsed, _expandPanel)
        : widget.child!;

    final content = Column(
      children: [
        // Drag handle
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: _isAtMaxHeight
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: childWidget,
          ),
        ),
      ],
    );

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: SizedBox(
        height: _currentHeight,
        child: widget.enableGlassmorphism
            ? _buildGlassmorphismContainer(content)
            : _buildSimpleContainer(content),
      ),
    );
  }

  Widget _buildGlassmorphismContainer(Widget content) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(widget.borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withAlpha(242),
                Colors.white.withAlpha(230),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(widget.borderRadius)),
            border: Border.all(
              color: Colors.white.withAlpha(128),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPrimary,
                blurRadius: 32,
                spreadRadius: 0,
                offset: const Offset(0, -12),
              ),
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildSimpleContainer(Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(widget.borderRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: content,
    );
  }
}
