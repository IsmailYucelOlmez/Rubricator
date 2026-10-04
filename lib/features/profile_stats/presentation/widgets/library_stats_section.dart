import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../providers/profile_stats_providers.dart';

class LibraryStatsSection extends ConsumerWidget {
  const LibraryStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(libraryStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: async.when(
          data: (lib) {
            final tiles = <({String label, int value, IconData icon})>[
              (label: AppLocalizations.of(context)!.toRead, value: lib.toRead, icon: Icons.bookmark_outline),
              (label: AppLocalizations.of(context)!.reading, value: lib.reading, icon: Icons.auto_stories_outlined),
              (label: AppLocalizations.of(context)!.completed, value: lib.completed, icon: Icons.check_circle_outline),
              (label: AppLocalizations.of(context)!.dropped, value: lib.dropped, icon: Icons.remove_circle_outline),
              (label: AppLocalizations.of(context)!.favorites, value: lib.favorites, icon: Icons.favorite_outline),
            ];
            final hasData = tiles.any((t) => t.value > 0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.library,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppLocalizations.of(context)!.countsFromShelves,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!hasData)
                  Text(
                    AppLocalizations.of(context)!.noDataYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      const spacing = 10.0;
                      final minTileWidth = _StatTile.minWidthFor(context, tiles);
                      var cross = w > 520 ? 3 : 2;
                      // Drop a column when tiles would be too narrow to keep
                      // the longest label (e.g. "Tamamlandı") on one line.
                      while (cross > 1 &&
                          (w - spacing * (cross - 1)) / cross < minTileWidth) {
                        cross--;
                      }
                      final tileHeight =
                          (w - spacing * (cross > 1 ? cross - 1 : 1)) /
                              (cross > 1 ? cross : 2) /
                              2.8;
                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          mainAxisExtent: tileHeight,
                        ),
                        children: tiles
                            .map(
                              (t) => _StatTile(
                                label: t.label,
                                value: t.value,
                                icon: t.icon,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: AppLoadingIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => AsyncErrorView(
            error: e,
            compact: true,
            onRetry: () => ref.invalidate(libraryStatsProvider),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  static const double _horizontalPadding = AppSpacing.sm;
  static const double _iconSize = 20;
  static const double _iconGap = AppSpacing.xs + 2;
  static const double _valueGap = AppSpacing.xs;

  static TextStyle? _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium;

  static TextStyle? _valueStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          );

  /// Narrowest tile width that fits every label on a single line.
  static double minWidthFor(
    BuildContext context,
    List<({String label, int value, IconData icon})> tiles,
  ) {
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    var widest = 0.0;
    for (final t in tiles) {
      final needed = measure(t.label, _labelStyle(context)) +
          measure('${t.value}', _valueStyle(context));
      if (needed > widest) widest = needed;
    }
    return widest +
        _horizontalPadding * 2 +
        _iconSize +
        _iconGap +
        _valueGap +
        1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = AppColors.accent(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalPadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: _iconSize, color: iconColor),
            const SizedBox(width: _iconGap),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle(context)?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(width: _valueGap),
            Text(
              '$value',
              style: _valueStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}


