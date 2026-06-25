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
import '../../domain/entities/habit_reading_book_choice.dart';
import '../../domain/usecases/habit_usecases.dart';
import '../providers/habit_providers.dart';
import 'habit_reading_book_log_tile.dart';

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
  final _generalMinutes = TextEditingController();
  final _generalPages = TextEditingController();
  final _bookDrafts = <String, HabitReadingBookLogDraft>{};
  bool _generalSelected = false;
  bool _submitting = false;
  String? _formError;
  List<HabitReadingBookChoice>? _loadedChoices;

  @override
  void initState() {
    super.initState();
    for (final controller in [_generalMinutes, _generalPages]) {
      controller.addListener(_clearFormError);
    }
  }

  void _clearFormError() {
    if (_formError == null) return;
    setState(() => _formError = null);
  }

  void _syncBookDrafts(List<HabitReadingBookChoice> choices) {
    if (_loadedChoices != null &&
        _choicesEqual(_loadedChoices!, choices)) {
      return;
    }
    for (final draft in _bookDrafts.values) {
      draft.dispose();
    }
    _bookDrafts
      ..clear()
      ..addEntries(
        choices.map(
          (choice) => MapEntry(choice.bookId, HabitReadingBookLogDraft()),
        ),
      );
    _loadedChoices = choices;
  }

  bool _choicesEqual(
    List<HabitReadingBookChoice> a,
    List<HabitReadingBookChoice> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].bookId != b[i].bookId) return false;
    }
    return true;
  }

  @override
  void dispose() {
    for (final controller in [_generalMinutes, _generalPages]) {
      controller
        ..removeListener(_clearFormError)
        ..dispose();
    }
    for (final draft in _bookDrafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  int _parseInt(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v ?? 0;
  }

  List<({String? bookId, int minutesRead, int pagesRead})> _collectEntries() {
    final entries = <({String? bookId, int minutesRead, int pagesRead})>[];

    for (final entry in _bookDrafts.entries) {
      final draft = entry.value;
      if (!draft.selected) continue;
      final minutes = draft.parseMinutes();
      final pages = draft.parsePages();
      if (minutes <= 0 && pages <= 0) continue;
      entries.add((
        bookId: entry.key,
        minutesRead: minutes,
        pagesRead: pages,
      ));
    }

    if (_generalSelected) {
      final minutes = _parseInt(_generalMinutes);
      final pages = _parseInt(_generalPages);
      if (minutes > 0 || pages > 0) {
        entries.add((
          bookId: null,
          minutesRead: minutes,
          pagesRead: pages,
        ));
      }
    } else if (_bookDrafts.isEmpty) {
      final minutes = _parseInt(_generalMinutes);
      final pages = _parseInt(_generalPages);
      if (minutes > 0 || pages > 0) {
        entries.add((
          bookId: null,
          minutesRead: minutes,
          pagesRead: pages,
        ));
      }
    }

    return entries;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final entries = _collectEntries();

    if (entries.isEmpty) {
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
      final result =
          await ref.read(habitLogControllerProvider).addLogs(entries);
      if (!mounted) return;

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.savedOffline
                ? l10n.readingLoggedOffline
                : entries.length > 1
                    ? l10n.readingLoggedCount(entries.length)
                    : l10n.readingLogged,
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

  Widget _buildGeneralLogSection(
    AppLocalizations l10n, {
    required bool optional,
  }) {
    if (!optional) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _generalMinutes,
            decoration: InputDecoration(labelText: l10n.minutes),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: () {
                  final n = _parseInt(_generalMinutes);
                  _generalMinutes.text = '${n + 10}';
                },
                child: Text(l10n.plusTenMin),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          TextField(
            controller: _generalPages,
            decoration: InputDecoration(labelText: l10n.pages),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: () {
                  final n = _parseInt(_generalPages);
                  _generalPages.text = '${n + 5}';
                },
                child: Text(l10n.plusFivePages),
              ),
            ],
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _generalSelected,
              onChanged: (value) {
                setState(() => _generalSelected = value ?? false);
              },
              title: Text(l10n.generalReadingLog),
              subtitle: Text(l10n.generalReadingLogHint),
            ),
            if (_generalSelected) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _generalMinutes,
                      decoration: InputDecoration(
                        labelText: l10n.minutes,
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final n = _parseInt(_generalMinutes);
                      _generalMinutes.text = '${n + 10}';
                    },
                    child: Text(l10n.plusTenMin),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _generalPages,
                      decoration: InputDecoration(
                        labelText: l10n.pages,
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final n = _parseInt(_generalPages);
                      _generalPages.text = '${n + 5}';
                    },
                    child: Text(l10n.plusFivePages),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
              l10n.selectBooksToLog,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            booksAsync.when(
              data: (choices) {
                _syncBookDrafts(choices);
                if (choices.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.noReadingBooksForLog,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildGeneralLogSection(l10n, optional: false),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.currentlyReadingBooks,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...choices.map((choice) {
                      final draft = _bookDrafts[choice.bookId]!;
                      return HabitReadingBookLogTile(
                        choice: choice,
                        draft: draft,
                        onSelectedChanged: (selected) {
                          setState(() => draft.selected = selected);
                        },
                        onChanged: _clearFormError,
                      );
                    }),
                    const SizedBox(height: AppSpacing.sm),
                    _buildGeneralLogSection(l10n, optional: true),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: AppLoadingIndicator(),
              ),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.noReadingBooksForLog,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildGeneralLogSection(l10n, optional: false),
                ],
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
