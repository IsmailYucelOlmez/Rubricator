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
      if (q.length < 2) {
        ref.read(searchNotifierProvider.notifier).clear();
      } else {
        ref.read(searchNotifierProvider.notifier).search(q);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final raw = _controller.text.trim();
    final showHint = raw.isEmpty || raw.length < 2;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Books', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search by title or author (min. 2 characters)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
            ),
            if (!showHint && searchState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                searchState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: showHint
                  ? const Center(child: Text('Start typing to search books'))
                  : _SearchResultsView(
                      state: searchState,
                      onLoadMore: () => ref
                          .read(searchNotifierProvider.notifier)
                          .loadMore(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({required this.state, required this.onLoadMore});

  final SearchState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.loadingFirstPage && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.loadingFirstPage && state.items.isEmpty) {
      return const Center(child: Text('No books found for this search.'));
    }
    return _BookList(
      books: state.items,
      onNearEnd: onLoadMore,
      loadingMore: state.loadingMore,
      hasMore: state.hasMore,
    );
  }
}

class _BookList extends StatefulWidget {
  const _BookList({
    required this.books,
    required this.onNearEnd,
    required this.loadingMore,
    this.hasMore = false,
  });

  final List<Book> books;
  final VoidCallback? onNearEnd;
  final bool loadingMore;
  final bool hasMore;

  @override
  State<_BookList> createState() => _BookListState();
}

class _BookListState extends State<_BookList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onNearEnd == null || !widget.hasMore || widget.loadingMore) {
      return;
    }
    if (!_scroll.hasClients) return;
    const threshold = 280.0;
    if (_scroll.position.maxScrollExtent - _scroll.position.pixels < threshold) {
      widget.onNearEnd!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scroll,
      itemCount: widget.books.length + (widget.loadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= widget.books.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final book = widget.books[index];
        return ListTile(
          leading: BookCoverLeading(coverId: book.coverId),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book)),
          ),
        );
      },
    );
  }
}
