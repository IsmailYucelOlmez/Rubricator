import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';

import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/widgets/vertical_book_card.dart';
import '../providers/search_notifier.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with RouteAware {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _clearFocus();
  }

  void _clearFocus() {
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final q = raw.trim();
      ref.read(searchQueryProvider.notifier).state = q;
    });
  }

  Future<void> _submitSearch() async {
    final q = _controller.text.trim();
    ref.read(searchQueryProvider.notifier).state = q;
    _clearFocus();
    await ref.read(searchInteractionProvider).logSubmit(q);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ResponsiveScaffoldBody(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _KeywordSearchBody(
            controller: _controller,
            focusNode: _focusNode,
            onSearchChanged: _onSearchChanged,
            onSubmitSearch: _submitSearch,
            onClearFocus: _clearFocus,
            onStateChanged: () => setState(() {}),
          ),
        ),
      ),
    );
  }
}

class _KeywordSearchBody extends ConsumerWidget {
  const _KeywordSearchBody({
    required this.controller,
    required this.focusNode,
    required this.onSearchChanged,
    required this.onSubmitSearch,
    required this.onClearFocus,
    required this.onStateChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String raw) onSearchChanged;
  final Future<void> Function() onSubmitSearch;
  final VoidCallback onClearFocus;
  final VoidCallback onStateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasText = controller.text.isNotEmpty;
    final raw = controller.text.trim();
    final showHint = raw.isEmpty || raw.length < 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: l10n.searchByTitleOrAuthorHint,
            prefixIcon: const Icon(Icons.search),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                color: AppColors.lightOnSurface,
                width: 1.5,
              ),
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () {
                      controller.clear();
                      onStateChanged();
                      onSearchChanged('');
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
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
                    onClearFocus();
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
                    onClearFocus();
                  },
                )
              : _SearchResultsView(
                  activeQuery: raw,
                  onOpenBook: (book) async {
                    onClearFocus();
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
      loading: () => GridView.builder(
        gridDelegate: BookGridLayout.delegate,
        itemCount: 6,
        itemBuilder: (_, _) => const VerticalBookCardSkeleton(),
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
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverGrid(
              gridDelegate: BookGridLayout.delegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final book = books[index];
                  return VerticalBookCard(
                    book: book,
                    onTap: () => widget.onOpenBook(book),
                  );
                },
                childCount: books.length,
              ),
            ),
            if (pagination.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: AppLoadingIndicator()),
                ),
              ),
          ],
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
              gridDelegate: BookGridLayout.delegate,
              itemCount: displayBooks.length,
              itemBuilder: (context, index) {
                final book = displayBooks[index];
                return VerticalBookCard(
                  book: book,
                  onTap: () => onOpenBook(book),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
