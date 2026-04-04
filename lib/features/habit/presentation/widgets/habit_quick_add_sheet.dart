import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/habit_usecases.dart';
import '../providers/habit_providers.dart';

Future<void> showHabitQuickAddBottomSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const _HabitQuickAddBody(),
      );
    },
  );
}

class _HabitQuickAddBody extends ConsumerStatefulWidget {
  const _HabitQuickAddBody();

  @override
  ConsumerState<_HabitQuickAddBody> createState() => _HabitQuickAddBodyState();
}

class _HabitQuickAddBodyState extends ConsumerState<_HabitQuickAddBody> {
  final _minutes = TextEditingController(text: '0');
  final _pages = TextEditingController(text: '0');
  String? _bookId;
  bool _submitting = false;

  @override
  void dispose() {
    _minutes.dispose();
    _pages.dispose();
    super.dispose();
  }

  int _parseInt(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v ?? 0;
  }

  Future<void> _submit() async {
    final minutes = _parseInt(_minutes);
    final pages = _parseInt(_pages);
    setState(() => _submitting = true);
    try {
      await ref.read(habitLogControllerProvider).addLog(
            bookId: _bookId,
            minutesRead: minutes,
            pagesRead: pages,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading logged')),
        );
      }
    } on HabitValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(habitBookChoicesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick log', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Add at least minutes or pages from today.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _minutes,
              decoration: const InputDecoration(
                labelText: 'Minutes',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    final n = _parseInt(_minutes);
                    _minutes.text = '${n + 10}';
                  },
                  child: const Text('+10 min'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pages,
              decoration: const InputDecoration(
                labelText: 'Pages',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    final n = _parseInt(_pages);
                    _pages.text = '${n + 5}';
                  },
                  child: const Text('+5 pages'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            booksAsync.when(
              data: (choices) {
                if (choices.isEmpty) {
                  return Text(
                    'Optional: add books to your reading list to pick one here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book (optional)',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    DropdownMenu<String?>(
                      key: ValueKey<String?>(_bookId),
                      initialSelection: _bookId,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Book'),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry<String?>(
                          value: null,
                          label: 'None',
                        ),
                        ...choices.map(
                          (c) => DropdownMenuEntry<String?>(
                            value: c.id,
                            label: c.label,
                          ),
                        ),
                      ],
                      onSelected: (v) => setState(() => _bookId = v),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (e, _) => Text('Books: $e'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save log'),
            ),
          ],
        ),
      ),
    );
  }
}
