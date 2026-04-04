import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../../user_books/domain/entities/user_book_entity.dart';
import '../../../user_books/presentation/providers/user_books_provider.dart';
import '../../data/datasources/habit_remote_datasource.dart';
import '../../data/repositories/habit_repository_impl.dart';
import '../../domain/entities/reading_log_entity.dart';
import '../../domain/entities/reading_stats_entity.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/usecases/habit_usecases.dart';

final _habitRemoteProvider = Provider<HabitRemoteDataSource>(
  (ref) => HabitRemoteDataSource(Supabase.instance.client),
);

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepositoryImpl(
    ref.watch(_habitRemoteProvider),
    () => ref.watch(authStateProvider).valueOrNull?.id,
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

class HabitLogController {
  HabitLogController(this._ref);

  final Ref _ref;

  Future<void> addLog({
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  }) async {
    await _ref.read(addReadingLogUseCaseProvider).call(
          bookId: bookId,
          minutesRead: minutesRead,
          pagesRead: pagesRead,
        );
    _ref.invalidate(readingStatsProvider);
    _ref.invalidate(readingLogsProvider);
    _ref.invalidate(todayReadingProvider);
  }
}
