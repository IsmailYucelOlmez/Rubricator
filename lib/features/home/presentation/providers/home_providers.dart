import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../books/data/services/api_service.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../data/datasources/home_cache_datasource.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_book_entity.dart';
import '../../domain/entities/home_genre_section.dart';
import '../../domain/repositories/home_repository.dart';

final _homeApiProvider = Provider<ApiService>((ref) => ApiService());

final _homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>(
  (ref) => HomeRemoteDataSource(
    ref.watch(_homeApiProvider),
    lang: ref.watch(localeProvider).languageCode,
  ),
);

final _homeCacheDataSourceProvider = Provider<HomeCacheDataSource>(
  (ref) => HomeCacheDataSource(SupabaseService.client),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(
    ref.watch(_homeRemoteDataSourceProvider),
    ref.watch(_homeCacheDataSourceProvider),
    ref.watch(bookRepositoryProvider),
  ),
);

final popularBooksProvider = StreamProvider<List<HomeBookEntity>>((ref) {
  return ref.watch(homeRepositoryProvider).streamPopularBooks();
});

/// Google Books `subject:` keys for home genre rows (underscore → space in API).
const kHomePageGenreKeys = <String>[
  'fantasy',
  'science_fiction',
  'romance',
  'mystery',
  'thriller',
  'horror',
];

final homeGenreSectionProvider =
    StreamProvider.family<HomeGenreSection, String>((ref, genreKey) {
      return ref
          .watch(homeRepositoryProvider)
          .streamHomeGenreSection(genreKey);
    });

final genreBooksProvider = FutureProvider.family<List<HomeBookEntity>, String>((
  ref,
  genreKey,
) {
  return ref.watch(homeRepositoryProvider).getBooksByGenre(genreKey);
});
