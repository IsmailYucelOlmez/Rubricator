import '../entities/reading_log_entity.dart';
import '../entities/reading_log_save_outcome.dart';
import '../entities/reading_stats_entity.dart';

abstract class HabitRepository {
  Future<ReadingLogSaveOutcome> addReadingLog({
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  });

  Future<List<ReadingLogEntity>> getLogsByDateRange(
    DateTime start,
    DateTime end,
  );

  Future<ReadingStatsEntity> getReadingStats();

  Future<bool> hasReadToday();

  Future<int> syncPendingLogs();
}
