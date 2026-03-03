import 'package:flutter/material.dart';

/// Modern Material 3 color palette with Indigo/Violet gradients.
abstract final class AppColors {
  // Primary colors (Indigo 500)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryContainer = Color(0xFFE0E7FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1E1B4B);

  // Secondary colors (Violet 500)
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryContainer = Color(0xFFEDE9FE);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF2E1065);

  // Tertiary accent (Cyan)
  static const Color tertiary = Color(0xFF06B6D4);
  static const Color tertiaryContainer = Color(0xFFCFFAFE);

  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color surfaceTint = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF475569);

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFF0F172A);

  // Error colors
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  // Outline
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  // Additional semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);

  // Primary gradient (Indigo to Violet)
  static const List<Color> primaryGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  // Navigation gradient (deeper, more saturated)
  static const List<Color> navigationGradient = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
  ];

  // Route info gradient (modern cyan-blue)
  static const List<Color> routeInfoGradient = [
    Color(0xFF6366F1),
    Color(0xFF06B6D4),
  ];

  // Surface gradient (subtle)
  static const List<Color> surfaceGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
  ];

  // Glass effect colors
  static const Color glassBackground = Color(0xE6FFFFFF); // 90% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  // Marker colors
  static const Color markerStart = Color(0xFF22C55E);
  static const Color markerEnd = Color(0xFFEF4444);

  // Shadows
  static Color shadowPrimary = const Color(0xFF6366F1).withAlpha(38); // 15%
  static Color shadowLight = const Color(0xFF0F172A).withAlpha(13); // 5%
  static Color shadowMedium = const Color(0xFF0F172A).withAlpha(26); // 10%
}
