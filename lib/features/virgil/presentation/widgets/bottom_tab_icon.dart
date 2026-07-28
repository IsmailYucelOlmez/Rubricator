import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/system_navigation_chrome.dart';

/// SVG icon for the main bottom navigation bar.
class BottomTabIcon extends StatelessWidget {
  const BottomTabIcon({
    super.key,
    required this.assetPath,
    this.size = 28,
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
  const VirgilTabMark({super.key, this.size = 28});

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

/// Selection pill behind a selected bottom-tab icon.
class BottomTabSelectionHalo extends StatelessWidget {
  const BottomTabSelectionHalo({super.key, required this.child});

  final Widget child;

  static const double width = 40;
  static const double height = 36;

  /// Shared layout box so every tab icon shares the same top/bottom edges.
  static const double iconSlot = 32;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// App bottom tabs with a fixed icon strip; system gesture/button inset is
/// painted with [SystemNavigationChrome] (device theme), not app theme.
class BottomTabNavBar extends StatelessWidget {
  const BottomTabNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.height = 64,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final double height;

  @override
  Widget build(BuildContext context) {
    final navigationBarTheme = Theme.of(context).navigationBarTheme;
    final backgroundColor = navigationBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainer;
    final iconTheme = navigationBarTheme.iconTheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final systemNavColor = SystemNavigationChrome.backgroundColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);

    // Exact total height — children cannot expand this.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemNavigationChrome.overlayStyle(context),
      child: SizedBox(
        height: height + bottomInset,
        width: double.infinity,
        child: Column(
          children: [
            ColoredBox(
              color: backgroundColor,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: topBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _BottomTabItem(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            iconTheme: iconTheme,
                            onTap: () => onDestinationSelected(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (bottomInset > 0)
              ColoredBox(
                color: systemNavColor,
                child: SizedBox(height: bottomInset, width: double.infinity),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.iconTheme,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final WidgetStateProperty<IconThemeData?>? iconTheme;

  @override
  Widget build(BuildContext context) {
    final states = <WidgetState>{
      if (selected) WidgetState.selected,
    };
    final resolved = iconTheme?.resolve(states) ??
        IconThemeData(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 28,
        );
    final icon = destination.icon;

    // Same slot for every tab → shared top/bottom bounds; icon size only
    // changes the glyph inside, not the alignment box.
    final slotted = SizedBox(
      width: BottomTabSelectionHalo.iconSlot,
      height: BottomTabSelectionHalo.iconSlot,
      child: Center(child: icon),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: IconTheme.merge(
          data: resolved,
          child: selected
              ? BottomTabSelectionHalo(child: slotted)
              : SizedBox(
                  width: BottomTabSelectionHalo.width,
                  height: BottomTabSelectionHalo.height,
                  child: Center(child: slotted),
                ),
        ),
      ),
    );
  }
}
