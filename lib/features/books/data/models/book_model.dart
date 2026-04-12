import '../../domain/entities/book.dart';

/// Normalized Google Books volume (data layer only).
class BookModel {
  const BookModel({
    required this.workId,
    required this.title,
    required this.primaryAuthorName,
    required this.authorKeys,
    this.languages,
    this.coverImageUrl,
    required this.description,
    required this.subjects,
  });

  final String workId;
  final String title;
  final String primaryAuthorName;
  final List<String> authorKeys;
  final List<String>? languages;

  /// HTTPS thumbnail URL from Google Books `imageLinks`.
  final String? coverImageUrl;

  final String description;
  final List<String> subjects;

  Book toEntity() {
    return Book(
      id: workId,
      title: title,
      author: primaryAuthorName,
      coverImageUrl: coverImageUrl,
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
    List<String>? languages,
    String? coverImageUrl,
    String? description,
    List<String>? subjects,
  }) {
    return BookModel(
      workId: workId ?? this.workId,
      title: title ?? this.title,
      primaryAuthorName: primaryAuthorName ?? this.primaryAuthorName,
      authorKeys: authorKeys ?? this.authorKeys,
      languages: languages ?? this.languages,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
    );
  }

  static String? _httpsThumbnail(Map<String, dynamic>? imageLinks) {
    if (imageLinks == null) return null;
    final u =
        imageLinks['thumbnail'] as String? ??
        imageLinks['smallThumbnail'] as String?;
    if (u == null || u.isEmpty) return null;
    return u.replaceFirst(RegExp(r'^http:'), 'https:');
  }

  static List<String> _authorKeysFromVolume(Map<String, dynamic> volumeInfo) {
    final names = volumeInfo['authors'];
    if (names is! List || names.isEmpty) return const <String>[];
    final out = <String>[];
    for (final e in names) {
      if (e is! String) continue;
      final t = e.trim();
      if (t.isEmpty) continue;
      out.add('g:${Uri.encodeComponent(t)}');
    }
    return out;
  }

  static List<String>? _languagesFromVolume(Map<String, dynamic> volumeInfo) {
    final lang = volumeInfo['language'];
    if (lang is! String) return null;
    final code = lang.trim().toLowerCase();
    if (code.isEmpty) return null;
    return <String>[code];
  }

  static List<String> _subjectsFromVolume(Map<String, dynamic> volumeInfo) {
    final raw = volumeInfo['categories'];
    if (raw is! List) return const <String>[];
    return raw
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(12)
        .toList();
  }

  static String _primaryAuthor(Map<String, dynamic> volumeInfo) {
    final names = volumeInfo['authors'];
    if (names is List && names.isNotEmpty) {
      final first = names.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
    }
    return 'Unknown author';
  }

  factory BookModel.fromEntity(Book book) {
    return BookModel(
      workId: book.id,
      title: book.title,
      primaryAuthorName: book.author,
      authorKeys: book.authorIds,
      languages: null,
      coverImageUrl: book.coverImageUrl,
      description: book.description,
      subjects: book.subjectKeys,
    );
  }

  factory BookModel.fromGoogleBooksVolume(
    Map<String, dynamic> json, {
    BookModel? mergeFrom,
  }) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final volumeInfo =
        json['volumeInfo'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final titleRaw = (volumeInfo['title'] as String?)?.trim();
    final title = titleRaw != null && titleRaw.isNotEmpty
        ? titleRaw
        : (mergeFrom?.title ?? 'Unknown title');
    final description = (volumeInfo['description'] as String?)?.trim() ?? '';
    final authorKeys = _authorKeysFromVolume(volumeInfo);
    final primary = authorKeys.isNotEmpty
        ? Uri.decodeComponent(authorKeys.first.substring(2))
        : _primaryAuthor(volumeInfo);
    final subjects = _subjectsFromVolume(volumeInfo);
    final languages = _languagesFromVolume(volumeInfo);
    final thumb = _httpsThumbnail(
      volumeInfo['imageLinks'] as Map<String, dynamic>?,
    );

    return BookModel(
      workId: id.isNotEmpty ? id : (mergeFrom?.workId ?? 'unknown'),
      title: title,
      primaryAuthorName:
          primary != 'Unknown author'
              ? primary
              : (mergeFrom?.primaryAuthorName ?? 'Unknown author'),
      authorKeys: authorKeys.isNotEmpty
          ? authorKeys
          : (mergeFrom?.authorKeys ?? const []),
      languages: languages ?? mergeFrom?.languages,
      coverImageUrl: thumb ?? mergeFrom?.coverImageUrl,
      description: description.isNotEmpty
          ? description
          : (mergeFrom?.description ?? ''),
      subjects: subjects.isNotEmpty
          ? subjects
          : (mergeFrom?.subjects ?? const []),
    );
  }
}
