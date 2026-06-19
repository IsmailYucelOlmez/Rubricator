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
    this.isbn13,
    this.publishedYear,
    this.pageCount,
    this.averageRating,
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
  final String? isbn13;
  final String? publishedYear;
  final int? pageCount;
  final double? averageRating;

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
    String? isbn13,
    String? publishedYear,
    int? pageCount,
    double? averageRating,
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
      isbn13: isbn13 ?? this.isbn13,
      publishedYear: publishedYear ?? this.publishedYear,
      pageCount: pageCount ?? this.pageCount,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return <String, dynamic>{
      'work_id': workId,
      'title': title,
      'primary_author_name': primaryAuthorName,
      'author_keys': authorKeys,
      'languages': languages,
      'cover_image_url': coverImageUrl,
      'description': description,
      'subjects': subjects,
      'isbn13': isbn13,
      'published_year': publishedYear,
      'page_count': pageCount,
      'average_rating': averageRating,
    };
  }

  factory BookModel.fromCacheJson(Map<String, dynamic> json) {
    final authorKeysRaw = json['author_keys'];
    final languagesRaw = json['languages'];
    final subjectsRaw = json['subjects'];
    return BookModel(
      workId: (json['work_id'] as String?)?.trim().isNotEmpty == true
          ? (json['work_id'] as String).trim()
          : 'unknown',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Unknown title',
      primaryAuthorName:
          (json['primary_author_name'] as String?)?.trim().isNotEmpty == true
          ? (json['primary_author_name'] as String).trim()
          : 'Unknown author',
      authorKeys: authorKeysRaw is List
          ? authorKeysRaw.whereType<String>().toList()
          : const <String>[],
      languages: languagesRaw is List
          ? languagesRaw.whereType<String>().toList()
          : null,
      coverImageUrl: (json['cover_image_url'] as String?)?.trim(),
      description: (json['description'] as String?) ?? '',
      subjects: subjectsRaw is List
          ? subjectsRaw.whereType<String>().toList()
          : const <String>[],
      isbn13: (json['isbn13'] as String?)?.trim(),
      publishedYear: (json['published_year'] as String?)?.trim(),
      pageCount: (json['page_count'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
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

  static String? _isbn13FromVolume(Map<String, dynamic> volumeInfo) {
    final identifiers = volumeInfo['industryIdentifiers'];
    if (identifiers is! List) return null;
    for (final raw in identifiers) {
      if (raw is! Map<String, dynamic>) continue;
      if (raw['type'] == 'ISBN_13') {
        final id = (raw['identifier'] as String?)?.trim();
        if (id != null && id.isNotEmpty) return id;
      }
    }
    return null;
  }

  static String? _publishedYearFromVolume(Map<String, dynamic> volumeInfo) {
    final rawDate = volumeInfo['publishedDate'];
    if (rawDate is! String || rawDate.length < 4) return null;
    return rawDate.substring(0, 4);
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
    final isbn13 = _isbn13FromVolume(volumeInfo);
    final publishedYear = _publishedYearFromVolume(volumeInfo);
    final pageCount = (volumeInfo['pageCount'] as num?)?.toInt();
    final averageRating = (volumeInfo['averageRating'] as num?)?.toDouble();

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
      isbn13: isbn13 ?? mergeFrom?.isbn13,
      publishedYear: publishedYear ?? mergeFrom?.publishedYear,
      pageCount: pageCount ?? mergeFrom?.pageCount,
      averageRating: averageRating ?? mergeFrom?.averageRating,
    );
  }
}
