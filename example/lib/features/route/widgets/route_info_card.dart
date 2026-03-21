import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:qorvia_maps_sdk/qorvia_maps_sdk.dart';

import '../../../app/theme/app_colors.dart';
import '../../search/models/travel_mode.dart';

/// Modern card displaying route information with fade-in animation.
class RouteInfoCard extends StatefulWidget {
  final RouteResponse route;
  final TravelMode travelMode;
  final bool isLoading;

  const RouteInfoCard({
    super.key,
    required this.route,
    required this.travelMode,
    this.isLoading = false,
  });

  @override
  State<RouteInfoCard> createState() => _RouteInfoCardState();
}

class _RouteInfoCardState extends State<RouteInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
    developer.log('[RouteInfoCard] Displayed route: '
        '${widget.route.formattedDistance}, ${widget.route.formattedDuration}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1), // Indigo
                Color(0xFF8B5CF6), // Violet
                Color(0xFF06B6D4), // Cyan accent
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(64), // 25%
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.secondary.withAlpha(38), // 15%
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decorative gradient overlay
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withAlpha(26),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      _RouteIcon(),
                      const SizedBox(width: 16),
                      Expanded(child: _RouteDetails(route: widget.route)),
                      _TravelModeChip(
                        travelMode: widget.travelMode,
                        isLoading: widget.isLoading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(38), // 15%
            Colors.white.withAlpha(13), // 5%
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withAlpha(26),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.route_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _RouteDetails extends StatelessWidget {
  final RouteResponse route;

  const _RouteDetails({required this.route});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: Colors.white.withAlpha(179),
            ),
            const SizedBox(width: 6),
            Text(
              route.formattedDuration,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.straighten_rounded,
              size: 14,
              color: Colors.white.withAlpha(153),
            ),
            const SizedBox(width: 6),
            Text(
              route.formattedDistance,
              style: TextStyle(
                color: Colors.white.withAlpha(217), // 85%
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TravelModeChip extends StatelessWidget {
  final TravelMode travelMode;
  final bool isLoading;

  const _TravelModeChip({
    required this.travelMode,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            travelMode.icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            travelMode.localizedName(context),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
