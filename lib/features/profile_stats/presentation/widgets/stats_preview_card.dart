import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../pages/profile_stats_page.dart';
import '../providers/profile_stats_providers.dart';

/// Profile summary only — does not load full analytics (see [profileStatsSummaryProvider]).
class StatsPreviewCard extends ConsumerWidget {
  const StatsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(profileStatsSummaryProvider);

    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const ProfileStatsPage(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: async.when(
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.readingStats,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.booksCount(s.completedBooks),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.star_outline, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      s.averageRating > 0
                          ? l10n.averageShort(s.averageRating.toStringAsFixed(1))
                          : l10n.noRatingsYet,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.topGenre(s.topGenre),
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.viewAllStats,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
            loading: () => SizedBox(
              height: AppSpacing.lg * 5,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(l10n.loadStatsError(e.toString())),
            ),
          ),
        ),
      ),
    );
  }
}
