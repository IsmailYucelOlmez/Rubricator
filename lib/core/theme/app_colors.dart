import 'package:flutter/material.dart';

/// Rubricator palette — dark-first, minimal accents.
abstract final class AppColors {
  /// Brand red.
  static const Color primary = Color(0xFFBA181B);

  /// Deep black used for dark theme surfaces and text on light theme.
  static const Color background = Color(0xFF161A1D);
  static const Color surface = Color(0xFF161A1D);
  static const Color card = Color(0xFF161A1D);

  /// Off-white used for light surfaces and text on dark theme.
  static const Color textPrimary = Color(0xFFF5F3F4);
  static const Color textSecondary = Color(0xFFF5F3F4);

  /// Neutral accent used where gold was previously used.
  static const Color gold = Color(0xFFF0EBD8);

  /// Light theme surfaces.
  static const Color lightBackground = Color(0xFFF5F3F4);
  static const Color lightSurface = Color(0xFFF5F3F4);
  static const Color lightSurfaceVariant = Color(0xFFF5F3F4);
  static const Color lightOnSurface = Color(0xFF161A1D);
  static const Color lightOnSurfaceVariant = Color(0xFF161A1D);
}
