import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/profile_stats_page.dart';
import '../providers/profile_stats_providers.dart';

/// Profile summary only — does not load full analytics (see [profileStatsSummaryProvider]).
class StatsPreviewCard extends ConsumerWidget {
  const StatsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileStatsSummaryProvider);

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const ProfileStatsPage(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: async.when(
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading stats',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '${s.completedBooks} books',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_outline, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      s.averageRating > 0
                          ? '${s.averageRating.toStringAsFixed(1)} avg'
                          : 'No ratings yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Top: ${s.topGenre}',
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View all stats',
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
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Could not load stats: $e'),
            ),
          ),
        ),
      ),
    );
  }
}
