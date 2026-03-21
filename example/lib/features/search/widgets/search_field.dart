import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

/// Modern search input field with glassmorphism-inspired design.
class SearchField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final Color iconColor;
  final ValueChanged<String> onChanged;
  final VoidCallback onMapSelect;
  final VoidCallback? onSubmitted;

  /// Whether the address is being resolved (shows shimmer animation).
  final bool isLoading;

  const SearchField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    required this.iconColor,
    required this.onChanged,
    required this.onMapSelect,
    this.onSubmitted,
    this.isLoading = false,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerPosition;
  late Animation<double> _pulseAnimation;

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerPosition = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 1),
    ]).animate(_shimmerController);

    if (widget.isLoading) {
      _shimmerController.repeat();
    }

    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    final focused = widget.focusNode.hasFocus;
    if (focused != _isFocused) {
      setState(() => _isFocused = focused);
      if (focused) {
        _animationController.forward();
        developer.log('[SearchField] Focus gained: ${widget.label}');
      } else {
        _animationController.reverse();
        developer.log('[SearchField] Focus lost: ${widget.label}');
      }
    }
  }

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
        _shimmerController.reset();
      }
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: _isFocused
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppColors.primaryContainer.withAlpha(51), // 20%
                      ],
                    )
                  : null,
              color: _isFocused ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primary.withAlpha(179) // 70%
                    : AppColors.outlineVariant,
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? AppColors.primary.withAlpha(
                          (38 * _glowAnimation.value).round())
                      : AppColors.shadowLight,
                  blurRadius: _isFocused ? 20 : 8,
                  spreadRadius: _isFocused ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
                if (_isFocused)
                  BoxShadow(
                    color: AppColors.primary.withAlpha(13), // 5%
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Row(
              children: [
                _buildIconContainer(),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField()),
                const SizedBox(width: 8),
                _MapSelectButton(
                  onTap: widget.onMapSelect,
                  isFocused: _isFocused,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconContainer() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.iconColor.withAlpha(_isFocused ? 38 : 26), // 15% : 10%
            widget.iconColor.withAlpha(_isFocused ? 26 : 13), // 10% : 5%
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: widget.iconColor.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        widget.prefixIcon,
        size: 18,
        color: widget.iconColor,
      ),
    );
  }

  Widget _buildTextField() {
    if (!widget.isLoading) {
      return TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textInputAction: TextInputAction.search,
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
          letterSpacing: 0.1,
        ),
        decoration: InputDecoration(
          hintText: widget.label,
          hintStyle: TextStyle(
            color: AppColors.onSurfaceVariant.withAlpha(179),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text with pulsing opacity
            Opacity(
              opacity: _pulseAnimation.value,
              child: Text(
                widget.controller.text.isNotEmpty
                    ? widget.controller.text
                    : widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Shimmer bar under text
            ClipRRect(
              borderRadius: BorderRadius.circular(1.5),
              child: SizedBox(
                height: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final barWidth = width * 0.4;
                    final pos = _shimmerPosition.value;
                    final left = (pos * width) - barWidth / 2;
                    return Stack(
                      children: [
                        // Track
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        // Moving indicator
                        Positioned(
                          left: left,
                          top: 0,
                          bottom: 0,
                          width: barWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1.5),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withAlpha(0),
                                  AppColors.primary.withAlpha(140),
                                  AppColors.primary.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapSelectButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isFocused;

  const _MapSelectButton({
    required this.onTap,
    required this.isFocused,
  });

  @override
  State<_MapSelectButton> createState() => _MapSelectButtonState();
}

class _MapSelectButtonState extends State<_MapSelectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        developer.log('[SearchField] Map select tapped');
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isPressed
                      ? [
                          AppColors.primary.withAlpha(26),
                          AppColors.secondary.withAlpha(26),
                        ]
                      : [
                          AppColors.surfaceTint,
                          AppColors.surfaceVariant,
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPressed
                      ? AppColors.primary.withAlpha(51)
                      : AppColors.outlineVariant,
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 16,
                    color: _isPressed
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).map,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isPressed
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
