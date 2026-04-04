import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_log_entity.dart';
import '../../domain/services/reading_streak_calculator.dart';
import '../providers/habit_providers.dart';

class HabitLogsList extends ConsumerWidget {
  const HabitLogsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(readingLogsProvider);
    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No logs yet — tap Quick log to start.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final grouped = <DateTime, List<ReadingLogEntity>>{};
        for (final log in logs) {
          final k = ReadingStreakCalculator.dateOnly(log.date);
          grouped.putIfAbsent(k, () => []).add(log);
        }
        final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Recent logs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...keys.take(14).map((day) {
                  final items = grouped[day]!..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                        child: Text(
                          _formatDay(day),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      ...items.map(
                        (e) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.edit_note_outlined),
                          title: Text(
                            [
                              if (e.minutesRead > 0) '${e.minutesRead} min',
                              if (e.pagesRead > 0) '${e.pagesRead} pages',
                            ].join(' · '),
                          ),
                          subtitle: e.bookId != null && e.bookId!.isNotEmpty
                              ? Text('Book: ${e.bookId}')
                              : null,
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Logs error: $e'),
    );
  }

  static String _formatDay(DateTime d) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
