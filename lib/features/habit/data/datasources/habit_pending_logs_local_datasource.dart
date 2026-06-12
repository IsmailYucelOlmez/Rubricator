import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_reading_log_model.dart';

class HabitPendingLogsLocalDataSource {
  HabitPendingLogsLocalDataSource();

  static const String _storageKey = 'pending_reading_logs_v1';
  static final Random _random = Random();

  String _newLocalId() {
    final n = DateTime.now().microsecondsSinceEpoch;
    return 'pending_${n}_${_random.nextInt(1 << 32)}';
  }

  Future<List<PendingReadingLogModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const <PendingReadingLogModel>[];
    return PendingReadingLogModel.decodeList(raw);
  }

  Future<List<PendingReadingLogModel>> getForUser(String userId) async {
    final all = await getAll();
    return all.where((l) => l.userId == userId).toList();
  }

  Future<void> enqueue({
    required String userId,
    String? bookId,
    required int minutesRead,
    required int pagesRead,
    DateTime? date,
  }) async {
    final now = DateTime.now();
    final logDate = date ?? DateTime(now.year, now.month, now.day);
    final entry = PendingReadingLogModel(
      localId: _newLocalId(),
      userId: userId,
      bookId: bookId?.trim().isEmpty == true ? null : bookId?.trim(),
      minutesRead: minutesRead,
      pagesRead: pagesRead,
      date: DateTime(logDate.year, logDate.month, logDate.day),
      createdAt: now,
    );
    final all = await getAll();
    all.add(entry);
    await _save(all);
  }

  Future<void> remove(String localId) async {
    final all = await getAll();
    all.removeWhere((l) => l.localId == localId);
    await _save(all);
  }

  Future<void> _save(List<PendingReadingLogModel> logs) async {
    final prefs = await SharedPreferences.getInstance();
    if (logs.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(
      _storageKey,
      PendingReadingLogModel.encodeList(logs),
    );
  }
}
