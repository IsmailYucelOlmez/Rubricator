import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_log_entity.dart';
import '../../domain/services/reading_streak_calculator.dart';
import '../providers/habit_providers.dart';

/// GitHub-style contribution grid: weeks as columns, weekdays as rows.
class HabitCalendarSection extends ConsumerWidget {
  const HabitCalendarSection({super.key, this.weeks = 26});

  final int weeks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(readingLogsProvider);
    return logsAsync.when(
      data: (logs) => _CalendarBody(logs: logs, weeks: weeks),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Calendar error: $e'),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({required this.logs, required this.weeks});

  final List<ReadingLogEntity> logs;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final today = ReadingStreakCalculator.dateOnly(DateTime.now());
    final startMonday = _mondayOf(today).subtract(Duration(days: 7 * (weeks - 1)));

    final byDay = <DateTime, int>{};
    for (final log in logs) {
      final d = ReadingStreakCalculator.dateOnly(log.date);
      byDay[d] = (byDay[d] ?? 0) + log.minutesRead + log.pagesRead * 2;
    }

    final maxVal = byDay.values.fold<int>(0, (a, b) => a > b ? a : b);
    int level(int v) {
      if (v <= 0) return 0;
      if (maxVal <= 0) return 1;
      final t = v / maxVal;
      if (t < 0.25) return 1;
      if (t < 0.5) return 2;
      if (t < 0.75) return 3;
      return 4;
    }

    Color colorFor(int lv) {
      final base = Theme.of(context).colorScheme.primary;
      if (lv == 0) {
        return Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        );
      }
      return base.withValues(alpha: (0.2 + lv * 0.18).clamp(0.0, 1.0));
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Last $weeks weeks (darker = more reading)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weeks, (w) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(7, (weekday) {
                        final day = startMonday.add(Duration(days: w * 7 + weekday));
                        if (day.isAfter(today)) {
                          return const SizedBox(width: 11, height: 11);
                        }
                        final v = byDay[ReadingStreakCalculator.dateOnly(day)] ?? 0;
                        final lv = level(v);
                        final isToday = ReadingStreakCalculator.dateOnly(day) == today;
                        return Container(
                          width: 11,
                          height: 11,
                          margin: const EdgeInsets.only(bottom: 3),
                          decoration: BoxDecoration(
                            color: colorFor(lv),
                            borderRadius: BorderRadius.circular(2),
                            border: isToday
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                    width: 1,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}
