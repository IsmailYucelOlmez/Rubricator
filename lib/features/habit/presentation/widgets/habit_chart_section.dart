import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_log_entity.dart';
import '../../domain/services/reading_streak_calculator.dart';
import '../providers/habit_providers.dart';

class HabitChartSection extends ConsumerWidget {
  const HabitChartSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(readingLogsProvider);
    return logsAsync.when(
      data: (logs) => _ChartCard(logs: logs),
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Chart error: $e'),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.logs});

  final List<ReadingLogEntity> logs;

  @override
  Widget build(BuildContext context) {
    final today = ReadingStreakCalculator.dateOnly(DateTime.now());
    final daily = <DateTime, int>{};
    for (var i = 0; i < 14; i++) {
      daily[today.subtract(Duration(days: i))] = 0;
    }
    for (final log in logs) {
      final d = ReadingStreakCalculator.dateOnly(log.date);
      if (daily.containsKey(d)) {
        daily[d] = (daily[d] ?? 0) + log.minutesRead;
      }
    }

    final ordered = daily.keys.toList()..sort();
    final maxM = ordered.map((k) => daily[k] ?? 0).fold<int>(0, (a, b) => a > b ? a : b);
    final denom = maxM > 0 ? maxM : 1;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily minutes (14 days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: ordered.map((day) {
                  final m = daily[day] ?? 0;
                  final h = 8.0 + (m / denom) * 100;
                  final isToday = day == today;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: '$m min',
                            child: Container(
                              height: h.clamp(4, 110),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Weekly minutes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _WeeklyBars(logs: logs, today: today),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.logs, required this.today});

  final List<ReadingLogEntity> logs;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final weekTotals = <int, int>{};
    for (var w = 0; w < 6; w++) {
      weekTotals[w] = 0;
    }
    for (final log in logs) {
      final d = ReadingStreakCalculator.dateOnly(log.date);
      final diff = today.difference(d).inDays;
      if (diff < 0 || diff >= 42) continue;
      final weekIndex = diff ~/ 7;
      if (weekIndex >= 6) continue;
      weekTotals[weekIndex] = (weekTotals[weekIndex] ?? 0) + log.minutesRead;
    }
    final maxW = weekTotals.values.fold<int>(0, (a, b) => a > b ? a : b);
    final denom = maxW > 0 ? maxW : 1;

    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(6, (i) {
          final m = weekTotals[i] ?? 0;
          final h = 10.0 + (m / denom) * 80;
          final label = i == 0 ? 'This wk' : '-${i}w';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: '$m min',
                    child: Container(
                      height: h.clamp(6, 92),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
