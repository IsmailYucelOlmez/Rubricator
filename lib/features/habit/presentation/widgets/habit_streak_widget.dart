import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 22),
              const SizedBox(width: 8),
              Text(
                '${s.currentStreak} day streak',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          );
        }
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current streak',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        '${s.currentStreak} days',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Longest: ${s.longestStreak} days',
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
      error: (e, _) => Text('Could not load streak: $e'),
    );
  }
}
