import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_error_view.dart';

import '../providers/habit_providers.dart';

class HabitStreakWidget extends ConsumerWidget {
  const HabitStreakWidget({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(readingStatsProvider);
    return statsAsync.when(
      data: (s) {
        if (compact) {
          return Row(
            children: [
              Icon(Icons.local_fire_department, color: AppColors.gold, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.dayStreak(s.currentStreak),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          );
        }
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: AppColors.gold, size: 36),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.currentStreak,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        AppLocalizations.of(context)!.daysCount(s.currentStreak),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppLocalizations.of(context)!.longestDays(s.longestStreak),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => AsyncErrorView(
            error: e,
            compact: true,
            onRetry: () => ref.invalidate(readingStatsProvider),
          ),
    );
  }
}
