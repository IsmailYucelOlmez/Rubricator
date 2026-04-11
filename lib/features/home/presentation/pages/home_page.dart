import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../books/presentation/pages/book_detail_page.dart';
import '../../domain/entities/home_book_entity.dart';
import '../providers/home_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _genres = <String>[
    'fantasy',
    'science_fiction',
    'romance',
    'mystery',
  ];

  static const _logoHeight = 40.0 * 1.10;
  static const _appBarPad = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          child: SvgPicture.asset(
            'assets/RubricatorLogov2.svg',
            height: _logoHeight,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(child: _PopularSection(l10n: l10n)),
          for (final genre in _genres)
            SliverToBoxAdapter(child: _GenreSection(genre: genre, l10n: l10n)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
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
        error: (error, stackTrace) => _InlineError(message: l10n.loadPopularBooksError),
      ),
    );
  }
}

class _GenreSection extends ConsumerWidget {
  const _GenreSection({required this.genre, required this.l10n});

  final String genre;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genreBooksProvider(genre));
    return _Section(
      title: _genreLabel(genre, l10n),
      child: state.when(
        data: (books) => _HorizontalBookList(books: books),
        loading: () => const _HorizontalSkeleton(),
        error: (error, stackTrace) => _InlineError(message: l10n.loadGenreBooksError(_genreLabel(genre, l10n))),
      ),
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
    this.topPadding = 10,
  });

  final String title;
  final Widget child;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, topPadding, AppSpacing.md, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: _CoverImage(coverId: book.coverId),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
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
  const _CoverImage({required this.coverId});

  final int? coverId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (coverId == null) {
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(child: Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant)),
      );
    }
    return Image.network(
      'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
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
              child: CircularProgressIndicator(strokeWidth: 2),
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
