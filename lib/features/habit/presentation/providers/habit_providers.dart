import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../../user_books/domain/entities/user_book_entity.dart';
import '../../../user_books/presentation/providers/user_books_provider.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../data/datasources/habit_pending_logs_local_datasource.dart';
import '../../data/datasources/habit_remote_datasource.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../domain/entities/habit_reading_book_choice.dart';
import '../../domain/entities/reading_log_entity.dart';
import '../../domain/entities/reading_log_save_outcome.dart';
import '../../domain/entities/reading_stats_entity.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/usecases/habit_usecases.dart';

final _habitRemoteProvider = Provider<HabitRemoteDataSource>(
  (ref) => HabitRemoteDataSource(Supabase.instance.client),
);

final _habitPendingLogsLocalProvider = Provider<HabitPendingLogsLocalDataSource>(
  (ref) => HabitPendingLogsLocalDataSource(),
);

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepositoryImpl(
    ref.watch(_habitRemoteProvider),
    ref.watch(_habitPendingLogsLocalProvider),
    () => ref.watch(authStateProvider).valueOrNull?.id,
    () async => ref.read(isOfflineProvider),
  );
});

final addReadingLogUseCaseProvider = Provider<AddReadingLogUseCase>(
  (ref) => AddReadingLogUseCase(ref.watch(habitRepositoryProvider)),
);

final getLogsByDateRangeUseCaseProvider = Provider<GetLogsByDateRangeUseCase>(
  (ref) => GetLogsByDateRangeUseCase(ref.watch(habitRepositoryProvider)),
);

final getReadingStatsUseCaseProvider = Provider<GetReadingStatsUseCase>(
  (ref) => GetReadingStatsUseCase(ref.watch(habitRepositoryProvider)),
);

final hasReadTodayUseCaseProvider = Provider<HasReadTodayUseCase>(
  (ref) => HasReadTodayUseCase(ref.watch(habitRepositoryProvider)),
);

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final _habitLogWindowProvider = Provider<({DateTime start, DateTime end})>((ref) {
  final now = DateTime.now();
  final end = _dateOnly(now);
  final start = end.subtract(const Duration(days: 400));
  return (start: start, end: end);
});

/// Cached by Riverpod; invalidated after new logs (see [habitLogControllerProvider]).
final readingLogsProvider = FutureProvider<List<ReadingLogEntity>>((ref) async {
  ref.watch(authStateProvider);
  final window = ref.watch(_habitLogWindowProvider);
  return ref.read(getLogsByDateRangeUseCaseProvider).call(
        window.start,
        window.end,
      );
});

final readingStatsProvider = FutureProvider<ReadingStatsEntity>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(getReadingStatsUseCaseProvider).call();
});

final todayReadingProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(hasReadTodayUseCaseProvider).call();
});

Future<List<HabitReadingBookChoice>> _loadHabitReadingBookChoices(
  Ref ref,
) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return const <HabitReadingBookChoice>[];

  final userBooksRepo = ref.watch(userBooksRepositoryProvider);
  final reading = await userBooksRepo.getUserBooksByStatus(ReadingStatus.reading);
  final reReading =
      await userBooksRepo.getUserBooksByStatus(ReadingStatus.reReading);

  final seen = <String>{};
  final userBooks = <UserBookEntity>[];
  for (final ub in [...reading, ...reReading]) {
    if (seen.add(ub.bookId)) userBooks.add(ub);
  }
  if (userBooks.isEmpty) return const <HabitReadingBookChoice>[];

  final bookRepo = ref.watch(bookRepositoryProvider);
  final out = <HabitReadingBookChoice>[];
  for (final ub in userBooks.take(24)) {
    var title = ub.bookTitle?.trim() ?? '';
    String? author = ub.bookAuthor?.trim();
    if (title.isEmpty) {
      try {
        final book = await bookRepo.getBookByWorkId(ub.bookId);
        title = book.title;
        author = book.author;
      } catch (_) {
        title = ub.bookId;
      }
    }
    out.add(
      HabitReadingBookChoice(
        bookId: ub.bookId,
        title: title,
        author: author?.isNotEmpty == true ? author : null,
        progress: ub.progress,
      ),
    );
  }
  return out;
}

final habitReadingBookChoicesProvider =
    FutureProvider<List<HabitReadingBookChoice>>((ref) {
  return _loadHabitReadingBookChoices(ref);
});

const _bookTitleFetchConcurrency = 4;

Future<Map<String, String>> _resolveBookTitles(
  Ref ref,
  Iterable<String> bookIds,
) async {
  final ids = bookIds.where((id) => id.trim().isNotEmpty).toSet();
  if (ids.isEmpty) return const {};

  final userBooksRepo = ref.read(userBooksRepositoryProvider);
  final bookRepo = ref.read(bookRepositoryProvider);
  final titles = <String, String>{};

  await Future.wait(
    ids.map((bookId) async {
      try {
        final userBook = await userBooksRepo.getUserBook(bookId);
        final stored = userBook?.bookTitle?.trim();
        if (stored != null && stored.isNotEmpty) {
          titles[bookId] = stored;
        }
      } catch (_) {
        // Fall back to remote lookup below.
      }
    }),
  );

  final needFetch = ids.where((id) => !titles.containsKey(id)).toList();
  for (var i = 0; i < needFetch.length; i += _bookTitleFetchConcurrency) {
    final end = (i + _bookTitleFetchConcurrency > needFetch.length)
        ? needFetch.length
        : i + _bookTitleFetchConcurrency;
    final chunk = needFetch.sublist(i, end);
    await Future.wait(
      chunk.map((bookId) async {
        try {
          titles[bookId] = (await bookRepo.getBookByWorkId(bookId)).title;
        } catch (_) {
          // Leave unresolved; UI omits subtitle rather than showing raw id.
        }
      }),
    );
  }

  return titles;
}

final readingLogBookTitlesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  ref.watch(authStateProvider);
  final logs = await ref.watch(readingLogsProvider.future);
  final bookIds = logs.map((log) => log.bookId).whereType<String>();
  return _resolveBookTitles(ref, bookIds);
});

final habitBookChoicesProvider =
    FutureProvider<List<({String id, String label})>>((ref) async {
  ref.watch(authStateProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.id;
  if (userId == null) return const <({String id, String label})>[];

  final userBooksRepo = ref.watch(userBooksRepositoryProvider);
  final reading = await userBooksRepo.getUserBooksByStatus(ReadingStatus.reading);
  final reReading =
      await userBooksRepo.getUserBooksByStatus(ReadingStatus.reReading);
  final seen = <String>{};
  final ids = <String>[];
  for (final ub in [...reading, ...reReading]) {
    if (seen.add(ub.bookId)) ids.add(ub.bookId);
  }
  if (ids.isEmpty) return const <({String id, String label})>[];

  final bookRepo = ref.watch(bookRepositoryProvider);
  final out = <({String id, String label})>[];
  for (final id in ids.take(24)) {
    try {
      final book = await bookRepo.getBookByWorkId(id);
      out.add((id: id, label: book.title));
    } catch (_) {
      out.add((id: id, label: id));
    }
  }
  return out;
});

final habitLogControllerProvider = Provider<HabitLogController>((ref) {
  return HabitLogController(ref);
});

class AddLogResult {
  const AddLogResult({required this.savedOffline});

  final bool savedOffline;
}

class HabitLogController {
  HabitLogController(this._ref);

  final Ref _ref;

  void _invalidateHabitData() {
    _ref.invalidate(readingStatsProvider);
    _ref.invalidate(readingLogsProvider);
    _ref.invalidate(todayReadingProvider);
  }

  Future<AddLogResult> addLog({
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  }) async {
    final outcome = await _ref.read(addReadingLogUseCaseProvider).call(
          bookId: bookId,
          minutesRead: minutesRead,
          pagesRead: pagesRead,
        );
    _invalidateHabitData();
    return AddLogResult(
      savedOffline: outcome == ReadingLogSaveOutcome.savedOffline,
    );
  }

  Future<AddLogResult> addLogs(
    List<({String? bookId, int minutesRead, int pagesRead})> entries,
  ) async {
    var savedOffline = false;
    for (final entry in entries) {
      final outcome = await _ref.read(addReadingLogUseCaseProvider).call(
            bookId: entry.bookId,
            minutesRead: entry.minutesRead,
            pagesRead: entry.pagesRead,
          );
      if (outcome == ReadingLogSaveOutcome.savedOffline) {
        savedOffline = true;
      }
    }
    _invalidateHabitData();
    return AddLogResult(savedOffline: savedOffline);
  }

  Future<int> syncPendingLogs() {
    return _ref.read(habitRepositoryProvider).syncPendingLogs();
  }
}
