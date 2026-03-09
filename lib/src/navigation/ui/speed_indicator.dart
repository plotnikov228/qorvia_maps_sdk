import 'package:flutter/material.dart';

import '../navigation_logger.dart';

/// Default colors for speed indicator (Yandex Navigator style).
const Color kDefaultSpeedBackgroundColor = Colors.white;
const Color kDefaultSpeedTextColor = Color(0xFF333333);
const Color kDefaultSpeedLimitBorderColor = Color(0xFFE53935);
const Color kDefaultSpeedOverLimitColor = Color(0xFFE53935);

/// Indicator showing current speed and speed limit in Yandex Navigator style.
///
/// Layout: `[current_speed_box] [speed_limit_circle]`
/// - Current speed in a rounded rectangle
/// - Speed limit in a red-bordered circle (when available)
/// - Current speed turns red when exceeding limit
class SpeedIndicator extends StatelessWidget {
  /// Current speed in km/h.
  final double speedKmh;

  /// Speed limit on current road segment (km/h), if available.
  final double? speedLimit;

  /// Background color for the speed display.
  final Color backgroundColor;

  /// Text color for normal speed.
  final Color textColor;

  /// Text color when speed exceeds limit.
  final Color overLimitColor;

  /// Border color for speed limit circle.
  final Color limitBorderColor;

  const SpeedIndicator({
    super.key,
    required this.speedKmh,
    this.speedLimit,
    this.backgroundColor = kDefaultSpeedBackgroundColor,
    this.textColor = kDefaultSpeedTextColor,
    this.overLimitColor = kDefaultSpeedOverLimitColor,
    this.limitBorderColor = kDefaultSpeedLimitBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOverLimit = speedLimit != null && speedKmh > speedLimit!;

    NavigationLogger.debug('SpeedIndicator', 'Building', {
      'speedKmh': speedKmh.round(),
      'speedLimit': speedLimit?.round(),
      'isOverLimit': isOverLimit,
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current speed box
        _buildSpeedBox(isOverLimit),
        // Speed limit circle (if available)
        if (speedLimit != null) ...[
          const SizedBox(width: 8),
          _buildSpeedLimitCircle(),
        ],
      ],
    );
  }

  /// Builds the current speed display box.
  Widget _buildSpeedBox(bool isOverLimit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${speedKmh.round()}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isOverLimit ? overLimitColor : textColor,
              height: 1.1,
            ),
          ),

        ],
      ),
    );
  }

  /// Builds the speed limit circle indicator.
  Widget _buildSpeedLimitCircle() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: limitBorderColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${speedLimit!.round()}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

/// Compact version of SpeedIndicator for smaller displays.
///
/// Shows only current speed without the limit circle.
class CompactSpeedIndicator extends StatelessWidget {
  /// Current speed in km/h.
  final double speedKmh;

  /// Speed limit on current road segment (km/h), if available.
  final double? speedLimit;

  /// Background color for the speed display.
  final Color backgroundColor;

  /// Text color for normal speed.
  final Color textColor;

  /// Text color when speed exceeds limit.
  final Color overLimitColor;

  const CompactSpeedIndicator({
    super.key,
    required this.speedKmh,
    this.speedLimit,
    this.backgroundColor = kDefaultSpeedBackgroundColor,
    this.textColor = kDefaultSpeedTextColor,
    this.overLimitColor = kDefaultSpeedOverLimitColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOverLimit = speedLimit != null && speedKmh > speedLimit!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${speedKmh.round()}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isOverLimit ? overLimitColor : textColor,
        ),
      ),
    );
  }
}
