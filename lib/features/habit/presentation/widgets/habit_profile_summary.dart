import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final todayAsync = ref.watch(todayReadingProvider);

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading habit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const HabitStreakWidget(compact: true),
            const SizedBox(height: 12),
            todayAsync.when(
              data: (read) => Text(
                read ? 'You logged reading today. Nice work.' : 'Did you read today?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              loading: () => const SizedBox(
                height: 20,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Text('Today status: $e'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showHabitQuickAddBottomSheet(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Quick log'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HabitPage(),
                        ),
                      );
                    },
                    child: const Text('Details'),
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
