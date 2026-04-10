import 'package:flutter/material.dart';

/// Rubricator palette — dark-first, minimal accents.
abstract final class AppColors {
  static const Color primary = Color(0xFF8B1E2D);

  static const Color background = Color(0xFF0F0F10);
  static const Color surface = Color(0xFF1A1A1C);
  static const Color card = Color(0xFF222225);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  static const Color gold = Color(0xFFC2A878);

  /// Light theme surfaces (warm paper-like, matches Rubricator maroon accent).
  static const Color lightBackground = Color(0xFFF7F4EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEDE8E1);
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  static const Color lightOnSurfaceVariant = Color(0xFF5C5E64);
}
