import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/navigation/web_page_title.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/sign_in_guard.dart';
import '../../../user_books/presentation/providers/user_books_provider.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../providers/book_resolve_providers.dart';
import '../providers/books_providers.dart';
import '../widgets/book_detail/add_content_sheet.dart';
import '../widgets/book_detail/book_content_tabs.dart';
import '../widgets/book_detail/book_description.dart';
import '../widgets/book_detail/book_detail_common.dart';
import '../widgets/book_detail/book_detail_header.dart';
import '../widgets/book_detail/reading_status_card.dart';
import '../widgets/book_detail/related_books_section.dart';
import '../widgets/book_detail/user_rating_card.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(
    length: BookContentTab.values.length,
    vsync: this,
  );
  final _scrollController = ScrollController();

  /// Whether the title has scrolled away and the app bar shows it.
  final _showTitleInAppBar = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _showTitleInAppBar.value =
          _scrollController.offset > BookDetailHeader.titleRevealOffset;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _showTitleInAppBar.dispose();
    super.dispose();
  }

  bool get _startsPending => isPendingBookId(widget.book.id);

  void _retryDetail() {
    if (_startsPending) {
      ref.invalidate(resolveBookProvider(widget.book));
      ref.invalidate(resolvedBookDetailProvider(widget.book));
    } else {
      ref.invalidate(bookDetailProvider(widget.book));
    }
  }

  Future<void> _addContent(String bookId) async {
    if (!await ensureSignedIn(context, ref) || !mounted) return;
    await showAddContentSheet(
      context,
      bookId: bookId,
      initialTab: BookContentTab.values[_tabController.index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = _startsPending
        ? ref.watch(resolvedBookDetailProvider(widget.book))
        : ref.watch(bookDetailProvider(widget.book));

    // Show the seed immediately; resolve/detail hydrate in place.
    final book = detailAsync.valueOrNull ?? bookEntityFromBook(widget.book);
    final isPending = isPendingBookId(book.id);

    // Also covers a failed resolve of a `pending:` book, which used to leave
    // the page on skeletons with no way to retry.
    if (detailAsync.hasError && !detailAsync.hasValue) {
      return WebPageTitle(
        label: '${book.title} · Rubricator',
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.bookDetails)),
          body: AsyncErrorView(
            error: detailAsync.error!,
            onRetry: _retryDetail,
          ),
        ),
      );
    }

    final gutter = bookDetailGutter(context);
    return WebPageTitle(
      label: '${book.title} · Rubricator',
      child: Scaffold(
        floatingActionButton: isPending
            ? null
            : FloatingActionButton(
                tooltip: l10n.addReview,
                onPressed: () => _addContent(book.id),
                child: const Icon(Icons.add),
              ),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              title: ValueListenableBuilder<bool>(
                valueListenable: _showTitleInAppBar,
                builder: (context, showTitle, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    showTitle ? book.title : l10n.bookDetails,
                    key: ValueKey(showTitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              actions: [
                if (!isPending) _StoreAction(book: book),
                if (!isPending) _FavoriteAction(book: book),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.md,
                gutter,
                AppSpacing.lg,
              ),
              sliver: SliverList.list(
                children: [
                  BookDetailHeader(book: book, isPending: isPending),
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  _PersonalSection(book: book, isPending: isPending),
                  const SizedBox(height: AppSpacing.md),
                  BookDescription(description: book.description),
                  const SizedBox(height: AppSpacing.lg),
                  RelatedBooksSection(book: book, isPending: isPending),
                ],
              ),
            ),
            if (isPending)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: const SliverToBoxAdapter(
                  child: AppSkeletonBox(height: 180),
                ),
              )
            else
              BookContentTabs(
                bookId: book.id,
                controller: _tabController,
                gutter: gutter,
              ),
            // Room for the FAB over the last item.
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reading status + own rating when signed in, a sign-in prompt otherwise.
class _PersonalSection extends ConsumerWidget {
  const _PersonalSection({required this.book, required this.isPending});

  final BookEntity book;
  final bool isPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (isPending || (auth.isLoading && !auth.hasValue)) {
      return const Column(
        children: [
          AppSkeletonBox(height: 72),
          SizedBox(height: AppSpacing.sm),
          AppSkeletonBox(height: 96),
        ],
      );
    }
    if (auth.valueOrNull == null) {
      return SignInPromptCard(
        message: AppLocalizations.of(context)!.signInToRateAndTrack,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReadingStatusCard(book: book),
        const SizedBox(height: AppSpacing.sm),
        UserRatingCard(bookId: book.id),
      ],
    );
  }
}

class _StoreAction extends StatelessWidget {
  const _StoreAction({required this.book});

  final BookEntity book;

  @override
  Widget build(BuildContext context) {
    final url = book.sourceUrl;
    final store = book.store;
    if (url == null || store == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      tooltip: switch (store) {
        BookStore.dr => l10n.openInDr,
        BookStore.kitapyurdu => l10n.openInKitapyurdu,
      },
      onPressed: () => openExternalUrl(context, url),
      icon: const Icon(Icons.storefront_outlined),
    );
  }
}

class _FavoriteAction extends ConsumerStatefulWidget {
  const _FavoriteAction({required this.book});

  final BookEntity book;

  @override
  ConsumerState<_FavoriteAction> createState() => _FavoriteActionState();
}

class _FavoriteActionState extends ConsumerState<_FavoriteAction> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (!await ensureSignedIn(context, ref) || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(userBookProvider(widget.book.id).notifier)
          .toggleFavorite(snapshot: userBookSnapshotOf(widget.book));
    } catch (e) {
      if (mounted) showBookDetailError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFavorite = ref.watch(
      userBookProvider(
        widget.book.id,
      ).select((a) => a.valueOrNull?.isFavorite ?? false),
    );
    return IconButton(
      tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
      onPressed: _busy ? null : _toggle,
      icon: _busy
          ? const AppLoadingIndicator(size: 18, strokeWidth: 2, centered: false)
          : Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
    );
  }
}
