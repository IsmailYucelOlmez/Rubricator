import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = raw.trim();
      setState(() => _query = q.length >= 2 ? q : '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.isNotEmpty;
    final searchResults = searching ? ref.watch(searchProvider(_query)) : null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search books (min. 2 characters)',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: searching
          ? _SearchResultList(result: searchResults!)
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      'Discover',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _PopularSection()),
                for (final genre in _genres)
                  SliverToBoxAdapter(child: _GenreSection(genre: genre)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }
}

class _SearchResultList extends StatelessWidget {
  const _SearchResultList({required this.result});

  final AsyncValue<List<HomeBookEntity>> result;

  @override
  Widget build(BuildContext context) {
    return result.when(
      data: (books) {
        if (books.isEmpty) return const Center(child: Text('No books found'));
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: books.length,
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (context, index) => _BookListTile(book: books[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not complete the search. Please try again.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PopularSection extends ConsumerWidget {
  const _PopularSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(popularBooksProvider);
    return _Section(
      title: 'Popular',
      child: state.when(
        data: (books) => _HorizontalBookList(books: books),
        loading: () => const _HorizontalSkeleton(),
        error: (error, stackTrace) =>
            const _InlineError(message: 'Could not load popular books.'),
      ),
    );
  }
}

class _GenreSection extends ConsumerWidget {
  const _GenreSection({required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genreBooksProvider(genre));
    return _Section(
      title: genre.replaceAll('_', ' ').toUpperCase(),
      child: state.when(
        data: (books) => _HorizontalBookList(books: books),
        loading: () => const _HorizontalSkeleton(),
        error: (error, stackTrace) =>
            _InlineError(message: 'Could not load $genre books.'),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
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
                borderRadius: BorderRadius.circular(10),
                child: _CoverImage(coverId: book.coverId),
              ),
            ),
            const SizedBox(height: 8),
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

class _BookListTile extends StatelessWidget {
  const _BookListTile({required this.book});

  final HomeBookEntity book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 42,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _CoverImage(coverId: book.coverId),
        ),
      ),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        book.authorNames,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book.toBook())),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverId});

  final int? coverId;

  @override
  Widget build(BuildContext context) {
    if (coverId == null) {
      return const ColoredBox(
        color: Color(0xFFECECEC),
        child: Center(child: Icon(Icons.menu_book_outlined)),
      );
    }
    return Image.network(
      'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0xFFECECEC),
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFFF2F2F2),
          child: Center(
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
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (_, index) => Container(
          width: 145,
          decoration: BoxDecoration(
            color: const Color(0xFFECECEC),
            borderRadius: BorderRadius.circular(10),
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
