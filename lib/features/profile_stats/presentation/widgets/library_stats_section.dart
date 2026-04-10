import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
                      final cross = w > 520 ? 3 : 2;
                      return GridView.count(
                        crossAxisCount: cross,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
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
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text(
            AppLocalizations.of(context)!.couldNotLoadLibraryStats(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.gold),
            const Spacer(),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}


