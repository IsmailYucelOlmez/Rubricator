import '../../domain/entities/reading_log_entity.dart';
import '../../domain/entities/reading_stats_entity.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/services/reading_streak_calculator.dart';
import '../datasources/habit_remote_datasource.dart';
import '../models/reading_log_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl(this._remote, this._currentUserId);

  final HabitRemoteDataSource _remote;
  final String? Function() _currentUserId;

  String? _userId() {
    final id = _currentUserId();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  String _requireUserId() {
    final id = _userId();
    if (id == null) {
      throw StateError('Sign in to log reading.');
    }
    return id;
  }

  @override
  Future<void> addReadingLog({
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  }) {
    return _remote.insertLog(
      userId: _requireUserId(),
      bookId: bookId,
      minutesRead: minutesRead,
      pagesRead: pagesRead,
    );
  }

  @override
  Future<List<ReadingLogEntity>> getLogsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final uid = _userId();
    if (uid == null) return const <ReadingLogEntity>[];
    final rows = await _remote.fetchLogsBetween(
      userId: uid,
      start: start,
      end: end,
    );
    return rows.map((r) => ReadingLogModel.fromRow(r).toEntity()).toList();
  }

  @override
  Future<ReadingStatsEntity> getReadingStats() async {
    final uid = _userId();
    if (uid == null) {
      return const ReadingStatsEntity(
        totalMinutes: 0,
        totalPages: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
    }
    final map = await _remote.fetchUserSummary();
    if (map == null) {
      return const ReadingStatsEntity(
        totalMinutes: 0,
        totalPages: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
    }
    final totalMinutes = (map['total_minutes'] as num?)?.toInt() ?? 0;
    final totalPages = (map['total_pages'] as num?)?.toInt() ?? 0;
    final rawDates = map['active_dates'];
    final dates = <DateTime>[];
    if (rawDates is List) {
      for (final e in rawDates) {
        final d = _parseSummaryDate(e);
        if (d != null) dates.add(d);
      }
    }
    return ReadingStreakCalculator.fromSummary(
      totalMinutes: totalMinutes,
      totalPages: totalPages,
      activeDates: dates,
      today: DateTime.now(),
    );
  }

  static DateTime? _parseSummaryDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    final s = value.toString();
    final head = s.split('T').first;
    final parts = head.split('-');
    if (parts.length >= 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  Future<bool> hasReadToday() async {
    final uid = _userId();
    if (uid == null) return false;
    return _remote.fetchHasReadToday(userId: uid);
  }
}
