import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';

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
                  AppLocalizations.of(context)!.noLogsYetTapQuickLog,
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
                    AppLocalizations.of(context)!.recentLogs,
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
                              if (e.minutesRead > 0) AppLocalizations.of(context)!.minutesShort(e.minutesRead),
                              if (e.pagesRead > 0) AppLocalizations.of(context)!.pagesShort(e.pagesRead),
                            ].join(' · '),
                          ),
                          subtitle: e.bookId != null && e.bookId!.isNotEmpty
                              ? Text(AppLocalizations.of(context)!.bookIdLabel(e.bookId!))
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
      loading: () => const AppLoadingIndicator(),
      error: (e, _) => AsyncErrorView(
            error: e,
            compact: true,
            onRetry: () => ref.invalidate(readingLogsProvider),
          ),
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
