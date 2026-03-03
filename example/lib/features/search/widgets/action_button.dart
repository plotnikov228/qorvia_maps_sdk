import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';

/// Modern action button with gradient and scale animation.
class ActionButton extends StatefulWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;

  const ActionButton({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  bool get _isDisabled => widget.onTap == null || widget.isLoading;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (_isDisabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (_isDisabled) return;
    HapticFeedback.lightImpact();
    developer.log('[ActionButton] Tapped: ${widget.label}');
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: widget.isPrimary ? _buildGradient() : null,
                color: widget.isPrimary ? null : _buildSecondaryColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _buildBorderColor(),
                  width: 1.5,
                ),
                boxShadow: _buildShadows(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLeadingWidget(),
                  const SizedBox(width: 8),
                  _buildLabel(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient? _buildGradient() {
    if (_isDisabled) {
      return LinearGradient(
        colors: [
          AppColors.outline.withAlpha(51),
          AppColors.outline.withAlpha(38),
        ],
      );
    }
    if (_isPressed) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryDark,
          AppColors.primary,
        ],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.primaryGradient,
    );
  }

  Color _buildSecondaryColor() {
    if (_isDisabled) {
      return AppColors.surfaceTint.withAlpha(128);
    }
    if (_isPressed) {
      return AppColors.surfaceTint;
    }
    return AppColors.surface;
  }

  Color _buildBorderColor() {
    if (widget.isPrimary) {
      return _isPressed
          ? AppColors.primaryDark.withAlpha(128)
          : Colors.transparent;
    }
    if (_isPressed) {
      return AppColors.primary.withAlpha(51);
    }
    return AppColors.outlineVariant;
  }

  List<BoxShadow> _buildShadows() {
    if (_isDisabled) return [];

    if (widget.isPrimary) {
      return [
        BoxShadow(
          color: AppColors.primary.withAlpha(_isPressed ? 26 : 51),
          blurRadius: _isPressed ? 8 : 16,
          spreadRadius: 0,
          offset: Offset(0, _isPressed ? 2 : 6),
        ),
        if (!_isPressed)
          BoxShadow(
            color: AppColors.secondary.withAlpha(26),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
      ];
    }

    return [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: _isPressed ? 4 : 8,
        offset: Offset(0, _isPressed ? 1 : 3),
      ),
    ];
  }

  Widget _buildLeadingWidget() {
    if (widget.isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: widget.isPrimary ? Colors.white : AppColors.primary,
        ),
      );
    }

    if (widget.icon != null) {
      return Icon(
        widget.icon,
        size: 18,
        color: _buildIconColor(),
      );
    }

    return const SizedBox.shrink();
  }

  Color _buildIconColor() {
    if (_isDisabled) {
      return widget.isPrimary
          ? Colors.white.withAlpha(179)
          : AppColors.outline;
    }
    return widget.isPrimary ? Colors.white : AppColors.onSurfaceVariant;
  }

  Widget _buildLabel() {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _buildTextColor(),
        letterSpacing: 0.3,
      ),
      child: Text(widget.label),
    );
  }

  Color _buildTextColor() {
    if (_isDisabled) {
      return widget.isPrimary
          ? Colors.white.withAlpha(179)
          : AppColors.outline;
    }
    return widget.isPrimary ? Colors.white : AppColors.onSurfaceVariant;
  }
}
