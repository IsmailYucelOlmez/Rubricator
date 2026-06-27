import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/login_page.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../providers/book_notes_providers.dart';
import '../widgets/book_note_feedback.dart';

class MyNotesPage extends ConsumerStatefulWidget {
  const MyNotesPage({super.key});

  @override
  ConsumerState<MyNotesPage> createState() => _MyNotesPageState();
}

class _MyNotesPageState extends ConsumerState<MyNotesPage> {
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
      ref.read(myNotesProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(myNotesProvider.notifier).setSearchQuery(value);
    });
  }

  void _openBook(String bookId, String? title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailPage(
          book: Book(
            id: bookId,
            title: title ?? bookId,
            author: '',
            description: '',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await confirmDeleteBookNote(context);
    if (confirm != true || !mounted) return;
    try {
      await ref.read(myNotesProvider.notifier).deleteNote(noteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noteDeleted)),
      );
    } catch (e) {
      if (!mounted) return;
      showBookNoteFeedback(context, e);
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myNotes)),
      body: user == null
          ? ResponsiveScaffoldBody(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.signInToSeeNotes),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<bool>(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(l10n.signIn),
                    ),
                  ],
                ),
              ),
            )
          : ResponsiveScaffoldBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchNotesHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  _TagFilterBar(
                    onSelected: (tag) =>
                        ref.read(myNotesProvider.notifier).setSelectedTag(tag),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final async = ref.watch(myNotesProvider);
                        final titlesAsync = ref.watch(myNotesBookTitlesProvider);
                        final titles = titlesAsync.valueOrNull ?? const {};

                        return async.when(
                          data: (state) {
                            if (state.notes.isEmpty) {
                              return Center(child: Text(l10n.noMyNotesYet));
                            }
                            return ListView.builder(
                              controller: _scrollController,
                              itemCount: state.notes.length +
                                  (state.loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= state.notes.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(AppSpacing.md),
                                    child: Center(
                                      child: AppLoadingIndicator(),
                                    ),
                                  );
                                }
                                final note = state.notes[index];
                                final bookTitle =
                                    titles[note.bookId] ?? note.bookId;
                                return ListTile(
                                  title: Text(note.noteTitle),
                                  subtitle: Text(
                                    '$bookTitle · ${_formatDate(note.createdAt)}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteNote(note.id),
                                  ),
                                  onTap: () =>
                                      _openBook(note.bookId, titles[note.bookId]),
                                );
                              },
                            );
                          },
                          loading: () => const AppLoadingIndicator(),
                          error: (error, stackTrace) => AsyncErrorView(
                            error: error,
                            onRetry: () =>
                                ref.read(myNotesProvider.notifier).refresh(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TagFilterBar extends ConsumerWidget {
  const _TagFilterBar({required this.onSelected});

  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(myNoteTagsProvider);
    final selectedTag = ref.watch(myNotesProvider).valueOrNull?.selectedTag;

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: FilterChip(
                  label: Text(AppLocalizations.of(context)!.allTags),
                  selected: selectedTag == null,
                  onSelected: (_) => onSelected(null),
                ),
              ),
              for (final tag in tags)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    label: Text(tag),
                    selected: selectedTag == tag,
                    onSelected: (_) =>
                        onSelected(selectedTag == tag ? null : tag),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
