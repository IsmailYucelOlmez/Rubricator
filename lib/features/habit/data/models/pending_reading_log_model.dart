import 'dart:convert';

import '../../domain/entities/reading_log_entity.dart';

class PendingReadingLogModel {
  PendingReadingLogModel({
    required this.localId,
    required this.userId,
    required this.bookId,
    required this.minutesRead,
    required this.pagesRead,
    required this.date,
    required this.createdAt,
  });

  final String localId;
  final String userId;
  final String? bookId;
  final int minutesRead;
  final int pagesRead;
  final DateTime date;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'local_id': localId,
      'user_id': userId,
      'book_id': bookId,
      'minutes_read': minutesRead,
      'pages_read': pagesRead,
      'date': _formatIsoDate(date),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PendingReadingLogModel.fromJson(Map<String, dynamic> json) {
    return PendingReadingLogModel(
      localId: (json['local_id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      bookId: json['book_id'] as String?,
      minutesRead: (json['minutes_read'] as num?)?.toInt() ?? 0,
      pagesRead: (json['pages_read'] as num?)?.toInt() ?? 0,
      date: _parseDate(json['date']),
      createdAt: _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ReadingLogEntity toEntity() {
    return ReadingLogEntity(
      id: 'local:$localId',
      userId: userId,
      bookId: bookId,
      minutesRead: minutesRead,
      pagesRead: pagesRead,
      date: date,
      createdAt: createdAt,
    );
  }

  static String encodeList(List<PendingReadingLogModel> logs) {
    return jsonEncode(logs.map((l) => l.toJson()).toList());
  }

  static List<PendingReadingLogModel> decodeList(String raw) {
    if (raw.trim().isEmpty) return <PendingReadingLogModel>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <PendingReadingLogModel>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PendingReadingLogModel.fromJson)
        .where((l) => l.localId.isNotEmpty && l.userId.isNotEmpty)
        .toList();
  }

  static String _formatIsoDate(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _parseDate(Object? value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    final s = value.toString();
    final parts = s.split('T').first.split('-');
    if (parts.length >= 3) {
      final y = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return DateTime(y, m, d);
    }
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
