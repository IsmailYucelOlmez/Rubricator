import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../providers/profile_stats_providers.dart';

Color _ratingBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? AppColors.lightOnSurface
      : AppColors.textPrimary.withValues(alpha: 0.4);
}

Widget _borderedProgressBar(
  BuildContext context, {
  required double value,
  double minHeight = 8,
}) {
  final scheme = Theme.of(context).colorScheme;
  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: _ratingBorderColor(context), width: 0.5),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: minHeight,
        backgroundColor: scheme.outline.withValues(alpha: 0.18),
        color: AppColors.primary,
      ),
    ),
  );
}

class RatingSection extends ConsumerWidget {
  const RatingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ratingStatsProvider);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: _ratingBorderColor(context), width: 0.5),
      ),
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
                const SizedBox(height: AppSpacing.sm),
                if (!hasData)
                  Text(
                    AppLocalizations.of(context)!.noDataYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        r.averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '0',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          height: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _borderedProgressBar(
                          context,
                          value: r.averageRating / 10,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '10',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          height: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var stars = 10; stars >= 1; stars--)
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
            child: const Center(child: AppLoadingIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => AsyncErrorView(
            error: e,
            compact: true,
            onRetry: () => ref.invalidate(ratingStatsProvider),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars, required this.count, required this.max});

  final int stars;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final t = max > 0 ? count / max : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '$stars ★',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: _borderedProgressBar(context, value: t)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
