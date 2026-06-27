import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../user_books/domain/entities/user_book_entity.dart';
import '../../domain/entities/habit_reading_book_choice.dart';

class HabitReadingBookLogDraft {
  HabitReadingBookLogDraft({int initialProgress = 0})
      : minutes = TextEditingController(),
        pages = TextEditingController(),
        progress = initialProgress,
        _initialProgress = initialProgress;

  bool selected = false;
  final TextEditingController minutes;
  final TextEditingController pages;
  int progress;
  final int _initialProgress;

  void dispose() {
    minutes.dispose();
    pages.dispose();
  }

  int parseMinutes() => int.tryParse(minutes.text.trim()) ?? 0;

  int parsePages() => int.tryParse(pages.text.trim()) ?? 0;

  bool get progressChanged => progress != _initialProgress;
}

class HabitReadingBookLogTile extends StatelessWidget {
  const HabitReadingBookLogTile({
    super.key,
    required this.choice,
    required this.draft,
    required this.onSelectedChanged,
    required this.onProgressChanged,
    required this.onChanged,
  });

  final HabitReadingBookChoice choice;
  final HabitReadingBookLogDraft draft;
  final ValueChanged<bool> onSelectedChanged;
  final ValueChanged<int> onProgressChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      if (choice.author != null && choice.author!.isNotEmpty) choice.author!,
      if (choice.progress != null) '${choice.progress}%',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              value: draft.selected,
              onChanged: (value) => onSelectedChanged(value ?? false),
              title: Text(
                choice.title,
                style: theme.textTheme.titleSmall,
              ),
              subtitle: subtitleParts.isEmpty
                  ? null
                  : Text(subtitleParts.join(' • ')),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: draft.selected
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: draft.minutes,
                          enabled: draft.selected,
                          onChanged: (_) => onChanged(),
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
                        onPressed: draft.selected
                            ? () {
                                draft.minutes.text =
                                    '${draft.parseMinutes() + 10}';
                                onChanged();
                              }
                            : null,
                        child: Text(l10n.plusTenMin),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: draft.pages,
                          enabled: draft.selected,
                          onChanged: (_) => onChanged(),
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
                        onPressed: draft.selected
                            ? () {
                                draft.pages.text = '${draft.parsePages() + 5}';
                                onChanged();
                              }
                            : null,
                        child: Text(l10n.plusFivePages),
                      ),
                    ],
                  ),
                  if (choice.status == ReadingStatus.reading) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.progressPercent(draft.progress),
                      style: theme.textTheme.bodySmall,
                    ),
                    Slider(
                      value: draft.progress.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${draft.progress}%',
                      onChanged: draft.selected
                          ? (value) => onProgressChanged(value.round())
                          : null,
                    ),
                  ],
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
