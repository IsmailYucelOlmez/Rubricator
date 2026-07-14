import '../../domain/entities/document_session.dart';

DocumentSessionStatus parseDocumentSessionStatus(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'ready':
      return DocumentSessionStatus.ready;
    case 'failed':
      return DocumentSessionStatus.failed;
    case 'processing':
    default:
      return DocumentSessionStatus.processing;
  }
}

DateTime? parseApiDateTime(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

int? parseOptionalInt(Object? raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}

int parseInt(Object? raw, [int fallback = 0]) =>
    parseOptionalInt(raw) ?? fallback;

bool parseBool(Object? raw, [bool fallback = false]) {
  if (raw is bool) return raw;
  if (raw is String) {
    final lower = raw.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  return fallback;
}
