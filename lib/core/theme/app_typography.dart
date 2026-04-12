import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Display (largest headings): EFCO Brookshire.
/// Headlines & titles: Have Heart One.
/// Body / labels: Handelson Three.
/// Donau Uppercase: only for all-caps UI (e.g. bottom nav — use [bottomNavLabel]).
abstract final class AppTypography {
  static const String _handelson = 'HandelsonThree';
  static const String _brookshire = 'EFCOBrookshire';
  static const String _haveHeartOne = 'HaveHeartOne';
  static const String _donauUpper = 'DonauNeueUppercase';

  /// Material [NavigationBar] labels; pair with `label: l10n.foo.toUpperCase()`.
  static TextStyle bottomNavLabel({required Color color}) {
    return TextStyle(
      fontFamily: _donauUpper,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: color,
    );
  }

  static TextTheme textTheme({Brightness brightness = Brightness.dark}) {
    final base = ThemeData(brightness: brightness, useMaterial3: true).textTheme;
    final onSurface = brightness == Brightness.dark ? AppColors.textPrimary : AppColors.lightOnSurface;
    final onSurfaceVariant =
        brightness == Brightness.dark ? AppColors.textSecondary : AppColors.lightOnSurfaceVariant;

    TextStyle brookshire({
      double fontSize = 24,
      FontWeight fontWeight = FontWeight.w700,
      Color? color,
      double? height,
    }) {
      return TextStyle(
        fontFamily: _brookshire,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? onSurface,
        height: height,
      );
    }

    TextStyle handelson({
      double fontSize = 14,
      FontWeight fontWeight = FontWeight.w400,
      Color? color,
      double? height,
    }) {
      return TextStyle(
        fontFamily: _handelson,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? onSurface,
        height: height,
      );
    }

    TextStyle haveHeartOne({
      double fontSize = 24,
      FontWeight fontWeight = FontWeight.w700,
      Color? color,
      double? height,
    }) {
      return TextStyle(
        fontFamily: _haveHeartOne,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? onSurface,
        height: height,
      );
    }

    return base.copyWith(
      displayLarge: brookshire(fontSize: 36, fontWeight: FontWeight.w700),
      displayMedium: brookshire(fontSize: 32),
      displaySmall: brookshire(fontSize: 28),
      headlineLarge: haveHeartOne(fontSize: 28),
      headlineMedium: haveHeartOne(fontSize: 24),
      headlineSmall: haveHeartOne(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: haveHeartOne(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: haveHeartOne(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: haveHeartOne(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: handelson(fontSize: 16),
      bodyMedium: handelson(fontSize: 14),
      bodySmall: handelson(fontSize: 12, color: onSurfaceVariant),
      labelLarge: handelson(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: handelson(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: handelson(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        color: onSurfaceVariant,
      ),
    );
  }
}
