import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Headlines: Playfair Display (editorial, Efco Brookshire–style).
/// Body: Newsreader (readable serif; Donau is not bundled in `google_fonts`).
abstract final class AppTypography {
  static TextTheme textTheme() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true).textTheme;
    final bodyBase = GoogleFonts.newsreaderTextTheme(base);

    TextStyle playfair({
      double fontSize = 24,
      FontWeight fontWeight = FontWeight.w700,
      Color? color,
      double? height,
    }) {
      return GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        height: height,
      );
    }

    TextStyle news({
      double fontSize = 14,
      FontWeight fontWeight = FontWeight.w400,
      Color? color,
      double? height,
    }) {
      return GoogleFonts.newsreader(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        height: height,
      );
    }

    return bodyBase.copyWith(
      displayLarge: playfair(fontSize: 36, fontWeight: FontWeight.w700),
      displayMedium: playfair(fontSize: 32),
      displaySmall: playfair(fontSize: 28),
      headlineLarge: playfair(fontSize: 28),
      headlineMedium: playfair(fontSize: 24),
      headlineSmall: playfair(fontSize: 22, fontWeight: FontWeight.w600),
      titleLarge: news(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: news(fontSize: 18, fontWeight: FontWeight.w600),
      titleSmall: news(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: news(fontSize: 16),
      bodyMedium: news(fontSize: 14),
      bodySmall: news(fontSize: 12, color: AppColors.textSecondary),
      labelLarge: news(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: news(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: news(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        color: AppColors.textSecondary,
      ),
    );
  }
}
