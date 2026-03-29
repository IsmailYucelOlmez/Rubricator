import '../../domain/entities/book.dart';

/// Normalized Open Library work / search hit (data layer only).
class BookModel {
  const BookModel({
    required this.workId,
    required this.title,
    required this.primaryAuthorName,
    required this.authorKeys,
    required this.coverId,
    required this.description,
    required this.subjects,
  });

  final String workId;
  final String title;
  final String primaryAuthorName;
  final List<String> authorKeys;
  final int? coverId;
  final String description;
  final List<String> subjects;

  Book toEntity() {
    return Book(
      id: workId,
      title: title,
      author: primaryAuthorName,
      coverId: coverId,
      description: description,
      authorIds: authorKeys,
      subjectKeys: subjects,
    );
  }

  BookModel copyWith({
    String? workId,
    String? title,
    String? primaryAuthorName,
    List<String>? authorKeys,
    int? coverId,
    String? description,
    List<String>? subjects,
  }) {
    return BookModel(
      workId: workId ?? this.workId,
      title: title ?? this.title,
      primaryAuthorName: primaryAuthorName ?? this.primaryAuthorName,
      authorKeys: authorKeys ?? this.authorKeys,
      coverId: coverId ?? this.coverId,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
    );
  }

  static String _normalizeDescription(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final v = raw['value'];
      if (v is String) return v;
    }
    return '';
  }

  static List<String> _authorKeysFromSearch(Map<String, dynamic> json) {
    final keys = <String>[];
    final raw = json['author_key'];
    if (raw is List) {
      for (final e in raw) {
        if (e is String) keys.add(_stripAuthorPrefix(e));
      }
    } else if (raw is String) {
      keys.add(_stripAuthorPrefix(raw));
    }
    return keys;
  }

  static String _stripAuthorPrefix(String key) {
    return key.replaceFirst(RegExp(r'^/authors/'), '');
  }

  static List<String> _authorKeysFromWork(Map<String, dynamic> json) {
    final keys = <String>[];
    final authors = json['authors'];
    if (authors is! List) return keys;
    for (final entry in authors) {
      if (entry is! Map<String, dynamic>) continue;
      final author = entry['author'];
      if (author is Map<String, dynamic>) {
        final k = author['key'] as String?;
        if (k != null) keys.add(_stripAuthorPrefix(k));
      }
    }
    return keys;
  }

  static List<String> _subjectsFromWork(Map<String, dynamic> json) {
    final raw = json['subjects'];
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(12)
        .toList();
  }

  static int? _firstCoverId(Map<String, dynamic> json) {
    final covers = json['covers'];
    if (covers is List && covers.isNotEmpty) {
      final first = covers.first;
      if (first is int) return first;
    }
    return null;
  }

  factory BookModel.fromEntity(Book book) {
    return BookModel(
      workId: book.id,
      title: book.title,
      primaryAuthorName: book.author,
      authorKeys: book.authorIds,
      coverId: book.coverId,
      description: book.description,
      subjects: book.subjectKeys,
    );
  }

  factory BookModel.fromSearchDoc(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    final workId = key.replaceFirst(RegExp(r'^/works/'), '');
    final names = json['author_name'];
    String author = 'Unknown author';
    if (names is List && names.isNotEmpty) {
      author = names.first.toString();
    } else if (names is String && names.isNotEmpty) {
      author = names;
    }
    final cover = json['cover_i'];
    return BookModel(
      workId: workId.isEmpty ? 'unknown' : workId,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Unknown title',
      primaryAuthorName: author,
      authorKeys: _authorKeysFromSearch(json),
      coverId: cover is int ? cover : null,
      description: '',
      subjects: const [],
    );
  }

  factory BookModel.fromTrendingWork(Map<String, dynamic> work) {
    final key = work['key'] as String? ?? '';
    final workId = key.replaceFirst(RegExp(r'^/works/'), '');
    String author = 'Unknown author';
    final authors = work['authors'] as List<dynamic>?;
    if (authors != null && authors.isNotEmpty) {
      final first = authors.first;
      if (first is Map<String, dynamic>) {
        author = first['name'] as String? ?? author;
      }
    }
    final cover = work['cover_id'];
    return BookModel(
      workId: workId.isEmpty ? 'unknown' : workId,
      title: (work['title'] as String?)?.trim().isNotEmpty == true
          ? work['title'] as String
          : 'Unknown title',
      primaryAuthorName: author,
      authorKeys: const [],
      coverId: cover is int ? cover : null,
      description: '',
      subjects: const [],
    );
  }

  factory BookModel.fromWorkJson(
    Map<String, dynamic> json, {
    BookModel? mergeFrom,
  }) {
    final key = json['key'] as String? ?? '';
    final workId = key.replaceFirst(RegExp(r'^/works/'), '');
    final title = (json['title'] as String?)?.trim();
    final description = _normalizeDescription(json['description']);
    final authorKeys = _authorKeysFromWork(json);
    final primary = mergeFrom?.primaryAuthorName ?? 'Unknown author';
    final coverFromWork = _firstCoverId(json);
    final subjects = _subjectsFromWork(json);

    return BookModel(
      workId: workId.isNotEmpty ? workId : (mergeFrom?.workId ?? 'unknown'),
      title: title != null && title.isNotEmpty
          ? title
          : (mergeFrom?.title ?? 'Unknown title'),
      primaryAuthorName: primary,
      authorKeys: authorKeys.isNotEmpty
          ? authorKeys
          : (mergeFrom?.authorKeys ?? const []),
      coverId: coverFromWork ?? mergeFrom?.coverId,
      description: description.isNotEmpty
          ? description
          : (mergeFrom?.description ?? ''),
      subjects: subjects.isNotEmpty
          ? subjects
          : (mergeFrom?.subjects ?? const []),
    );
  }
}
