import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';

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
        final l10n = AppLocalizations.of(context)!;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.readingLogged)),
        );
      }
    } on HabitValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotSave(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(habitBookChoicesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md + AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.md + AppSpacing.xs,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.quickLog, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.addMinutesOrPagesPrompt,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md + AppSpacing.xs),
            TextField(
              controller: _minutes,
              decoration: InputDecoration(
                labelText: l10n.minutes,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: () {
                    final n = _parseInt(_minutes);
                    _minutes.text = '${n + 10}';
                  },
                  child: Text(l10n.plusTenMin),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            TextField(
              controller: _pages,
              decoration: InputDecoration(
                labelText: l10n.pages,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: () {
                    final n = _parseInt(_pages);
                    _pages.text = '${n + 5}';
                  },
                  child: Text(l10n.plusFivePages),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            booksAsync.when(
              data: (choices) {
                if (choices.isEmpty) {
                  return Text(
                    l10n.optionalAddBooksPrompt,
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bookOptional,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownMenu<String?>(
                      key: ValueKey<String?>(_bookId),
                      initialSelection: _bookId,
                      expandedInsets: EdgeInsets.zero,
                      label: Text(l10n.book),
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
              error: (e, _) => Text(l10n.booksError(e.toString())),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const AppLoadingIndicator(
                      size: 22,
                      strokeWidth: 2,
                      centered: false,
                    )
                  : Text(l10n.saveLog),
            ),
          ],
        ),
      ),
    );
  }
}
