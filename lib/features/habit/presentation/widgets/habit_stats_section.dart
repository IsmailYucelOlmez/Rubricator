import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';

import '../providers/habit_providers.dart';

class HabitStatsSection extends ConsumerWidget {
  const HabitStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(readingStatsProvider);
    return statsAsync.when(
      data: (s) {
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.totals, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.timer_outlined,
                        label: AppLocalizations.of(context)!.minutes,
                        value: '${s.totalMinutes}',
                      ),
                    ),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.auto_stories_outlined,
                        label: AppLocalizations.of(context)!.pages,
                        value: '${s.totalPages}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppLoadingIndicator(centered: false),
            ),
          ),
      error: (e, _) => Text(AppLocalizations.of(context)!.statsError(e.toString())),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 28, color: AppColors.gold),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ],
    );
  }
}
