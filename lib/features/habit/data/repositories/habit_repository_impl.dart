import '../../../../core/network/network_errors.dart';
import '../../domain/entities/reading_log_entity.dart';
import '../../domain/entities/reading_log_save_outcome.dart';
import '../../domain/entities/reading_stats_entity.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/services/reading_streak_calculator.dart';
import '../datasources/habit_pending_logs_local_datasource.dart';
import '../datasources/habit_remote_datasource.dart';
import '../models/pending_reading_log_model.dart';
import '../models/reading_log_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl(
    this._remote,
    this._local,
    this._currentUserId,
    this._isOffline,
  );

  final HabitRemoteDataSource _remote;
  final HabitPendingLogsLocalDataSource _local;
  final String? Function() _currentUserId;
  final Future<bool> Function() _isOffline;

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

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _inDateRange(DateTime date, DateTime start, DateTime end) {
    final d = _dateOnly(date);
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  Future<void> _queueLocally({
    required String userId,
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  }) {
    return _local.enqueue(
      userId: userId,
      bookId: bookId,
      minutesRead: minutesRead,
      pagesRead: pagesRead,
    );
  }

  @override
  Future<ReadingLogSaveOutcome> addReadingLog({
    String? bookId,
    required int minutesRead,
    required int pagesRead,
  }) async {
    final uid = _requireUserId();
    if (await _isOffline()) {
      await _queueLocally(
        userId: uid,
        bookId: bookId,
        minutesRead: minutesRead,
        pagesRead: pagesRead,
      );
      return ReadingLogSaveOutcome.savedOffline;
    }

    try {
      await _remote.insertLog(
        userId: uid,
        bookId: bookId,
        minutesRead: minutesRead,
        pagesRead: pagesRead,
      );
      return ReadingLogSaveOutcome.synced;
    } catch (e) {
      if (isLikelyNetworkError(e)) {
        await _queueLocally(
          userId: uid,
          bookId: bookId,
          minutesRead: minutesRead,
          pagesRead: pagesRead,
        );
        return ReadingLogSaveOutcome.savedOffline;
      }
      rethrow;
    }
  }

  @override
  Future<int> syncPendingLogs() async {
    if (await _isOffline()) return 0;
    final uid = _userId();
    if (uid == null) return 0;

    final pending = await _local.getForUser(uid);
    if (pending.isEmpty) return 0;

    var synced = 0;
    for (final log in pending) {
      try {
        await _remote.insertLog(
          userId: log.userId,
          bookId: log.bookId,
          minutesRead: log.minutesRead,
          pagesRead: log.pagesRead,
          date: log.date,
        );
        await _local.remove(log.localId);
        synced++;
      } catch (e) {
        if (isLikelyNetworkError(e)) break;
      }
    }
    return synced;
  }

  Future<List<ReadingLogEntity>> _pendingLogsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final pending = await _local.getForUser(userId);
    return pending
        .where((p) => _inDateRange(p.date, start, end))
        .map((p) => p.toEntity())
        .toList();
  }

  @override
  Future<List<ReadingLogEntity>> getLogsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final uid = _userId();
    if (uid == null) return const <ReadingLogEntity>[];

    final pending = await _pendingLogsInRange(uid, start, end);
    if (await _isOffline()) {
      pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pending;
    }

    try {
      final rows = await _remote.fetchLogsBetween(
        userId: uid,
        start: start,
        end: end,
      );
      final remote = rows.map((r) => ReadingLogModel.fromRow(r).toEntity()).toList();
      final merged = [...pending, ...remote]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (e) {
      if (isLikelyNetworkError(e)) {
        pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return pending;
      }
      rethrow;
    }
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

    final pending = await _local.getForUser(uid);
    if (await _isOffline() || pending.isNotEmpty) {
      return _statsFromPending(uid, pending);
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

  Future<ReadingStatsEntity> _statsFromPending(
    String userId,
    List<PendingReadingLogModel> pendingLogs,
  ) async {
    var remoteMinutes = 0;
    var remotePages = 0;
    final activeDates = <DateTime>[];

    if (!await _isOffline()) {
      try {
        final map = await _remote.fetchUserSummary();
        if (map != null) {
          remoteMinutes = (map['total_minutes'] as num?)?.toInt() ?? 0;
          remotePages = (map['total_pages'] as num?)?.toInt() ?? 0;
          final rawDates = map['active_dates'];
          if (rawDates is List) {
            for (final e in rawDates) {
              final d = _parseSummaryDate(e);
              if (d != null) activeDates.add(d);
            }
          }
        }
      } catch (e) {
        if (!isLikelyNetworkError(e)) rethrow;
      }
    }

    if (pendingLogs.isEmpty && activeDates.isEmpty) {
      return const ReadingStatsEntity(
        totalMinutes: 0,
        totalPages: 0,
        currentStreak: 0,
        longestStreak: 0,
      );
    }

    var pendingMinutes = 0;
    var pendingPages = 0;
    for (final log in pendingLogs) {
      pendingMinutes += log.minutesRead;
      pendingPages += log.pagesRead;
      activeDates.add(_dateOnly(log.date));
    }

    return ReadingStreakCalculator.fromSummary(
      totalMinutes: remoteMinutes + pendingMinutes,
      totalPages: remotePages + pendingPages,
      activeDates: activeDates,
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

    final today = _dateOnly(DateTime.now());
    final pending = await _local.getForUser(uid);
    if (pending.any((p) => _dateOnly(p.date) == today)) {
      return true;
    }

    if (await _isOffline()) return false;

    try {
      return _remote.fetchHasReadToday(userId: uid);
    } catch (e) {
      if (isLikelyNetworkError(e)) return false;
      rethrow;
    }
  }
}
