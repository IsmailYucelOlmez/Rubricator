import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_stats_providers.dart';

class ReadingIdentitySection extends ConsumerWidget {
  const ReadingIdentitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genreStatsProvider);
    final authorsAsync = ref.watch(authorStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading identity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Genres and authors from completed books',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Top genres',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            genresAsync.when(
              data: (genres) {
                if (genres.isEmpty) {
                  return Text(
                    'No data yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                }
                final maxC = genres.map((g) => g.count).reduce((a, b) => a > b ? a : b);
                return Column(
                  children: genres.map((g) {
                    final t = maxC > 0 ? g.count / maxC : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g.genre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '${g.count}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: t,
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Could not load genres: $e'),
            ),
            const SizedBox(height: 20),
            Text(
              'Top authors',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            authorsAsync.when(
              data: (authors) {
                if (authors.isEmpty) {
                  return Text(
                    'No data yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                }
                return Column(
                  children: authors.map((a) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.author),
                      trailing: Text(
                        '${a.count}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Could not load authors: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
