import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/widgets/book_cover_leading.dart';
import '../../../books/presentation/widgets/book_cover_with_favorite_button.dart';
import '../../../books/presentation/widgets/book_search_result_tile.dart';
import '../../../document_chat/presentation/pages/document_chat_view.dart';
import '../../../semantic_discovery/presentation/pages/semantic_discovery_view.dart';
import '../providers/search_notifier.dart';

/// Matches home horizontal [HomePage] `_BookCard` author typography.
TextStyle? _homeLikeBookAuthorStyle(TextTheme theme) {
  final bodySmall = theme.bodySmall;
  return bodySmall?.copyWith(
    fontSize: (bodySmall.fontSize ?? 12) * 1.40,
  );
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  Timer? _debounce;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _tabController.dispose();
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
    return SafeArea(
      child: ResponsiveScaffoldBody(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: l10n.searchTabKeyword),
                Tab(text: l10n.searchTabSemantic),
                Tab(text: l10n.searchTabDocumentChat),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _KeywordSearchBody(
                      controller: _controller,
                      onSearchChanged: _onSearchChanged,
                      onSubmitSearch: _submitSearch,
                      onStateChanged: () => setState(() {}),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SemanticDiscoveryView(),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: _KeepAliveDocumentChat(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the document-chat subtree alive when switching Search tabs so an
/// in-flight upload/poll is not dropped by [TabBarView].
class _KeepAliveDocumentChat extends StatefulWidget {
  const _KeepAliveDocumentChat();

  @override
  State<_KeepAliveDocumentChat> createState() => _KeepAliveDocumentChatState();
}

class _KeepAliveDocumentChatState extends State<_KeepAliveDocumentChat>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const DocumentChatView();
  }
}

class _KeywordSearchBody extends ConsumerWidget {
  const _KeywordSearchBody({
    required this.controller,
    required this.onSearchChanged,
    required this.onSubmitSearch,
    required this.onStateChanged,
  });

  final TextEditingController controller;
  final void Function(String raw) onSearchChanged;
  final Future<void> Function() onSubmitSearch;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final raw = controller.text.trim();
    final showHint = raw.isEmpty || raw.length < 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.searchByTitleOrAuthorHint,
            prefixIcon: const Icon(Icons.search),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            onStateChanged();
            onSearchChanged(value);
          },
          onSubmitted: (_) => onSubmitSearch(),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: showHint
              ? _DiscoveryView(
                  l10n: l10n,
                  onOpenBook: (book) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BookDetailPage(book: book),
                      ),
                    );
                  },
                  onPickQuery: (query) {
                    controller.text = query;
                    onStateChanged();
                    ref.read(searchQueryProvider.notifier).state = query;
                    ref.read(searchInteractionProvider).logSubmit(query);
                  },
                )
              : _SearchResultsView(
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
    );
  }
}

class _SearchResultsView extends ConsumerStatefulWidget {
  const _SearchResultsView({
    required this.activeQuery,
    required this.onOpenBook,
  });

  final String activeQuery;
  final ValueChanged<Book> onOpenBook;

  @override
  ConsumerState<_SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends ConsumerState<_SearchResultsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(searchProvider);
    return state.when(
      loading: () => ListView.separated(
        itemCount: 6,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: AppListTileSkeleton(),
        ),
      ),
      error: (error, stackTrace) => AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(searchProvider),
          ),
      data: (pagination) {
        final books = pagination.books;
        if (books.isEmpty) {
          return Center(child: Text(l10n.noBooksFoundFor(widget.activeQuery)));
        }
        return ListView.separated(
          controller: _scrollController,
          itemCount: books.length + (pagination.isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= books.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: AppLoadingIndicator()),
              );
            }
            final book = books[index];
            return BookSearchResultTile(
              book: book,
              onTap: () => widget.onOpenBook(book),
            );
          },
        );
      },
    );
  }
}

class _DiscoveryView extends ConsumerWidget {
  const _DiscoveryView({
    required this.l10n,
    required this.onOpenBook,
    required this.onPickQuery,
  });

  final AppLocalizations l10n;
  final ValueChanged<Book> onOpenBook;
  final ValueChanged<String> onPickQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularQueries = ref.watch(popularSearchProvider);
    final popularBooks = ref.watch(popularBooksProvider);
    return ListView(
      children: [
        Text(
          l10n.recentSearches,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        popularQueries.when(
          loading: () => const AppSkeletonBox(height: 28, borderRadius: AppSpacing.sm),
          error: (error, stackTrace) => AsyncErrorView(
                error: error,
                compact: true,
                onRetry: () => ref.invalidate(popularSearchProvider),
              ),
          data: (queries) {
            if (queries.isEmpty) {
              return Text(l10n.noRecentSearchesYet);
            }
            final displayQueries = queries.take(6).toList();
            return SizedBox(
              height: 104,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                clipBehavior: Clip.hardEdge,
                children: displayQueries
                    .map(
                      (q) => ActionChip(
                        label: Text(q),
                        onPressed: () => onPickQuery(q),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md + AppSpacing.xs),
        Text(
          l10n.recentSearchedBooks,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        popularBooks.when(
          loading: () => const SizedBox(
            height: AppSpacing.xl * 10,
            child: AppSkeletonBox(),
          ),
          error: (error, stackTrace) => AsyncErrorView(
                error: error,
                compact: true,
                onRetry: () => ref.invalidate(popularBooksProvider),
              ),
          data: (books) {
            if (books.isEmpty) {
              return Text(l10n.noRecentSearchedBooksYet);
            }
            final displayBooks = books.take(6).toList();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.52,
              ),
              itemCount: displayBooks.length,
              itemBuilder: (context, index) {
                final book = displayBooks[index];
                final theme = Theme.of(context);
                return InkWell(
                  onTap: () => onOpenBook(book),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BookCoverWithFavoriteButton(
                          bookId: book.id,
                          title: book.title,
                          author: book.author,
                          categories: book.subjectKeys,
                          child: BookCoverLeading(
                            coverImageUrl: book.coverImageUrl,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: bookListTitleStyle(theme.textTheme),
                      ),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _homeLikeBookAuthorStyle(theme.textTheme),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
