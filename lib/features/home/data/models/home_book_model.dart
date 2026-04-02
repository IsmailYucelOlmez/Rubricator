import '../../domain/entities/home_book_entity.dart';

class HomeBookModel {
  const HomeBookModel({
    required this.id,
    required this.title,
    required this.coverId,
    required this.authorNames,
    this.languages,
  });

  final String id;
  final String title;
  final int? coverId;
  final String authorNames;
  final List<String>? languages;

  HomeBookEntity toEntity() {
    return HomeBookEntity(
      id: id,
      title: title,
      coverId: coverId,
      authorNames: authorNames,
    );
  }

  factory HomeBookModel.fromSubjectWork(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    final id = key.replaceFirst(RegExp(r'^/works/'), '');
    final title = (json['title'] as String?)?.trim();
    final authors = json['authors'] as List<dynamic>?;
    var author = 'Unknown author';
    if (authors != null && authors.isNotEmpty) {
      final first = authors.first;
      if (first is Map<String, dynamic>) {
        author = (first['name'] as String?)?.trim().isNotEmpty == true
            ? first['name'] as String
            : author;
      }
    }
    final languages =
        _parseLanguages(json['language'] ?? json['languages']);
    return HomeBookModel(
      id: id.isEmpty ? 'unknown' : id,
      title: title != null && title.isNotEmpty ? title : 'Unknown title',
      coverId: json['cover_id'] as int?,
      authorNames: author,
      languages: languages,
    );
  }

  factory HomeBookModel.fromSearchDoc(Map<String, dynamic> json) {
    final key = json['key'] as String? ?? '';
    final id = key.replaceFirst(RegExp(r'^/works/'), '');
    final title = (json['title'] as String?)?.trim();
    final names = json['author_name'] as List<dynamic>?;
    final author = (names != null && names.isNotEmpty)
        ? names.first.toString()
        : 'Unknown author';
    final languages =
        _parseLanguages(json['language'] ?? json['languages']);
    return HomeBookModel(
      id: id.isEmpty ? 'unknown' : id,
      title: title != null && title.isNotEmpty ? title : 'Unknown title',
      coverId: json['cover_i'] as int?,
      authorNames: author,
      languages: languages,
    );
  }

  static List<String>? _parseLanguages(dynamic raw) {
    if (raw == null) return null;
    final out = <String>[];

    void addCode(dynamic v) {
      String? code;
      if (v is String) {
        code = v;
      } else if (v is Map<String, dynamic>) {
        final k = v['key'];
        if (k is String) code = k;
      }
      if (code == null) return;

      final normalized =
          code.replaceFirst(RegExp(r'^/languages/'), '').trim().toLowerCase();
      if (normalized.isNotEmpty) out.add(normalized);
    }

    if (raw is List) {
      for (final e in raw) {
        addCode(e);
      }
    } else {
      addCode(raw);
    }

    final unique = out.toSet().toList();
    return unique.isEmpty ? null : unique;
  }
}
