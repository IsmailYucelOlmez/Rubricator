import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/api_service.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_book_entity.dart';
import '../../domain/repositories/home_repository.dart';

final _homeApiProvider = Provider<ApiService>((ref) => ApiService());

final _homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>(
  (ref) => HomeRemoteDataSource(ref.watch(_homeApiProvider)),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(_homeRemoteDataSourceProvider)),
);

final popularBooksProvider = FutureProvider<List<HomeBookEntity>>((ref) {
  return ref.watch(homeRepositoryProvider).getPopularBooks();
});

final genreBooksProvider = FutureProvider.family<List<HomeBookEntity>, String>((
  ref,
  genre,
) {
  return ref.watch(homeRepositoryProvider).getBooksByGenre(genre);
});

final searchProvider = FutureProvider.family<List<HomeBookEntity>, String>((
  ref,
  query,
) {
  return ref.watch(homeRepositoryProvider).searchBooks(query);
});
