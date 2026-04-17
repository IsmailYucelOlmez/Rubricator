import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../pages/habit_page.dart';
import '../providers/habit_providers.dart';
import 'habit_quick_add_sheet.dart';
import 'habit_streak_widget.dart';

/// Profile strip: streak, today prompt, quick log + link to full habit page.
class HabitProfileSummary extends ConsumerWidget {
  const HabitProfileSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final todayAsync = ref.watch(todayReadingProvider);

    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.readingHabit,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            const HabitStreakWidget(compact: true),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            todayAsync.when(
              data: (read) => Text(
                read ? l10n.readingLoggedToday : l10n.didYouReadToday,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              loading: () => const SizedBox(
                height: 20,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppLoadingIndicator(size: 20, strokeWidth: 2, centered: false),
                ),
              ),
              error: (e, _) => Text(l10n.todayStatusError(e.toString())),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showHabitQuickAddBottomSheet(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(l10n.quickLog),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HabitPage(),
                        ),
                      );
                    },
                    child: Text(l10n.details),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
