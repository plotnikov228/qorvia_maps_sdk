import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../models/travel_mode.dart';

/// Modern travel mode selector with sliding pill animation.
class TravelModeSelector extends StatefulWidget {
  final TravelMode selectedMode;
  final ValueChanged<TravelMode> onModeChanged;

  const TravelModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  State<TravelModeSelector> createState() => _TravelModeSelectorState();
}

class _TravelModeSelectorState extends State<TravelModeSelector> {
  int get _selectedIndex => TravelMode.values.indexOf(widget.selectedMode);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withAlpha(128),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 8) / TravelMode.values.length;

          return Stack(
            children: [
              // Sliding pill indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: 4 + (_selectedIndex * itemWidth),
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: _buildPillIndicator(),
              ),

              // Mode options
              Row(
                children: TravelMode.values.asMap().entries.map((entry) {
                  return Expanded(
                    child: _ModeOption(
                      mode: entry.value,
                      isSelected: widget.selectedMode == entry.value,
                      onTap: () => _handleTap(entry.value),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPillIndicator() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(51), // 20%
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.secondary.withAlpha(26), // 10%
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  void _handleTap(TravelMode mode) {
    if (mode != widget.selectedMode) {
      HapticFeedback.selectionClick();
      developer.log('[TravelModeSelector] Mode changed: ${mode.name}');
      widget.onModeChanged(mode);
    }
  }
}

class _ModeOption extends StatefulWidget {
  final TravelMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModeOption> createState() => _ModeOptionState();
}

class _ModeOptionState extends State<_ModeOption>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 0, // Using Icon
                    ),
                    child: Icon(
                      widget.mode.icon,
                      size: 18,
                      color: widget.isSelected
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.isSelected
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                    child: Text(widget.mode.localizedName(context)),
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
