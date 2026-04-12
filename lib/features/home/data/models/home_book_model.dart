import '../../domain/entities/home_book_entity.dart';

class HomeBookModel {
  const HomeBookModel({
    required this.id,
    required this.title,
    this.coverImageUrl,
    required this.authorNames,
    this.languages,
    this.categories,
  });

  final String id;
  final String title;
  final String? coverImageUrl;
  final String authorNames;
  final List<String>? languages;
  /// Google `volumeInfo.categories` when present.
  final List<String>? categories;

  HomeBookEntity toEntity() {
    return HomeBookEntity(
      id: id,
      title: title,
      coverImageUrl: coverImageUrl,
      authorNames: authorNames,
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

  static List<String>? _languages(Map<String, dynamic> volumeInfo) {
    final lang = volumeInfo['language'];
    if (lang is! String) return null;
    final code = lang.trim().toLowerCase();
    if (code.isEmpty) return null;
    return <String>[code];
  }

  static String _authorNames(Map<String, dynamic> volumeInfo) {
    final names = volumeInfo['authors'];
    if (names is List && names.isNotEmpty) {
      final first = names.first;
      if (first is String && first.trim().isNotEmpty) return first.trim();
    }
    return 'Unknown author';
  }

  factory HomeBookModel.fromGoogleVolume(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final volumeInfo =
        json['volumeInfo'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final titleRaw = (volumeInfo['title'] as String?)?.trim();
    final categoriesRaw = volumeInfo['categories'];
    List<String>? categories;
    if (categoriesRaw is List<dynamic>) {
      categories = categoriesRaw
          .whereType<String>()
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (categories.isEmpty) categories = null;
    }
    return HomeBookModel(
      id: id.isEmpty ? 'unknown' : id,
      title: titleRaw != null && titleRaw.isNotEmpty ? titleRaw : 'Unknown title',
      coverImageUrl: _httpsThumbnail(
        volumeInfo['imageLinks'] as Map<String, dynamic>?,
      ),
      authorNames: _authorNames(volumeInfo),
      languages: _languages(volumeInfo),
      categories: categories,
    );
  }
}
