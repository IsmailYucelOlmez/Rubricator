import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Display (largest headings): Nouveau.
/// Headlines & titles: Sansita Swashed.
/// Body / labels: Sansita Swashed.
/// Sinistre: bottom nav labels (use [bottomNavLabel]).
abstract final class AppTypography {
  static const String _nouveau = 'Nouveau';
  static const String _sansitaSwashed = 'SansitaSwashed';
  static const String _sinistre = 'Sinistre';

  static TextStyle bottomNavLabel({required Color color}) {
    return TextStyle(
      fontFamily: _sinistre,
      fontSize: 11 * 1.20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: color,
    );
  }

  static TextTheme textTheme({
    Brightness brightness = Brightness.dark,
    double bodyFontSizeFactor = 1.0,
  }) {
    final base = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
    final onSurface = brightness == Brightness.dark ? AppColors.textPrimary : AppColors.lightOnSurface;
    final onSurfaceVariant =
        brightness == Brightness.dark ? AppColors.textSecondary : AppColors.lightOnSurfaceVariant;

    TextStyle nouveau({
      double fontSize = 24,
      FontWeight fontWeight = FontWeight.w700,
      Color? color,
      double? height,
    }) {
      return TextStyle(
        fontFamily: _nouveau,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? onSurface,
        height: height,
      );
    }

    TextStyle body({
      double fontSize = 14,
      FontWeight fontWeight = FontWeight.w400,
      Color? color,
      double? height,
    }) {
      return TextStyle(
        fontFamily: _sansitaSwashed,
        fontSize: fontSize * bodyFontSizeFactor,
        fontWeight: fontWeight,
        color: color ?? onSurface,
        height: height,
      );
    }

    TextStyle sansitaSwashed({
      double fontSize = 24,
      FontWeight fontWeight = FontWeight.w700,
      Color? color,
      double? height,
    }) {
      return TextStyle(
        fontFamily: _sansitaSwashed,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? onSurface,
        height: height,
      );
    }

    return base.copyWith(
      displayLarge: nouveau(fontSize: 36, fontWeight: FontWeight.w700),
      displayMedium: nouveau(fontSize: 32),
      displaySmall: nouveau(fontSize: 28),
      headlineLarge: sansitaSwashed(fontSize: 28),
      headlineMedium: sansitaSwashed(fontSize: 24),
      headlineSmall: sansitaSwashed(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: sansitaSwashed(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: sansitaSwashed(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: sansitaSwashed(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: body(fontSize: 16),
      bodyMedium: body(fontSize: 14),
      bodySmall: body(fontSize: 12, color: onSurfaceVariant),
      labelLarge: body(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: body(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: body(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        color: onSurfaceVariant,
      ),
    );
  }
}
