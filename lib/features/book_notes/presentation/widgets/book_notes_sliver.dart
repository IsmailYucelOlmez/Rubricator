import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../domain/entities/book_note_entity.dart';
import '../providers/book_notes_providers.dart';
import 'book_note_card.dart';
import 'book_note_feedback.dart';
import 'book_note_form_sheet.dart';

/// Public notes for a book as slivers (search field + lazily built list),
/// meant to sit inside the book detail page's scroll view. The next page is
/// requested once the last note is laid out, i.e. scrolled near.
class BookNotesSliver extends ConsumerStatefulWidget {
  const BookNotesSliver({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookNotesSliver> createState() => _BookNotesSliverState();
}

class _BookNotesSliverState extends ConsumerState<BookNotesSliver> {
  static const _stateMinHeight = 160.0;

  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _deletingNoteId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMore() {
    if (!mounted) return;
    ref.read(publicBookNotesProvider(widget.bookId).notifier).loadMore();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(publicBookNotesProvider(widget.bookId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _showEditSheet(BookNoteEntity note) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await showBookNoteFormSheet(
        context,
        bookId: widget.bookId,
        initial: note,
        onSubmit:
            ({
              required noteTitle,
              required noteContent,
              pageNumber,
              chapterTitle,
              required tags,
              required isPublic,
            }) async {
              await ref
                  .read(publicBookNotesProvider(widget.bookId).notifier)
                  .updateNote(
                    note.copyWith(
                      noteTitle: noteTitle,
                      noteContent: noteContent,
                      pageNumber: pageNumber,
                      clearPageNumber: pageNumber == null,
                      chapterTitle: chapterTitle,
                      clearChapterTitle: chapterTitle == null,
                      tags: tags,
                      isPublic: isPublic,
                    ),
                  );
            },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noteUpdated)));
    } catch (e) {
      if (!mounted) return;
      showBookNoteFeedback(context, e);
    }
  }

  Future<void> _deleteNote(BookNoteEntity note) async {
    if (_deletingNoteId != null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirm = await confirmDeleteBookNote(context);
    if (confirm != true || !mounted) return;
    setState(() => _deletingNoteId = note.id);
    try {
      await ref
          .read(publicBookNotesProvider(widget.bookId).notifier)
          .deleteNote(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noteDeleted)));
    } catch (e) {
      if (!mounted) return;
      showBookNoteFeedback(context, e);
    } finally {
      if (mounted) setState(() => _deletingNoteId = null);
    }
  }

  Widget _state(Widget child) => SliverToBoxAdapter(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _stateMinHeight),
      child: Center(child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(publicBookNotesProvider(widget.bookId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final currentUserDisplayName = ref.watch(currentUserDisplayNameProvider);

    final Widget list = switch (async) {
      AsyncValue(:final valueOrNull?) when valueOrNull.notes.isEmpty => _state(
        Text(l10n.noPublicNotesYet, textAlign: TextAlign.center),
      ),
      AsyncValue(:final valueOrNull?) => SliverList.separated(
        itemCount: valueOrNull.notes.length + (valueOrNull.loadingMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final notes = valueOrNull.notes;
          if (index >= notes.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: AppLoadingIndicator()),
            );
          }
          if (index == notes.length - 1 && valueOrNull.hasMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
          }
          final note = notes[index];
          final own = note.userId == currentUserId;
          return BookNoteCard(
            note: note,
            currentUserId: currentUserId,
            currentUserDisplayName: currentUserDisplayName,
            onEdit: own && _deletingNoteId == null
                ? () => _showEditSheet(note)
                : null,
            onDelete: own && _deletingNoteId == null
                ? () => _deleteNote(note)
                : null,
            isDeleting: _deletingNoteId == note.id,
          );
        },
      ),
      AsyncError(:final error) => _state(
        AsyncErrorView(
          error: error,
          compact: true,
          onRetry: () => ref
              .read(publicBookNotesProvider(widget.bookId).notifier)
              .refresh(),
        ),
      ),
      _ => _state(const AppLoadingIndicator()),
    };

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchNotesHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
        list,
      ],
    );
  }
}
