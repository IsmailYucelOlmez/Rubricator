import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../data/datasources/book_notes_remote_datasource.dart';
import '../../data/repositories/book_notes_repository_impl.dart';
import '../../domain/entities/book_note_entity.dart';
import '../../domain/repositories/book_notes_repository.dart';
import '../../domain/usecases/book_notes_usecases.dart';

const bookNotesPageSize = 20;

final _bookNotesRemoteProvider = Provider<BookNotesRemoteDataSource>(
  (ref) => BookNotesRemoteDataSource(Supabase.instance.client),
);

final bookNotesRepositoryProvider = Provider<BookNotesRepository>((ref) {
  return BookNotesRepositoryImpl(
    ref.watch(_bookNotesRemoteProvider),
    () => ref.watch(currentUserIdProvider),
  );
});

final getPublicNotesByBookUseCaseProvider = Provider<GetPublicNotesByBookUseCase>(
  (ref) => GetPublicNotesByBookUseCase(ref.watch(bookNotesRepositoryProvider)),
);

final getMyNotesUseCaseProvider = Provider<GetMyNotesUseCase>(
  (ref) => GetMyNotesUseCase(ref.watch(bookNotesRepositoryProvider)),
);

final getMyNoteTagsUseCaseProvider = Provider<GetMyNoteTagsUseCase>(
  (ref) => GetMyNoteTagsUseCase(ref.watch(bookNotesRepositoryProvider)),
);

final addBookNoteUseCaseProvider = Provider<AddBookNoteUseCase>(
  (ref) => AddBookNoteUseCase(ref.watch(bookNotesRepositoryProvider)),
);

final updateBookNoteUseCaseProvider = Provider<UpdateBookNoteUseCase>(
  (ref) => UpdateBookNoteUseCase(ref.watch(bookNotesRepositoryProvider)),
);

final deleteBookNoteUseCaseProvider = Provider<DeleteBookNoteUseCase>(
  (ref) => DeleteBookNoteUseCase(ref.watch(bookNotesRepositoryProvider)),
);

class PaginatedNotesState {
  const PaginatedNotesState({
    required this.notes,
    required this.hasMore,
    required this.loadingMore,
    required this.searchQuery,
    this.selectedTag,
  });

  final List<BookNoteEntity> notes;
  final bool hasMore;
  final bool loadingMore;
  final String searchQuery;
  final String? selectedTag;

  PaginatedNotesState copyWith({
    List<BookNoteEntity>? notes,
    bool? hasMore,
    bool? loadingMore,
    String? searchQuery,
    String? selectedTag,
    bool clearSelectedTag = false,
  }) {
    return PaginatedNotesState(
      notes: notes ?? this.notes,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag:
          clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
    );
  }
}

List<String>? _tagFilter(String? tag) {
  if (tag == null || tag.isEmpty) return null;
  return [tag];
}

void _invalidateMyNotesCaches(Ref ref) {
  ref.invalidate(myNotesProvider);
  ref.invalidate(myNoteTagsProvider);
}

class PublicBookNotesNotifier
    extends FamilyAsyncNotifier<PaginatedNotesState, String> {
  late final String _bookId;

  @override
  Future<PaginatedNotesState> build(String arg) async {
    _bookId = arg;
    final notes = await ref.read(getPublicNotesByBookUseCaseProvider).call(
          _bookId,
          limit: bookNotesPageSize,
        );
    return PaginatedNotesState(
      notes: notes,
      hasMore: notes.length >= bookNotesPageSize,
      loadingMore: false,
      searchQuery: '',
    );
  }

  Future<void> setSearchQuery(String query) async {
    final trimmed = query.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final notes = await ref.read(getPublicNotesByBookUseCaseProvider).call(
            _bookId,
            searchQuery: trimmed.isEmpty ? null : trimmed,
            limit: bookNotesPageSize,
          );
      return PaginatedNotesState(
        notes: notes,
        hasMore: notes.length >= bookNotesPageSize,
        loadingMore: false,
        searchQuery: trimmed,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final more = await ref.read(getPublicNotesByBookUseCaseProvider).call(
            _bookId,
            searchQuery:
                current.searchQuery.isEmpty ? null : current.searchQuery,
            limit: bookNotesPageSize,
            offset: current.notes.length,
          );
      state = AsyncData(
        current.copyWith(
          notes: [...current.notes, ...more],
          hasMore: more.length >= bookNotesPageSize,
          loadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final search = current?.searchQuery ?? '';
    await setSearchQuery(search);
  }

  Future<void> addNote({
    required String noteTitle,
    required String noteContent,
    int? pageNumber,
    String? chapterTitle,
    required List<String> tags,
    required bool isPublic,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Sign in required.');
    final search = state.valueOrNull?.searchQuery ?? '';

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(addBookNoteUseCaseProvider).call(
            BookNoteEntity(
              id: '',
              userId: userId,
              bookId: _bookId,
              pageNumber: pageNumber,
              chapterTitle: chapterTitle,
              noteTitle: noteTitle,
              noteContent: noteContent,
              tags: tags,
              isPublic: isPublic,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      _invalidateMyNotesCaches(ref);
      final notes = await ref.read(getPublicNotesByBookUseCaseProvider).call(
            _bookId,
            searchQuery: search.isEmpty ? null : search,
            limit: bookNotesPageSize,
          );
      return PaginatedNotesState(
        notes: notes,
        hasMore: notes.length >= bookNotesPageSize,
        loadingMore: false,
        searchQuery: search,
      );
    });
  }

  Future<void> updateNote(BookNoteEntity note) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(updateBookNoteUseCaseProvider).call(note);
      _invalidateMyNotesCaches(ref);
      return _reloadCurrent();
    });
  }

  Future<void> deleteNote(String noteId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deleteBookNoteUseCaseProvider).call(noteId);
      _invalidateMyNotesCaches(ref);
      return _reloadCurrent();
    });
  }

  Future<PaginatedNotesState> _reloadCurrent() async {
    final search = state.valueOrNull?.searchQuery ?? '';
    final notes = await ref.read(getPublicNotesByBookUseCaseProvider).call(
          _bookId,
          searchQuery: search.isEmpty ? null : search,
          limit: bookNotesPageSize,
        );
    return PaginatedNotesState(
      notes: notes,
      hasMore: notes.length >= bookNotesPageSize,
      loadingMore: false,
      searchQuery: search,
    );
  }
}

final publicBookNotesProvider = AsyncNotifierProviderFamily<
    PublicBookNotesNotifier, PaginatedNotesState, String>(
  PublicBookNotesNotifier.new,
);

class MyNotesNotifier extends AsyncNotifier<PaginatedNotesState> {
  @override
  Future<PaginatedNotesState> build() async {
    ref.watch(authStateProvider);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const PaginatedNotesState(
        notes: [],
        hasMore: false,
        loadingMore: false,
        searchQuery: '',
      );
    }
    final notes = await ref.read(getMyNotesUseCaseProvider).call(
          limit: bookNotesPageSize,
        );
    return PaginatedNotesState(
      notes: notes,
      hasMore: notes.length >= bookNotesPageSize,
      loadingMore: false,
      searchQuery: '',
    );
  }

  Future<void> setSearchQuery(String query) async {
    final trimmed = query.trim();
    final selectedTag = state.valueOrNull?.selectedTag;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final notes = await ref.read(getMyNotesUseCaseProvider).call(
            searchQuery: trimmed.isEmpty ? null : trimmed,
            tagFilter: _tagFilter(selectedTag),
            limit: bookNotesPageSize,
          );
      return PaginatedNotesState(
        notes: notes,
        hasMore: notes.length >= bookNotesPageSize,
        loadingMore: false,
        searchQuery: trimmed,
        selectedTag: selectedTag,
      );
    });
  }

  Future<void> setSelectedTag(String? tag) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final notes = await ref.read(getMyNotesUseCaseProvider).call(
            searchQuery: current?.searchQuery.isEmpty ?? true
                ? null
                : current!.searchQuery,
            tagFilter: _tagFilter(tag),
            limit: bookNotesPageSize,
          );
      return PaginatedNotesState(
        notes: notes,
        hasMore: notes.length >= bookNotesPageSize,
        loadingMore: false,
        searchQuery: current?.searchQuery ?? '',
        selectedTag: tag,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final more = await ref.read(getMyNotesUseCaseProvider).call(
            searchQuery:
                current.searchQuery.isEmpty ? null : current.searchQuery,
            tagFilter: _tagFilter(current.selectedTag),
            limit: bookNotesPageSize,
            offset: current.notes.length,
          );
      state = AsyncData(
        current.copyWith(
          notes: [...current.notes, ...more],
          hasMore: more.length >= bookNotesPageSize,
          loadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    ref.invalidate(myNoteTagsProvider);
    final current = state.valueOrNull;
    await setSearchQuery(current?.searchQuery ?? '');
    if (current?.selectedTag != null) {
      await setSelectedTag(current!.selectedTag);
    }
  }

  Future<void> deleteNote(String noteId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deleteBookNoteUseCaseProvider).call(noteId);
      _invalidateMyNotesCaches(ref);
      return _reloadCurrent();
    });
  }

  Future<PaginatedNotesState> _reloadCurrent() async {
    final current = state.valueOrNull;
    final notes = await ref.read(getMyNotesUseCaseProvider).call(
          searchQuery: current?.searchQuery.isEmpty ?? true
              ? null
              : current!.searchQuery,
          tagFilter: _tagFilter(current?.selectedTag),
          limit: bookNotesPageSize,
        );
    return PaginatedNotesState(
      notes: notes,
      hasMore: notes.length >= bookNotesPageSize,
      loadingMore: false,
      searchQuery: current?.searchQuery ?? '',
      selectedTag: current?.selectedTag,
    );
  }

}

final myNotesProvider =
    AsyncNotifierProvider<MyNotesNotifier, PaginatedNotesState>(
  MyNotesNotifier.new,
);

final myNoteTagsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.read(getMyNoteTagsUseCaseProvider).call();
});

const _bookTitleFetchConcurrency = 4;

Future<Map<String, String>> resolveBookNoteTitles(
  Ref ref,
  Iterable<String> bookIds,
) async {
  final bookRepo = ref.read(bookRepositoryProvider);
  final titles = <String, String>{};
  final ids = bookIds.where((id) => id.trim().isNotEmpty).toSet().toList();
  for (var i = 0; i < ids.length; i += _bookTitleFetchConcurrency) {
    final end = (i + _bookTitleFetchConcurrency > ids.length)
        ? ids.length
        : i + _bookTitleFetchConcurrency;
    final chunk = ids.sublist(i, end);
    await Future.wait(
      chunk.map((bookId) async {
        try {
          titles[bookId] = (await bookRepo.getBookByWorkId(bookId)).title;
        } catch (_) {}
      }),
    );
  }
  return titles;
}

final myNotesBookTitlesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  ref.watch(authStateProvider);
  final notesState = await ref.watch(myNotesProvider.future);
  return resolveBookNoteTitles(
    ref,
    notesState.notes.map((n) => n.bookId),
  );
});
