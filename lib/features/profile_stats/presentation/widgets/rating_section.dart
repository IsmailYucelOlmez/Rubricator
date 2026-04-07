import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../providers/profile_stats_providers.dart';

class RatingSection extends ConsumerWidget {
  const RatingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ratingStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.starsGivenToBooks,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
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
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: List.generate(5, (i) {
                            final filled = i < r.averageRating.round().clamp(0, 5);
                            return Icon(
                              filled ? Icons.star : Icons.star_border,
                              size: 22,
                              color: Theme.of(context).colorScheme.primary,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
          loading: () => const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
      padding: const EdgeInsets.only(bottom: 8),
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
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: t,
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
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


