import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';

import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/widgets/book_cover_with_favorite_button.dart';
import 'genre_books_page.dart';
import '../../domain/entities/home_book_entity.dart';
import '../../domain/entities/home_genre_section.dart';
import '../providers/home_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _logoHeight = 40.0 * 1.10;
  static const _appBarPad = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final genreSections = ref.watch(homeGenreSectionsProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: math.max(
          _logoHeight + _appBarPad * 2,
          kMinInteractiveDimension + _appBarPad * 2,
        ),
        centerTitle: false,
        titleSpacing: _appBarPad,
        automaticallyImplyLeading: false,
        actionsPadding: const EdgeInsets.only(
          top: _appBarPad,
          right: _appBarPad,
          bottom: _appBarPad,
        ),
        title: Padding(
          padding: const EdgeInsets.fromLTRB(
            _appBarPad,
            _appBarPad,
            0,
            _appBarPad,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rubricator',
              style: TextStyle(
                fontFamily: 'Nouveau',
                fontSize: _logoHeight * 0.7,
                height: 1.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(popularBooksProvider.future),
            ref.refresh(homeGenreSectionsProvider.future),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(child: _PopularSection(l10n: l10n)),
            ...genreSections.when(
              data: (map) => [
                for (final genre in kHomePageGenreKeys)
                  SliverToBoxAdapter(
                    child: _GenreSection(
                      genre: genre,
                      section: map[genre] ??
                          const HomeGenreSection(
                            books: <HomeBookEntity>[],
                            loadState: HomeGenreSectionLoadState.error,
                          ),
                      l10n: l10n,
                    ),
                  ),
              ],
              loading: () => [
                for (final genre in kHomePageGenreKeys)
                  SliverToBoxAdapter(
                    child: _Section(
                      title: _genreLabel(genre, l10n),
                      child: const _HorizontalSkeleton(),
                    ),
                  ),
              ],
              error: (error, stackTrace) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: AsyncErrorView(
                      error: error,
                      compact: true,
                      onRetry: () => ref.invalidate(homeGenreSectionsProvider),
                    ),
                  ),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],
        ),
      ),
    );
  }
}

class _PopularSection extends ConsumerWidget {
  const _PopularSection({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(popularBooksProvider);
    return _Section(
      title: l10n.popular,
      child: state.when(
        data: (books) => _HorizontalBookList(books: books),
        loading: () => const _HorizontalSkeleton(),
        error: (error, stackTrace) => AsyncErrorView(
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(popularBooksProvider),
        ),
      ),
    );
  }
}

class _GenreSection extends ConsumerWidget {
  const _GenreSection({
    required this.genre,
    required this.section,
    required this.l10n,
  });

  final String genre;
  final HomeGenreSection section;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genreLabel = _genreLabel(genre, l10n);
    final theme = Theme.of(context);
    final softEmpty = SizedBox(
      height: 72,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            l10n.homeGenreEmptySoft(genreLabel),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );

    late final Widget body;
    switch (section.loadState) {
      case HomeGenreSectionLoadState.ready:
        body = section.books.isEmpty ? softEmpty : _HorizontalBookList(books: section.books);
      case HomeGenreSectionLoadState.emptyUnavailable:
        body = softEmpty;
      case HomeGenreSectionLoadState.error:
        body = AsyncErrorView(
          error: StateError('home_genre:$genre'),
          compact: true,
          onRetry: () => ref.invalidate(homeGenreSectionsProvider),
        );
    }

    return _Section(
      title: genreLabel,
      trailing: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GenreBooksPage(
              genreKey: genre,
              genreLabel: genreLabel,
            ),
          ),
        ),
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        ),
        child: Text(
          l10n.homeShowAll,
          style: TextStyle(
            fontFamily: 'LTMuseum',
            fontSize: 10,
          ),
        ),
      ),
      child: body,
    );
  }
}

String _genreLabel(String genre, AppLocalizations l10n) {
  switch (genre) {
    case 'fantasy':
      return l10n.genreFantasy;
    case 'science_fiction':
      return l10n.genreScienceFiction;
    case 'romance':
      return l10n.genreRomance;
    case 'mystery':
      return l10n.genreMystery;
    case 'thriller':
      return l10n.genreThriller;
    case 'horror':
      return l10n.genreHorror;
    default:
      return _titleCaseWords(genre.replaceAll('_', ' '));
  }
}

String _titleCaseWords(String raw) {
  return raw.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return word;
    final lower = word.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final titleFontSize = titleStyle?.fontSize ?? 22;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: titleStyle?.copyWith(fontSize: titleFontSize * 1.50),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HorizontalBookList extends StatelessWidget {
  const _HorizontalBookList({required this.books});

  final List<HomeBookEntity> books;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 288,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, index) => const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        itemBuilder: (context, index) => _BookCard(book: books[index]),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final HomeBookEntity book;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final titleFontSize = (titleStyle?.fontSize ?? 14) * 0.80;
    return SizedBox(
      width: 145,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book.toBook())),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BookCoverWithFavoriteButton(
                bookId: book.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: _CoverImage(coverImageUrl: book.coverImageUrl),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: titleStyle?.copyWith(
                fontSize: titleFontSize,
                fontFamily: 'LTSoul',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.authorNames,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = AppConstants.bookThumbnailUrl(coverImageUrl);
    if (url == null) {
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(child: Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant)),
      );
    }
    return Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: cs.surfaceContainer,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: AppLoadingIndicator(size: 20, strokeWidth: 2, centered: false),
            ),
          ),
        );
      },
    );
  }
}

class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    final placeholder = Theme.of(context).colorScheme.surfaceContainerHighest;
    return SizedBox(
      height: 288,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, index) => const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        itemBuilder: (_, index) => Container(
          width: 145,
          decoration: BoxDecoration(
            color: placeholder,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

