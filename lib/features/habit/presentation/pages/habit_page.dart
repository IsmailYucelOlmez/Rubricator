import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../widgets/habit_calendar_section.dart';
import '../widgets/habit_chart_section.dart';
import '../widgets/habit_logs_list.dart';
import '../widgets/habit_quick_add_sheet.dart';
import '../widgets/habit_stats_section.dart';
import '../widgets/habit_streak_widget.dart';

class HabitPage extends ConsumerWidget {
  const HabitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.readingHabit)),
        body: Center(
          child: ResponsiveScaffoldBody(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.signInForHabit,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.readingHabit),
        actions: [
          IconButton(
            tooltip: l10n.quickLog,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => showHabitQuickAddBottomSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHabitQuickAddBottomSheet(context),
        icon: const Icon(Icons.timer_outlined),
        label: Text(l10n.log),
      ),
      body: ResponsiveScaffoldBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
          HabitStreakWidget(),
          SizedBox(height: AppSpacing.md),
          HabitStatsSection(),
          SizedBox(height: AppSpacing.md),
          HabitCalendarSection(),
          SizedBox(height: AppSpacing.md),
          HabitChartSection(),
          SizedBox(height: AppSpacing.md),
          HabitLogsList(),
          SizedBox(height: AppSpacing.xl * 2 + AppSpacing.md),
        ],
        ),
      ),
    );
  }
}
