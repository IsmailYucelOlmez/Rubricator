import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api_service.dart';
import '../../../../services/supabase_service.dart';
import '../../data/datasources/home_cache_datasource.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_book_entity.dart';
import '../../domain/repositories/home_repository.dart';

final _homeApiProvider = Provider<ApiService>((ref) => ApiService());

final _homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>(
  (ref) => HomeRemoteDataSource(ref.watch(_homeApiProvider)),
);

final _homeCacheDataSourceProvider = Provider<HomeCacheDataSource>(
  (ref) => HomeCacheDataSource(SupabaseService.client),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(
    ref.watch(_homeRemoteDataSourceProvider),
    ref.watch(_homeCacheDataSourceProvider),
  ),
);

final popularBooksProvider = FutureProvider<List<HomeBookEntity>>((ref) {
  return ref.watch(homeRepositoryProvider).getPopularBooks();
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

final homeGenreSectionsProvider =
    FutureProvider<Map<String, List<HomeBookEntity>>>((ref) {
      return ref
          .watch(homeRepositoryProvider)
          .getHomeGenreSectionBooks(kHomePageGenreKeys);
    });

final genreBooksProvider = FutureProvider.family<List<HomeBookEntity>, String>((
  ref,
  genreKey,
) {
  return ref.watch(homeRepositoryProvider).getBooksByGenre(genreKey);
});
