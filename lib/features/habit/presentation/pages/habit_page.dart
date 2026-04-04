import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reading habit')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sign in to log reading, see streaks, and view your activity calendar.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading habit'),
        actions: [
          IconButton(
            tooltip: 'Quick log',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => showHabitQuickAddBottomSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHabitQuickAddBottomSheet(context),
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Log'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HabitStreakWidget(),
          SizedBox(height: 16),
          HabitStatsSection(),
          SizedBox(height: 16),
          HabitCalendarSection(),
          SizedBox(height: 16),
          HabitChartSection(),
          SizedBox(height: 16),
          HabitLogsList(),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}
