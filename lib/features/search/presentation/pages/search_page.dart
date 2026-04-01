import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/widgets/book_cover_leading.dart';
import '../providers/search_notifier.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

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
      ref.read(searchQueryProvider.notifier).state = q;
    });
  }

  Future<void> _submitSearch() async {
    final q = _controller.text.trim();
    ref.read(searchQueryProvider.notifier).state = q;
    await ref.read(searchInteractionProvider).logSubmit(q);
  }

  @override
  Widget build(BuildContext context) {
    final raw = _controller.text.trim();
    final showHint = raw.isEmpty || raw.length < 2;
    final searchResult = ref.watch(searchProvider);
    final popularQueries = ref.watch(popularSearchProvider);
    final popularBooks = ref.watch(popularBooksProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Books',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search by title or author (min. 2 characters)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
              onSubmitted: (_) => _submitSearch(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: showHint
                  ? _DiscoveryView(
                      popularQueries: popularQueries,
                      popularBooks: popularBooks,
                      onOpenBook: (book) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BookDetailPage(book: book),
                          ),
                        );
                      },
                      onPickQuery: (query) {
                        _controller.text = query;
                        setState(() {});
                        ref.read(searchQueryProvider.notifier).state = query;
                      },
                    )
                  : _SearchResultsView(
                      state: searchResult,
                      activeQuery: raw,
                      onOpenBook: (book) async {
                        await ref
                            .read(searchInteractionProvider)
                            .logBookClick(query: raw, bookId: book.id);
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BookDetailPage(book: book),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.state,
    required this.activeQuery,
    required this.onOpenBook,
  });

  final AsyncValue<List<Book>> state;
  final String activeQuery;
  final ValueChanged<Book> onOpenBook;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Search failed: ${error.toString().replaceFirst('Exception: ', '')}',
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Center(child: Text('No books found for "$activeQuery".'));
        }
        return _BookList(books: books, onOpenBook: onOpenBook);
      },
    );
  }
}

class _DiscoveryView extends StatelessWidget {
  const _DiscoveryView({
    required this.popularQueries,
    required this.popularBooks,
    required this.onOpenBook,
    required this.onPickQuery,
  });

  final AsyncValue<List<String>> popularQueries;
  final AsyncValue<List<Book>> popularBooks;
  final ValueChanged<Book> onOpenBook;
  final ValueChanged<String> onPickQuery;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          'Popular Searches',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        popularQueries.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) =>
              const Text('Could not load popular searches.'),
          data: (queries) {
            if (queries.isEmpty) {
              return const Text('No popular searches yet.');
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: queries
                  .map(
                    (q) => ActionChip(
                      label: Text(q),
                      onPressed: () => onPickQuery(q),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        Text('Popular Books', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        popularBooks.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) =>
              const Text('Could not load popular books.'),
          data: (books) {
            if (books.isEmpty) {
              return const Text('No popular books yet.');
            }
            return SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return SizedBox(
                    width: 160,
                    child: InkWell(
                      onTap: () => onOpenBook(book),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 0.7,
                                child: BookCoverLeading(coverId: book.coverId),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                book.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books, required this.onOpenBook});

  final List<Book> books;
  final ValueChanged<Book> onOpenBook;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          leading: BookCoverLeading(coverId: book.coverId),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onOpenBook(book),
        );
      },
    );
  }
}
