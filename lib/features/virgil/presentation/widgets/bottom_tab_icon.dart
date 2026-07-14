import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

/// SVG icon for the main bottom navigation bar.
class BottomTabIcon extends StatelessWidget {
  const BottomTabIcon({
    super.key,
    required this.assetPath,
    this.size = 36,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Center Virgil tab: large “V” rendered with Megrim (not an image asset).
class VirgilTabMark extends StatelessWidget {
  const VirgilTabMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return Text(
      'V',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Megrim',
        fontSize: size,
        height: 1,
        color: color,
      ),
    );
  }
}

/// Taller / narrower selection pill behind a selected bottom-tab icon.
///
/// Material’s built-in [NavigationIndicator] is fixed at 64×32; this replaces
/// that look (with [NavigationBarThemeData.indicatorColor] set transparent).
class BottomTabSelectionHalo extends StatelessWidget {
  const BottomTabSelectionHalo({super.key, required this.child});

  final Widget child;

  static const double width = 48;
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22);
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: child,
    );
  }
}
