import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../books/data/services/api_service.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../../trbooks/presentation/providers/trbooks_providers.dart';
import '../../data/datasources/home_cache_datasource.dart';
import '../../data/datasources/home_local_datasource.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_page_snapshot.dart';
import '../../domain/entities/home_book_entity.dart';
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

final _homeLocalDataSourceProvider = Provider<HomeLocalDataSource>(
  (ref) => HomeLocalDataSource(lang: ref.watch(localeProvider).languageCode),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(
    ref.watch(_homeRemoteDataSourceProvider),
    ref.watch(_homeCacheDataSourceProvider),
    ref.watch(_homeLocalDataSourceProvider),
    ref.watch(bookRepositoryProvider),
    ref.watch(trbooksRepositoryProvider),
    lang: ref.watch(localeProvider).languageCode,
  ),
);

/// Google Books `subject:` keys for home genre rows (underscore → space in API).
const kHomePageGenreKeys = <String>[
  'fantasy',
  'science_fiction',
  'romance',
  'mystery',
  'thriller',
  'horror',
];

/// D&R (the trbooks source) has no separate thriller/horror category — both
/// map to its single "Korku Gerilim" category, so the two sections would
/// show identical books for Turkish users. Drop `horror` there and keep
/// `thriller` as the one combined section.
List<String> homePageGenreKeysFor(String languageCode) {
  if (languageCode == 'tr') {
    return kHomePageGenreKeys.where((key) => key != 'horror').toList();
  }
  return kHomePageGenreKeys;
}

final homePageGenreKeysProvider = Provider<List<String>>(
  (ref) => homePageGenreKeysFor(ref.watch(localeProvider).languageCode),
);

/// Stale-while-revalidate: paints the last home page saved on this device
/// first, then overlays rails from the network as each one arrives. A network
/// failure only surfaces as an error when there was nothing saved to show.
final homePageSnapshotProvider = StreamProvider<HomePageSnapshot>((ref) async* {
  final repository = ref.watch(homeRepositoryProvider);
  final genreKeys = ref.watch(homePageGenreKeysProvider);
  final stopwatch = Stopwatch()..start();

  HomePageSnapshot? saved;
  try {
    saved = await repository.readSavedHomePage();
  } catch (error) {
    AppLogger.warning('home', 'Saved home page unreadable: $error');
  }
  AppLogger.info(
    'home.timing',
    'disk snapshot read: ${stopwatch.elapsedMilliseconds}ms '
        '(${saved == null ? 'miss' : 'hit'})',
  );
  if (saved != null) yield saved;

  var current = saved ?? HomePageSnapshot.empty;
  HomePageSnapshot? latestNetwork;
  var firstNetworkRail = true;
  try {
    await for (final partial in repository.watchHomePage(genreKeys)) {
      if (firstNetworkRail) {
        firstNetworkRail = false;
        AppLogger.info(
          'home.timing',
          'first network rail: ${stopwatch.elapsedMilliseconds}ms',
        );
      }
      latestNetwork = partial;
      current = partial.overlaying(current);
      yield current;
    }
  } catch (error) {
    if (saved == null) rethrow;
    AppLogger.warning(
      'home',
      'Home refresh failed, keeping saved copy: $error',
    );
    return;
  }
  AppLogger.info(
    'home.timing',
    'network complete: ${stopwatch.elapsedMilliseconds}ms',
  );

  final network = latestNetwork;
  if (network != null &&
      network.isCompleteFor(genreKeys) &&
      network.hasAnyBooks) {
    try {
      await repository.saveHomePage(network);
    } catch (error) {
      AppLogger.warning('home', 'Saving home page failed: $error');
    }
  }
});

final genreBooksProvider = FutureProvider.family<List<HomeBookEntity>, String>((
  ref,
  genreKey,
) async {
  final isTurkish = ref.watch(localeProvider).languageCode == 'tr';
  final keyword = HomeRemoteDataSource.turkishGenreQueries[genreKey];
  if (isTurkish && keyword != null) {
    final trbooks = await ref
        .watch(trbooksByKeywordUseCaseProvider)
        .call(keyword);
    if (trbooks.isNotEmpty) {
      return trbooks
          .map(
            (book) => HomeBookEntity(
              id: book.id,
              title: book.title,
              coverImageUrl: book.coverImageUrl,
              authorNames: book.author,
              description: book.description,
              sourceUrl: book.sourceUrl,
            ),
          )
          .toList();
    }
  }
  return ref.watch(homeRepositoryProvider).getBooksByGenre(genreKey);
});
