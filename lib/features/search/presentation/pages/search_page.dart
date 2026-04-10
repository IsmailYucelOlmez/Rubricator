import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final raw = _controller.text.trim();
    final showHint = raw.isEmpty || raw.length < 2;
    final searchResult = ref.watch(searchProvider);
    final popularQueries = ref.watch(popularSearchProvider);
    final popularBooks = ref.watch(popularBooksProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.searchBooksTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.searchByTitleOrAuthorHint,
                prefixIcon: const Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
              onSubmitted: (_) => _submitSearch(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: showHint
                  ? _DiscoveryView(
                      l10n: l10n,
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
                      l10n: l10n,
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
    required this.l10n,
    required this.state,
    required this.activeQuery,
    required this.onOpenBook,
  });

  final AppLocalizations l10n;
  final AsyncValue<List<Book>> state;
  final String activeQuery;
  final ValueChanged<Book> onOpenBook;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          l10n.searchFailed(error.toString().replaceFirst('Exception: ', '')),
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Center(child: Text(l10n.noBooksFoundFor(activeQuery)));
        }
        return _BookList(books: books, onOpenBook: onOpenBook);
      },
    );
  }
}

class _DiscoveryView extends StatelessWidget {
  const _DiscoveryView({
    required this.l10n,
    required this.popularQueries,
    required this.popularBooks,
    required this.onOpenBook,
    required this.onPickQuery,
  });

  final AsyncValue<List<String>> popularQueries;
  final AppLocalizations l10n;
  final AsyncValue<List<Book>> popularBooks;
  final ValueChanged<Book> onOpenBook;
  final ValueChanged<String> onPickQuery;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          l10n.recentSearches,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        popularQueries.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => Text(l10n.loadRecentSearchesError),
          data: (queries) {
            if (queries.isEmpty) {
              return Text(l10n.noRecentSearchesYet);
            }
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
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
        const SizedBox(height: AppSpacing.md + AppSpacing.xs),
        Text(l10n.recentSearchedBooks, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        popularBooks.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => Text(l10n.loadRecentSearchedBooksError),
          data: (books) {
            if (books.isEmpty) {
              return Text(l10n.noRecentSearchedBooksYet);
            }
            return SizedBox(
              height: AppSpacing.xl * 8,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return SizedBox(
                    width: 160,
                    child: InkWell(
                      onTap: () => onOpenBook(book),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 0.7,
                                child: BookCoverLeading(coverId: book.coverId),
                              ),
                              const SizedBox(height: AppSpacing.sm),
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
