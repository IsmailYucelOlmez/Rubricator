import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/profile_stats_providers.dart';

class RatingSection extends ConsumerWidget {
  const RatingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ratingStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: async.when(
          data: (r) {
            final total = r.distribution.values.fold<int>(0, (a, b) => a + b);
            final hasData = total > 0 && r.averageRating > 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.yourRatings,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppLocalizations.of(context)!.starsGivenToBooks,
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
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        r.averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: List.generate(5, (i) {
                            final filled = i < r.averageRating.round().clamp(0, 5);
                            return Icon(
                              filled ? Icons.star : Icons.star_border,
                              size: 22,
                              color: AppColors.gold,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (var stars = 5; stars >= 1; stars--)
                    _StarRow(
                      stars: stars,
                      count: r.distribution[stars] ?? 0,
                      max: total,
                    ),
                ],
              ],
            );
          },
          loading: () => SizedBox(
            height: AppSpacing.xl * 3 + AppSpacing.sm,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text(
            AppLocalizations.of(context)!.couldNotLoadRatings(e.toString()),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.stars,
    required this.count,
    required this.max,
  });

  final int stars;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final t = max > 0 ? count / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$stars ★',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: t,
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}


