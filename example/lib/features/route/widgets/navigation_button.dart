import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';

/// Modern navigation button with pulse animation and gradient.
class NavigationButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const NavigationButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<NavigationButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for attracting attention
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat();

    // Scale animation for tap feedback
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (widget.isLoading) return;
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap() {
    if (widget.isLoading || widget.onTap == null) return;
    HapticFeedback.mediumImpact();
    developer.log('[NavigationButton] Tapped');
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
        animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Pulse ring (only when not loading)
                if (!widget.isLoading)
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isPressed ? 0.0 : 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(
                              (102 * (1 - _pulseAnimation.value)).round(),
                            ),
                            width: 2 + (_pulseAnimation.value * 4),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Main button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isLoading
                          ? [
                              AppColors.outline.withAlpha(128),
                              AppColors.outline.withAlpha(102),
                            ]
                          : _isPressed
                              ? [
                                  AppColors.primaryDark,
                                  AppColors.primary,
                                ]
                              : AppColors.navigationGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isLoading
                            ? Colors.transparent
                            : AppColors.primary.withAlpha(
                                _isPressed ? 38 : 77,
                              ),
                        blurRadius: _isPressed ? 12 : 20,
                        spreadRadius: 0,
                        offset: Offset(0, _isPressed ? 4 : 8),
                      ),
                      if (!widget.isLoading && !_isPressed)
                        BoxShadow(
                          color: AppColors.secondary.withAlpha(38),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 12),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLeadingWidget(),
                      const SizedBox(width: 10),
                      Text(
                        widget.isLoading ? 'Загрузка...' : 'Поехали',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeadingWidget() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.navigation_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
