import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/home_book_entity.dart';
import '../../domain/entities/home_genre_section.dart';
import '../../domain/entities/home_page_snapshot.dart';

/// Last complete home page per language, so a cold start can paint it
/// immediately while the network refresh runs (stale-while-revalidate).
class HomeLocalDataSource {
  HomeLocalDataSource({required this.lang});

  final String lang;

  /// Bump when the stored shape changes; older payloads are ignored.
  static const int _version = 1;

  String get _key => 'home_snapshot_v${_version}_$lang';

  Future<HomePageSnapshot?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final popular = (json['popular'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(_bookFromJson)
          .toList();
      final sectionsRaw =
          json['sections'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final sections = <String, HomeGenreSection>{};
      for (final entry in sectionsRaw.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        sections[entry.key] = HomeGenreSection(
          books: (value['books'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(_bookFromJson)
              .toList(),
          loadState: HomeGenreSectionLoadState.values.firstWhere(
            (s) => s.name == value['state'],
            orElse: () => HomeGenreSectionLoadState.ready,
          ),
        );
      }
      return HomePageSnapshot(popularBooks: popular, genreSections: sections);
    } catch (_) {
      // Corrupt/incompatible payload: behave as if nothing was saved.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> write(HomePageSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'popular': (snapshot.popularBooks ?? const <HomeBookEntity>[])
          .map(_bookToJson)
          .toList(),
      'sections': <String, dynamic>{
        for (final entry in snapshot.genreSections.entries)
          entry.key: <String, dynamic>{
            'state': entry.value.loadState.name,
            'books': entry.value.books.map(_bookToJson).toList(),
          },
      },
    };
    await prefs.setString(_key, jsonEncode(payload));
  }

  static Map<String, dynamic> _bookToJson(HomeBookEntity book) {
    return <String, dynamic>{
      'id': book.id,
      'title': book.title,
      'cover': book.coverImageUrl,
      'authors': book.authorNames,
      'description': book.description,
      'source_url': book.sourceUrl,
    };
  }

  static HomeBookEntity _bookFromJson(Map<String, dynamic> json) {
    return HomeBookEntity(
      id: json['id'] as String? ?? 'unknown',
      title: json['title'] as String? ?? '',
      coverImageUrl: json['cover'] as String?,
      authorNames: json['authors'] as String? ?? '',
      description: json['description'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }
}
