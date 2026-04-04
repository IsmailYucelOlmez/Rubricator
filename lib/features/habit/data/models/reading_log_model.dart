import '../../domain/entities/reading_log_entity.dart';

class ReadingLogModel {
  ReadingLogModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.minutesRead,
    required this.pagesRead,
    required this.date,
    required this.createdAt,
  });

  factory ReadingLogModel.fromRow(Map<String, dynamic> row) {
    return ReadingLogModel(
      id: (row['id'] as String?) ?? '',
      userId: (row['user_id'] as String?) ?? '',
      bookId: row['book_id'] as String?,
      minutesRead: (row['minutes_read'] as num?)?.toInt() ?? 0,
      pagesRead: (row['pages_read'] as num?)?.toInt() ?? 0,
      date: _parseDate(row['date']),
      createdAt: _parseDateTime(row['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String userId;
  final String? bookId;
  final int minutesRead;
  final int pagesRead;
  final DateTime date;
  final DateTime createdAt;

  ReadingLogEntity toEntity() {
    return ReadingLogEntity(
      id: id,
      userId: userId,
      bookId: bookId,
      minutesRead: minutesRead,
      pagesRead: pagesRead,
      date: date,
      createdAt: createdAt,
    );
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
