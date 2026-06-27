import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../domain/entities/book_note_entity.dart';
import '../providers/book_notes_providers.dart';
import 'book_note_card.dart';
import 'book_note_feedback.dart';
import 'book_note_form_sheet.dart';

class BookNotesTab extends ConsumerStatefulWidget {
  const BookNotesTab({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookNotesTab> createState() => _BookNotesTabState();
}

class _BookNotesTabState extends ConsumerState<BookNotesTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels >= max - 120) {
      ref.read(publicBookNotesProvider(widget.bookId).notifier).loadMore();
    }
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
        onSubmit: ({
          required noteTitle,
          required noteContent,
          pageNumber,
          chapterTitle,
          required tags,
          required isPublic,
        }) async {
          await ref.read(publicBookNotesProvider(widget.bookId).notifier).updateNote(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noteUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      showBookNoteFeedback(context, e);
    }
  }

  Future<void> _deleteNote(BookNoteEntity note) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await confirmDeleteBookNote(context);
    if (confirm != true || !mounted) return;
    try {
      await ref
          .read(publicBookNotesProvider(widget.bookId).notifier)
          .deleteNote(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noteDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      showBookNoteFeedback(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(publicBookNotesProvider(widget.bookId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchNotesHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: async.when(
            data: (state) {
              if (state.notes.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noPublicNotesYet,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                itemCount: state.notes.length + (state.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.notes.length) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: AppLoadingIndicator()),
                    );
                  }
                  final note = state.notes[index];
                  return BookNoteCard(
                    note: note,
                    currentUserId: currentUserId,
                    onEdit: note.userId == currentUserId
                        ? () => _showEditSheet(note)
                        : null,
                    onDelete: note.userId == currentUserId
                        ? () => _deleteNote(note)
                        : null,
                  );
                },
              );
            },
            loading: () => const AppLoadingIndicator(),
            error: (error, stackTrace) => AsyncErrorView(
              error: error,
              compact: true,
              onRetry: () => ref
                  .read(publicBookNotesProvider(widget.bookId).notifier)
                  .refresh(),
            ),
          ),
        ),
      ],
    );
  }
}
