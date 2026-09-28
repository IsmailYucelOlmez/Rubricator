import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_loading.dart';
import '../../../../user_books/domain/entities/user_book_entity.dart';
import '../../../../user_books/domain/entities/user_book_snapshot.dart';
import '../../../../user_books/presentation/providers/user_books_provider.dart';
import '../../../domain/entities/book_detail_entities.dart';
import 'book_detail_common.dart';

UserBookSnapshot userBookSnapshotOf(BookEntity book) => UserBookSnapshot(
  title: book.title,
  author: book.author,
  categories: book.subjectKeys,
);

String readingStatusLabel(ReadingStatus status, AppLocalizations l10n) {
  return switch (status) {
    ReadingStatus.toRead => l10n.toRead,
    ReadingStatus.reading => l10n.reading,
    ReadingStatus.completed => l10n.completed,
    ReadingStatus.dropped => l10n.dropped,
    ReadingStatus.reReading => l10n.reReading,
  };
}

/// Reading status + progress for the signed-in user.
class ReadingStatusCard extends ConsumerStatefulWidget {
  const ReadingStatusCard({super.key, required this.book});

  final BookEntity book;

  @override
  ConsumerState<ReadingStatusCard> createState() => _ReadingStatusCardState();
}

class _ReadingStatusCardState extends ConsumerState<ReadingStatusCard> {
  static const _progressDebounceDuration = Duration(milliseconds: 400);

  Timer? _progressDebounce;

  /// Slider value while the user drags / a save is pending; `null` follows
  /// the stored progress.
  int? _localProgress;

  @override
  void dispose() {
    _progressDebounce?.cancel();
    super.dispose();
  }

  UserBookNotifier get _notifier =>
      ref.read(userBookProvider(widget.book.id).notifier);

  Future<void> _openStatusSheet(UserBookEntity? userBook) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<_StatusChoice>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ReadingStatusSheet(current: userBook?.status),
    );
    if (choice == null || !mounted) return;

    try {
      final status = choice.status;
      if (status == null) {
        if (userBook == null) return;
        if (userBook.isFavorite &&
            !await confirmDelete(
              context,
              title: l10n.removeFromListTitle,
              message: l10n.removeFavoriteFromListMessage,
              confirmLabel: l10n.remove,
            )) {
          return;
        }
        await _notifier.remove();
        if (mounted) showBookDetailMessage(context, l10n.removedFromList);
        return;
      }
      await _notifier.upsert(
        status: status,
        isFavorite: userBook?.isFavorite ?? false,
        snapshot: userBookSnapshotOf(widget.book),
      );
    } catch (e) {
      if (mounted) showBookDetailError(context, e);
    }
  }

  Future<void> _persistProgress(int value, UserBookEntity? userBook) async {
    _progressDebounce?.cancel();
    _progressDebounce = null;
    final completed = value >= 100;
    try {
      await _notifier.upsert(
        status: completed
            ? ReadingStatus.completed
            : (userBook?.status ?? ReadingStatus.reading),
        isFavorite: userBook?.isFavorite ?? false,
        progress: completed ? null : value,
        snapshot: userBookSnapshotOf(widget.book),
      );
    } catch (e) {
      if (mounted) showBookDetailError(context, e);
    } finally {
      if (mounted && _progressDebounce == null) {
        setState(() => _localProgress = null);
      }
    }
  }

  void _onProgressChanged(int value, UserBookEntity? userBook) {
    setState(() => _localProgress = value);
    _progressDebounce?.cancel();
    _progressDebounce = Timer(
      _progressDebounceDuration,
      () => _persistProgress(value, userBook),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(userBookProvider(widget.book.id));
    if (async.isLoading && !async.hasValue) {
      return const AppSkeletonBox(height: 72);
    }
    final userBook = async.valueOrNull;
    final status = userBook?.status;
    final progress = status == ReadingStatus.completed
        ? 100
        : (_localProgress ?? userBook?.progress ?? 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    status == null
                        ? l10n.addToList
                        : readingStatusLabel(status, l10n),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => _openStatusSheet(userBook),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                  ),
                  child: Text(l10n.change),
                ),
              ],
            ),
            if (status == ReadingStatus.reading) ...[
              Text(
                l10n.progressPercent(progress),
                style: bookDetailBodyStyle(context),
              ),
              Slider(
                value: progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$progress%',
                onChanged: (value) =>
                    _onProgressChanged(value.round(), userBook),
                onChangeEnd: (value) =>
                    _persistProgress(value.round(), userBook),
              ),
            ] else if (status == ReadingStatus.completed) ...[
              Text(
                l10n.progressPercent(progress),
                style: bookDetailBodyStyle(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.md,
                ),
                child: LinearProgressIndicator(
                  value: 1,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sheet result: a status to set, or `status == null` to remove the book
/// from the user's list (tapping the currently selected status).
typedef _StatusChoice = ({ReadingStatus? status});

class _ReadingStatusSheet extends StatelessWidget {
  const _ReadingStatusSheet({required this.current});

  final ReadingStatus? current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final status in ReadingStatus.values)
            ListTile(
              selected: current == status,
              leading: Icon(
                current == status
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: current == status ? cs.primary : null,
              ),
              title: Text(readingStatusLabel(status, l10n)),
              trailing: current == status
                  ? Icon(Icons.close, size: 18, color: cs.onSurfaceVariant)
                  : null,
              onTap: () => Navigator.of(
                context,
              ).pop<_StatusChoice>((status: current == status ? null : status)),
            ),
        ],
      ),
    );
  }
}
