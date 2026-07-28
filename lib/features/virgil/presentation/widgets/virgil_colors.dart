import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Theme-aware Virgil palette — light keeps the editorial black/white look;
/// dark maps onto the app surface/text tokens.
@immutable
class VirgilColors {
  const VirgilColors({
    required this.paper,
    required this.ink,
    required this.muted,
    required this.coverBg,
    required this.track,
    required this.accent,
  });

  final Color paper;
  final Color ink;
  final Color muted;
  final Color coverBg;
  final Color track;

  /// Brand CTA / error red (same on light and dark).
  final Color accent;

  static const Color _accent = Color(0xFFEF233C);

  static VirgilColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return VirgilColors(
        paper: AppColors.background,
        ink: AppColors.textPrimary,
        muted: AppColors.textPrimary.withValues(alpha: 0.55),
        coverBg: const Color(0xFF2A2E32),
        track: AppColors.textPrimary.withValues(alpha: 0.18),
        accent: _accent,
      );
    }
    return const VirgilColors(
      paper: Color(0xFFFFFFFF),
      ink: Color(0xFF000000),
      muted: Color(0xFF9E9E9E),
      coverBg: Color(0xFFE8E8E8),
      track: Color(0xFFE5E5E5),
      accent: _accent,
    );
  }
}
