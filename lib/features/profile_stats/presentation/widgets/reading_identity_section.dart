import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../providers/profile_stats_providers.dart';

class ReadingIdentitySection extends ConsumerWidget {
  const ReadingIdentitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genreStatsProvider);
    final authorsAsync = ref.watch(authorStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.readingIdentity,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppLocalizations.of(context)!.genresAndAuthorsFromCompleted,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.topGenres,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            genresAsync.when(
              data: (genres) {
                if (genres.isEmpty) {
                  return Text(
                    AppLocalizations.of(context)!.noDataYet,
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
                          const SizedBox(height: AppSpacing.xs),
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
                child: Center(child: AppLoadingIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text(
                AppLocalizations.of(context)!.couldNotLoadGenres(e.toString()),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.topAuthors,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            authorsAsync.when(
              data: (authors) {
                if (authors.isEmpty) {
                  return Text(
                    AppLocalizations.of(context)!.noDataYet,
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
                child: Center(child: AppLoadingIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text(
                AppLocalizations.of(context)!.couldNotLoadAuthors(e.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

