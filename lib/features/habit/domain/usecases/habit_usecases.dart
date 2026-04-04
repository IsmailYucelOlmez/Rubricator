import '../entities/reading_log_entity.dart';
import '../entities/reading_stats_entity.dart';
import '../repositories/habit_repository.dart';

class HabitValidationException implements Exception {
  HabitValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AddReadingLogUseCase {
  const AddReadingLogUseCase(this._repository);
  final HabitRepository _repository;

  Future<void> call({
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  }) {
    if (minutesRead < 0 || pagesRead < 0) {
      throw HabitValidationException('Values cannot be negative.');
    }
    if (minutesRead == 0 && pagesRead == 0) {
      throw HabitValidationException('Enter minutes and/or pages read.');
    }
    return _repository.addReadingLog(
      bookId: bookId,
      minutesRead: minutesRead,
      pagesRead: pagesRead,
    );
  }
}

class GetLogsByDateRangeUseCase {
  const GetLogsByDateRangeUseCase(this._repository);
  final HabitRepository _repository;

  Future<List<ReadingLogEntity>> call(DateTime start, DateTime end) {
    return _repository.getLogsByDateRange(start, end);
  }
}

class GetReadingStatsUseCase {
  const GetReadingStatsUseCase(this._repository);
  final HabitRepository _repository;

  Future<ReadingStatsEntity> call() => _repository.getReadingStats();
}

class HasReadTodayUseCase {
  const HasReadTodayUseCase(this._repository);
  final HabitRepository _repository;

  Future<bool> call() => _repository.hasReadToday();
}
