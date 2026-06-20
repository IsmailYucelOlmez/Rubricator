import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/notification/reading_reminder_prefs.dart';
import '../../../../core/notification/reading_reminder_scheduler.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ux/l10n_app_error.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/usecases/habit_usecases.dart';
import '../providers/habit_providers.dart';

Future<void> showHabitAddLogBottomSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const _HabitAddLogBody(),
      );
    },
  );
}

class _HabitAddLogBody extends ConsumerStatefulWidget {
  const _HabitAddLogBody();

  @override
  ConsumerState<_HabitAddLogBody> createState() => _HabitAddLogBodyState();
}

class _HabitAddLogBodyState extends ConsumerState<_HabitAddLogBody> {
  final _minutes = TextEditingController();
  final _pages = TextEditingController();
  String? _bookId;
  bool _submitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    for (final controller in [_minutes, _pages]) {
      controller.addListener(_clearFormError);
    }
  }

  void _clearFormError() {
    if (_formError == null) return;
    setState(() => _formError = null);
  }

  @override
  void dispose() {
    for (final controller in [_minutes, _pages]) {
      controller
        ..removeListener(_clearFormError)
        ..dispose();
    }
    super.dispose();
  }

  int _parseInt(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v ?? 0;
  }

  String? _normalizedBookId() {
    final raw = _bookId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> _submit() async {
    final minutes = _parseInt(_minutes);
    final pages = _parseInt(_pages);
    final l10n = AppLocalizations.of(context)!;

    if (minutes <= 0 && pages <= 0) {
      setState(() => _formError = l10n.addMinutesOrPagesPrompt);
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final bookId = _normalizedBookId();
      final result = await ref.read(habitLogControllerProvider).addLog(
            bookId: bookId,
            minutesRead: minutes,
            pagesRead: pages,
          );
      if (!mounted) return;

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.savedOffline ? l10n.readingLoggedOffline : l10n.readingLogged,
          ),
        ),
      );
      unawaited(_syncReminderAfterLog(ref));
    } on HabitValidationException catch (e) {
      if (mounted) {
        setState(() => _formError = e.message);
      }
    } on StateError {
      if (mounted) {
        setState(() => _formError = l10n.signInForHabit);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _formError = l10n.userFacingMessage(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static Future<void> _syncReminderAfterLog(WidgetRef ref) async {
    try {
      final stats = await ref.read(readingStatsProvider.future);
      await ReadingReminderScheduler.syncStreakAfterLog(
        currentStreak: stats.currentStreak,
      );
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final savedStreak = prefs.getInt(kReadingReminderStreakKey) ?? 0;
      await ReadingReminderScheduler.syncStreakAfterLog(
        currentStreak: savedStreak,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final booksAsync = ref.watch(habitReadingBookChoicesProvider);

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
            Text(l10n.log, style: Theme.of(context).textTheme.titleLarge),
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
                    l10n.noReadingBooksForLog,
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectReadingBook,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...choices.map(
                      (choice) {
                        final selected = _bookId == choice.id;
                        return ListTile(
                          title: Text(choice.label),
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          selected: selected,
                          onTap: () => setState(() => _bookId = choice.id),
                        );
                      },
                    ),
                    ListTile(
                      title: Text(l10n.none),
                      leading: Icon(
                        _bookId == null
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      selected: _bookId == null,
                      onTap: () => setState(() => _bookId = null),
                    ),
                  ],
                );
              },
              loading: () => Text(
                l10n.selectReadingBook,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              error: (error, _) => Text(
                l10n.noReadingBooksForLog,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 24),
            if (_formError != null) ...[
              Text(
                _formError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
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
