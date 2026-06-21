import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
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
import '../../../user_books/presentation/providers/user_books_provider.dart';

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
    final snapshotAsync = ref.watch(homePageSnapshotProvider);
    final favoriteIds = ref.watch(favoriteBookIdsProvider).valueOrNull ??
        const <String>{};

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: math.max(
          _logoHeight + _appBarPad * 2,
          kMinInteractiveDimension + _appBarPad * 2,
        ),
        centerTitle: false,
        titleSpacing: _appBarPad,
        automaticallyImplyLeading: false,
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
      ),
      body: ResponsiveScaffoldBody(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homePageSnapshotProvider);
            ref.invalidate(favoriteBookIdsProvider);
            await ref.read(homePageSnapshotProvider.future);
          },
          child: snapshotAsync.when(
            data: (snapshot) => _HomeScrollContent(
              l10n: l10n,
              popularBooks: snapshot.popularBooks,
              genreSections: snapshot.genreSections,
              favoriteIds: favoriteIds,
              onRetry: () => ref.invalidate(homePageSnapshotProvider),
            ),
            loading: () => _HomeScrollContent.loading(l10n: l10n),
            error: (error, stackTrace) => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(homePageSnapshotProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScrollContent extends StatelessWidget {
  const _HomeScrollContent({
    required this.l10n,
    required this.popularBooks,
    required this.genreSections,
    required this.favoriteIds,
    required this.onRetry,
  });

  const _HomeScrollContent.loading({required this.l10n})
      : popularBooks = null,
        genreSections = null,
        favoriteIds = const <String>{},
        onRetry = _noop;

  static void _noop() {}

  final AppLocalizations l10n;
  final List<HomeBookEntity>? popularBooks;
  final Map<String, HomeGenreSection>? genreSections;
  final Set<String> favoriteIds;
  final VoidCallback onRetry;

  bool get _isLoading => popularBooks == null || genreSections == null;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(
          child: _Section(
            title: l10n.popular,
            child: _isLoading
                ? const _HorizontalSkeleton()
                : popularBooks!.isEmpty
                    ? const _HorizontalSkeleton()
                    : _HorizontalBookList(
                        books: popularBooks!,
                        favoriteIds: favoriteIds,
                      ),
          ),
        ),
        for (final genre in kHomePageGenreKeys)
          SliverToBoxAdapter(
            child: _isLoading
                ? _Section(
                    title: _genreLabel(genre, l10n),
                    child: const _HorizontalSkeleton(),
                  )
                : _GenreSection(
                    genre: genre,
                    section: genreSections![genre]!,
                    l10n: l10n,
                    favoriteIds: favoriteIds,
                    onRetry: onRetry,
                  ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      ],
    );
  }
}

class _GenreSection extends StatelessWidget {
  const _GenreSection({
    required this.genre,
    required this.section,
    required this.l10n,
    required this.favoriteIds,
    required this.onRetry,
  });

  final String genre;
  final HomeGenreSection section;
  final AppLocalizations l10n;
  final Set<String> favoriteIds;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
        body = section.books.isEmpty
            ? softEmpty
            : _HorizontalBookList(books: section.books, favoriteIds: favoriteIds);
      case HomeGenreSectionLoadState.emptyUnavailable:
        body = softEmpty;
      case HomeGenreSectionLoadState.error:
        body = AsyncErrorView(
          error: StateError('home_genre:$genre'),
          compact: true,
          onRetry: onRetry,
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
            fontSize: 10 * 1.2,
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
                  style: titleStyle?.copyWith(fontSize: titleFontSize * 1.10),
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
  const _HorizontalBookList({
    required this.books,
    required this.favoriteIds,
  });

  final List<HomeBookEntity> books;
  final Set<String> favoriteIds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 288,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, index) =>
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        itemBuilder: (context, index) => _BookCard(
          book: books[index],
          isFavorite: favoriteIds.contains(books[index].id),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.isFavorite,
  });

  final HomeBookEntity book;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final titleFontSize = (titleStyle?.fontSize ?? 14) * 1.1;
    final authorStyle = Theme.of(context).textTheme.bodySmall;
    final authorFontSize = (authorStyle?.fontSize ?? 12) * 1.40;
    return SizedBox(
      width: context.isTabletLayout ? 158 : 145,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookDetailPage(book: book.toBook()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BookCoverWithFavoriteButton(
                bookId: book.id,
                title: book.title,
                author: book.authorNames,
                isFavorite: isFavorite,
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
              style: authorStyle?.copyWith(fontSize: authorFontSize),
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
        child: Center(
          child: Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant),
        ),
      );
    }
    return Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: cs.surfaceContainer,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: AppLoadingIndicator(
                size: 20,
                strokeWidth: 2,
                centered: false,
              ),
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
        separatorBuilder: (_, index) =>
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        itemBuilder: (_, index) => Container(
          width: context.isTabletLayout ? 158 : 145,
          decoration: BoxDecoration(
            color: placeholder,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}
