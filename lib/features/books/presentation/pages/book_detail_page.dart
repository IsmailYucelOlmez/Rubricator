import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/navigation/web_page_title.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/book_cover_utils.dart';
import '../../../../core/utils/relative_time_utils.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_toggle_switch.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../user_books/domain/entities/user_book_entity.dart';
import '../../../user_books/domain/entities/user_book_snapshot.dart';
import '../../../user_books/presentation/providers/user_books_provider.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../providers/book_resolve_providers.dart';
import '../providers/books_providers.dart';
import '../../../book_notes/presentation/providers/book_notes_providers.dart';
import '../../../book_notes/presentation/widgets/book_note_form_sheet.dart';
import '../../../book_notes/domain/usecases/book_notes_usecases.dart';
import '../../../book_notes/presentation/widgets/book_notes_tab.dart';
import '../widgets/book_cover_with_favorite_button.dart';
import 'author_detail_page.dart';

TextStyle _bookDetailBodyStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!;

TextStyle _bookDetailInputStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge!;

Color _bookDetailBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? AppColors.lightOnSurface
      : AppColors.textPrimary.withValues(alpha: 0.4);
}

Color _bookDetailStarColor(BuildContext context, {required bool filled}) {
  if (filled) {
    return AppColors.accent(context);
  }
  return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
}

class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage>
    with SingleTickerProviderStateMixin {
  final _reviewController = TextEditingController();
  final _externalTitleController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _externalDescriptionController = TextEditingController();
  final _quoteController = TextEditingController();
  final _noteTitleController = TextEditingController();
  final _noteContentController = TextEditingController();
  final _notePageController = TextEditingController();
  final _noteChapterController = TextEditingController();
  final _noteTagsController = TextEditingController();
  late final TabController _contentTabController;
  // Rating is stored on a 1-10 scale (half-star steps on a 5-star UI).
  int _selectedRating = 0;
  bool _isEditingRating = false;
  bool _favoriteBusy = false;
  bool _preferExternalReviews = false;

  @override
  void initState() {
    super.initState();
    _contentTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _contentTabController.dispose();
    _reviewController.dispose();
    _externalTitleController.dispose();
    _externalUrlController.dispose();
    _externalDescriptionController.dispose();
    _quoteController.dispose();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    _notePageController.dispose();
    _noteChapterController.dispose();
    _noteTagsController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// trbooks only scrapes two stores; the product page host tells them apart.
  bool _isDrUrl(String url) =>
      (Uri.tryParse(url)?.host ?? '').toLowerCase().contains('dr.com');

  Future<void> _openSourceUrl(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage(l10n.invalidUrl);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showMessage(l10n.couldNotOpenBrowser);
    }
  }

  UserBookSnapshot _snapshotFor({
    required String title,
    required String author,
    required List<String> categories,
  }) {
    return UserBookSnapshot(
      title: title,
      author: author,
      categories: categories,
    );
  }

  Future<void> _setReadingStatus(
    ReadingStatus selected, {
    required String bookId,
    required bool isFavorite,
    required String title,
    required String author,
    required List<String> categories,
  }) async {
    await ref
        .read(userBookProvider(bookId).notifier)
        .upsert(
          status: selected,
          isFavorite: isFavorite,
          snapshot: _snapshotFor(
            title: title,
            author: author,
            categories: categories,
          ),
        );
  }

  void _feedbackError(Object e, [BuildContext? feedbackContext]) {
    final ctx = feedbackContext ?? context;
    if (!(feedbackContext?.mounted ?? mounted)) return;
    final l10n = AppLocalizations.of(ctx)!;
    final s = e.toString().toLowerCase();
    if (s.contains('sign in required') || s.contains('sign in to')) {
      AppFeedback.showSuccessSnackBar(ctx, l10n.uxMustSignIn);
      return;
    }
    if (s.contains('10 characters')) {
      AppFeedback.showSuccessSnackBar(ctx, l10n.uxReviewMinLength);
      return;
    }
    if (s.contains('title is required')) {
      AppFeedback.showSuccessSnackBar(ctx, l10n.uxTitleRequired);
      return;
    }
    if (s.contains('valid url') || s.contains('invalid url')) {
      AppFeedback.showSuccessSnackBar(ctx, l10n.invalidUrl);
      return;
    }
    if (e is BookNoteValidationException) {
      AppFeedback.showSuccessSnackBar(ctx, e.message);
      return;
    }
    AppFeedback.showErrorSnackBar(ctx, e);
  }

  Future<void> _showAddContentSheet(
    BuildContext context, {
    required String bookId,
    required int initialTabIndex,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final mq = MediaQuery.of(sheetContext);
        final keyboard = mq.viewInsets.bottom;
        final preferredHeight = (mq.size.height * 0.58).clamp(420.0, 560.0);
        final maxSheetHeight = (mq.size.height - keyboard - 24).clamp(
          200.0,
          mq.size.height,
        );
        final sheetHeight = preferredHeight > maxSheetHeight
            ? maxSheetHeight
            : preferredHeight;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: SizedBox(
            height: sheetHeight,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: SafeArea(
                top: false,
                child: _AddContentBottomSheet(
                  initialTabIndex: initialTabIndex,
                  reviewController: _reviewController,
                  externalTitleController: _externalTitleController,
                  externalUrlController: _externalUrlController,
                  externalDescriptionController: _externalDescriptionController,
                  quoteController: _quoteController,
                  noteTitleController: _noteTitleController,
                  noteContentController: _noteContentController,
                  notePageController: _notePageController,
                  noteChapterController: _noteChapterController,
                  noteTagsController: _noteTagsController,
                  onAddReview: (isSpoiler) async {
                    try {
                      await ref
                          .read(reviewListProvider(bookId).notifier)
                          .add(_reviewController.text, isSpoiler: isSpoiler);
                      _reviewController.clear();
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (!mounted) return;
                      _showMessage(l10n.reviewAdded);
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      _feedbackError(e, sheetContext);
                    }
                  },
                  onAddExternalReview: () async {
                    try {
                      await ref
                          .read(externalReviewProvider(bookId).notifier)
                          .add(
                            title: _externalTitleController.text,
                            url: _externalUrlController.text,
                            description: _externalDescriptionController.text,
                          );
                      _externalTitleController.clear();
                      _externalUrlController.clear();
                      _externalDescriptionController.clear();
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (!mounted) return;
                      setState(() {
                        _preferExternalReviews = true;
                        _contentTabController.index = 0;
                      });
                      _showMessage(l10n.externalReviewAdded);
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      _feedbackError(e, sheetContext);
                    }
                  },
                  onAddQuote: () async {
                    try {
                      await ref
                          .read(quoteProvider(bookId).notifier)
                          .add(_quoteController.text);
                      _quoteController.clear();
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (!mounted) return;
                      _showMessage(l10n.quoteAdded);
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      _feedbackError(e, sheetContext);
                    }
                  },
                  onAddNote: ({required isPublic}) async {
                    try {
                      await ref
                          .read(publicBookNotesProvider(bookId).notifier)
                          .addNote(
                            noteTitle: _noteTitleController.text,
                            noteContent: _noteContentController.text,
                            pageNumber: parseBookNotePage(
                              _notePageController.text,
                            ),
                            chapterTitle:
                                _noteChapterController.text.trim().isEmpty
                                ? null
                                : _noteChapterController.text.trim(),
                            tags: parseBookNoteTags(_noteTagsController.text),
                            isPublic: isPublic,
                          );
                      _noteTitleController.clear();
                      _noteContentController.clear();
                      _notePageController.clear();
                      _noteChapterController.clear();
                      _noteTagsController.clear();
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      if (!mounted) return;
                      _showMessage(l10n.noteAdded);
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      _feedbackError(e, sheetContext);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seedEntity = bookEntityFromBook(widget.book);
    final detailedBookAsync = isPendingBookId(widget.book.id)
        ? ref.watch(resolvedBookDetailProvider(widget.book))
        : ref.watch(bookDetailProvider(widget.book));

    // Show seed immediately; resolve/detail hydrate in place (no blocking spinner).
    final detailedBook = detailedBookAsync.valueOrNull ?? seedEntity;
    final isPendingId = isPendingBookId(detailedBook.id);
    final detailFailed =
        detailedBookAsync.hasError && !isPendingBookId(widget.book.id);

    final userBookAsync = isPendingId
        ? const AsyncValue<UserBookEntity?>.data(null)
        : ref.watch(userBookProvider(detailedBook.id));
    final userBook = userBookAsync.valueOrNull;
    final isFavorite = userBook?.isFavorite ?? false;
    final status = userBook?.status;

    return WebPageTitle(
      label: '${detailedBook.title} · Rubricator',
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.bookDetails),
          actions: [
            if (!isPendingId && detailedBook.sourceUrl != null)
              IconButton(
                tooltip: _isDrUrl(detailedBook.sourceUrl!)
                    ? l10n.openInDr
                    : l10n.openInKitapyurdu,
                onPressed: () => _openSourceUrl(detailedBook.sourceUrl!),
                icon: const Icon(Icons.storefront_outlined),
              ),
            IconButton(
              onPressed: isPendingId
                  ? null
                  : () async {
                      try {
                        await showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => _StatusBottomSheet(
                            current: status,
                            onSelect: (selected) async {
                              await _setReadingStatus(
                                selected,
                                bookId: detailedBook.id,
                                isFavorite: isFavorite,
                                title: detailedBook.title,
                                author: detailedBook.author,
                                categories: detailedBook.subjectKeys,
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        _feedbackError(e);
                      }
                    },
              icon: const Icon(Icons.menu_book_outlined),
            ),
            IconButton(
              onPressed: isPendingId || _favoriteBusy
                  ? null
                  : () async {
                      setState(() => _favoriteBusy = true);
                      try {
                        await ref
                            .read(userBookProvider(detailedBook.id).notifier)
                            .toggleFavorite(
                              snapshot: _snapshotFor(
                                title: detailedBook.title,
                                author: detailedBook.author,
                                categories: detailedBook.subjectKeys,
                              ),
                            );
                      } catch (e) {
                        if (!mounted) return;
                        _feedbackError(e);
                      } finally {
                        if (mounted) setState(() => _favoriteBusy = false);
                      }
                    },
              icon: _favoriteBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: AppLoadingIndicator(
                        size: 18,
                        strokeWidth: 2,
                        centered: false,
                      ),
                    )
                  : Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
            ),
          ],
        ),
        floatingActionButton: !isPendingId
            ? FloatingActionButton(
                onPressed: () => _showAddContentSheet(
                  context,
                  bookId: detailedBook.id,
                  initialTabIndex: _contentTabController.index,
                ),
                child: const Icon(Icons.add),
              )
            : null,
        body: ResponsiveScaffoldBody(
          child: detailFailed
              ? AsyncErrorView(
                  error: detailedBookAsync.error!,
                  onRetry: () =>
                      ref.invalidate(bookDetailProvider(widget.book)),
                )
              : _buildDetailBody(
                  context: context,
                  l10n: l10n,
                  detailedBook: detailedBook,
                  isPendingId: isPendingId,
                  userBook: userBook,
                  isFavorite: isFavorite,
                  status: status,
                ),
        ),
      ),
    );
  }

  Widget _buildDetailBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required BookEntity detailedBook,
    required bool isPendingId,
    required UserBookEntity? userBook,
    required bool isFavorite,
    required ReadingStatus? status,
  }) {
    final reviews = isPendingId
        ? const AsyncValue<List<ReviewEntity>>.data([])
        : ref.watch(reviewListProvider(detailedBook.id));
    final externalReviews = isPendingId
        ? const AsyncValue<List<ExternalReviewEntity>>.data([])
        : ref.watch(externalReviewProvider(detailedBook.id));
    final quotes = isPendingId
        ? const AsyncValue<List<QuoteEntity>>.data([])
        : ref.watch(quoteProvider(detailedBook.id));
    final rating = isPendingId
        ? const AsyncValue<RatingState>.loading()
        : ref.watch(ratingProvider(detailedBook.id));
    final hasUserRated = rating.valueOrNull?.userRating != null;
    final userRating = rating.valueOrNull?.userRating;
    final selectedRatingForUi = _selectedRating > 0
        ? _selectedRating
        : (userRating ?? 0);
    final coverUrl = AppConstants.bookDetailCoverUrl(
      detailedBook.coverImageUrl,
    );
    final related = isPendingId
        ? const AsyncValue<List<Book>>.loading()
        : ref.watch(
            relatedBooksProvider((
              workId: detailedBook.id,
              subjects: detailedBook.subjectKeys,
              author: detailedBook.author,
            )),
          );
    final bookDescription = stripHtmlTags(detailedBook.description);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + 72 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (coverUrl != null) _BookDetailCover(url: coverUrl),
        Text(
          detailedBook.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (detailedBook.isUserSubmitted) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                AppLocalizations.of(context)!.userSubmittedBadgeLabel,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
        const SizedBox(height: 4),
        if (detailedBook.authorIds.isNotEmpty)
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AuthorDetailPage(authorId: detailedBook.authorIds.first),
                ),
              );
            },
            child: Text(
              detailedBook.author,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        else
          Text(
            detailedBook.author,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 12),
        if (isPendingId)
          const AppSkeletonBox(height: 72)
        else
          _ReadingStatusCard(
            userBook: userBook,
            onTapSelectStatus: () async {
              try {
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => _StatusBottomSheet(
                    current: status,
                    onSelect: (selected) async {
                      await _setReadingStatus(
                        selected,
                        bookId: detailedBook.id,
                        isFavorite: isFavorite,
                        title: detailedBook.title,
                        author: detailedBook.author,
                        categories: detailedBook.subjectKeys,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
            onProgressChanged: (value) async {
              final current = userBook?.status ?? ReadingStatus.toRead;
              final completed = value >= 100;
              final status = completed ? ReadingStatus.completed : current;
              try {
                await ref
                    .read(userBookProvider(detailedBook.id).notifier)
                    .upsert(
                      status: status,
                      isFavorite: isFavorite,
                      progress: completed ? null : value,
                      snapshot: _snapshotFor(
                        title: detailedBook.title,
                        author: detailedBook.author,
                        categories: detailedBook.subjectKeys,
                      ),
                    );
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
          ),
        const SizedBox(height: AppSpacing.sm),
        if (isPendingId)
          const AppSkeletonBox(height: 48)
        else
          _RatingSection(
            state: rating,
            selectedRating: selectedRatingForUi,
            onRetry: () => ref.invalidate(ratingProvider(detailedBook.id)),
            onChanged: (value) => setState(() => _selectedRating = value),
            onSubmit: () async {
              try {
                await ref
                    .read(ratingProvider(detailedBook.id).notifier)
                    .submit(_selectedRating);
                _showMessage(l10n.ratingSubmitted);
                if (mounted) {
                  setState(() {
                    _selectedRating = 0;
                    _isEditingRating = false;
                  });
                }
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
            canEdit: !hasUserRated || _isEditingRating,
            hasUserRated: hasUserRated,
            isEditing: _isEditingRating,
            onTapEdit: () {
              if (userRating == null) return;
              setState(() {
                _isEditingRating = true;
                _selectedRating = userRating;
              });
            },
            onCancelEdit: () {
              setState(() {
                _isEditingRating = false;
                _selectedRating = 0;
              });
            },
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          bookDescription.isEmpty
              ? l10n.noDescriptionAvailable
              : bookDescription,
          style: _bookDetailBodyStyle(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.relatedBooks, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        related.when(
          data: (list) {
            if (list.isEmpty) {
              return Text(
                l10n.noRelatedTitlesFound,
                style: _bookDetailBodyStyle(context),
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                itemBuilder: (context, i) {
                  final b = list[i];
                  final u = AppConstants.bookThumbnailUrl(b.coverImageUrl);
                  return SizedBox(
                    width: 110,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BookDetailPage(book: b),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: BookCoverWithFavoriteButton(
                              bookId: b.id,
                              title: b.title,
                              author: b.author,
                              categories: b.subjectKeys,
                              compact: true,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: u != null
                                    ? Image.network(
                                        u,
                                        webHtmlElementStrategy:
                                            WebHtmlElementStrategy.prefer,
                                        width: 110,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                ColoredBox(
                                                  color: Colors.white,
                                                  child: Icon(
                                                    Icons.menu_book_outlined,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                      )
                                    : ColoredBox(
                                        color: Colors.white,
                                        child: Icon(
                                          Icons.menu_book_outlined,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const AppSkeletonBox(height: 4, borderRadius: 2),
          error: (error, stackTrace) => AsyncErrorView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(
              relatedBooksProvider((
                workId: detailedBook.id,
                subjects: detailedBook.subjectKeys,
                author: detailedBook.author,
              )),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isPendingId)
          const AppSkeletonBox(height: 180)
        else
          _ReviewsAndQuotesSection(
            bookId: detailedBook.id,
            tabController: _contentTabController,
            reviews: reviews,
            externalReviews: externalReviews,
            preferExternalReviews: _preferExternalReviews,
            currentUserId: ref.watch(currentUserIdProvider),
            currentUserDisplayName: ref.watch(currentUserDisplayNameProvider),
            onRetryReviews: () =>
                ref.invalidate(reviewListProvider(detailedBook.id)),
            onRetryExternalReviews: () =>
                ref.invalidate(externalReviewProvider(detailedBook.id)),
            onEditReview: (review) async {
              _reviewController.text = review.content;
              final edited =
                  await showDialog<({String content, bool isSpoiler})>(
                    context: context,
                    builder: (dialogContext) => _EditReviewDialog(
                      initialValue: review.content,
                      initialIsSpoiler: review.isSpoiler,
                    ),
                  );
              if (edited == null) return;
              try {
                await ref
                    .read(reviewListProvider(detailedBook.id).notifier)
                    .editReview(
                      review,
                      edited.content,
                      isSpoiler: edited.isSpoiler,
                    );
                _showMessage(l10n.reviewUpdated);
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
            onDeleteReview: (review) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.uxDeleteReviewTitle),
                  content: Text(l10n.uxDeleteReviewMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirm != true || !mounted) return;
              try {
                await ref
                    .read(reviewListProvider(detailedBook.id).notifier)
                    .remove(review);
                _showMessage(l10n.reviewDeleted);
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
            onOpenExternalReview: (url) async {
              final uri = Uri.tryParse(url);
              if (uri == null) {
                _showMessage(l10n.invalidUrl);
                return;
              }
              final ok = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!ok && mounted) {
                _showMessage(l10n.couldNotOpenBrowser);
              }
            },
            onDeleteExternalReview: (review) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.uxDeleteExternalReviewTitle),
                  content: Text(l10n.uxDeleteExternalReviewMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirm != true || !mounted) return;
              try {
                await ref
                    .read(externalReviewProvider(detailedBook.id).notifier)
                    .remove(review);
                _showMessage(l10n.externalReviewDeleted);
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
            quotes: quotes,
            onRetryQuotes: () => ref.invalidate(quoteProvider(detailedBook.id)),
            onLikeQuote: (quoteId) async {
              try {
                await ref
                    .read(quoteProvider(detailedBook.id).notifier)
                    .toggleLike(quoteId);
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
            onLikeReview: (reviewId) async {
              try {
                await ref
                    .read(reviewListProvider(detailedBook.id).notifier)
                    .toggleLike(reviewId);
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
          ),
      ],
    );
  }
}

class _BookDetailCover extends StatefulWidget {
  const _BookDetailCover({required this.url});

  final String url;

  @override
  State<_BookDetailCover> createState() => _BookDetailCoverState();
}

class _BookDetailCoverState extends State<_BookDetailCover> {
  bool? _showCover;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precheckCover();
  }

  @override
  void didUpdateWidget(covariant _BookDetailCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() => _showCover = null);
      _precheckCover();
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _removeListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  void _precheckCover() {
    _removeListener();
    final provider = NetworkImage(widget.url);
    _stream = provider.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, _) async {
        final isPlaceholder = await looksLikePlaceholderCover(info.image);
        if (!mounted) return;
        setState(() => _showCover = !isPlaceholder);
      },
      onError: (_, __) {
        if (!mounted) return;
        setState(() => _showCover = false);
      },
    );
    _stream!.addListener(_listener!);
  }

  @override
  Widget build(BuildContext context) {
    if (_showCover != true) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.network(
            widget.url,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            height: 320,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _ReadingStatusCard extends StatefulWidget {
  const _ReadingStatusCard({
    required this.userBook,
    required this.onTapSelectStatus,
    required this.onProgressChanged,
  });

  final UserBookEntity? userBook;
  final VoidCallback onTapSelectStatus;
  final Future<void> Function(int value) onProgressChanged;

  @override
  State<_ReadingStatusCard> createState() => _ReadingStatusCardState();
}

class _ReadingStatusCardState extends State<_ReadingStatusCard> {
  static const _progressDebounceDuration = Duration(milliseconds: 400);

  Timer? _progressDebounce;
  late int _localProgress;

  @override
  void initState() {
    super.initState();
    _localProgress = widget.userBook?.progress ?? 0;
  }

  @override
  void didUpdateWidget(_ReadingStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_progressDebounce != null) return;
    final next = widget.userBook?.progress ?? 0;
    if (next != _localProgress) {
      _localProgress = next;
    }
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    super.dispose();
  }

  void _persistProgress(int value) {
    _progressDebounce?.cancel();
    _progressDebounce = null;
    unawaited(widget.onProgressChanged(value));
  }

  void _onProgressChanged(int value) {
    setState(() => _localProgress = value);
    _progressDebounce?.cancel();
    _progressDebounce = Timer(_progressDebounceDuration, () {
      _persistProgress(value);
    });
  }

  void _onProgressChangeEnd(int value) {
    _persistProgress(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = widget.userBook?.status;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  status == null ? l10n.addToList : _statusLabel(status, l10n),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onTapSelectStatus,
                  child: Text(l10n.change),
                ),
              ],
            ),
            if (status == ReadingStatus.reading) ...[
              const SizedBox(height: 8),
              Text(
                l10n.progressPercent(_localProgress),
                style: _bookDetailBodyStyle(context),
              ),
              Slider(
                value: _localProgress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$_localProgress%',
                onChanged: (value) => _onProgressChanged(value.round()),
                onChangeEnd: (value) => _onProgressChangeEnd(value.round()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBottomSheet extends StatefulWidget {
  const _StatusBottomSheet({required this.current, required this.onSelect});

  final ReadingStatus? current;
  final Future<void> Function(ReadingStatus status) onSelect;

  @override
  State<_StatusBottomSheet> createState() => _StatusBottomSheetState();
}

class _StatusBottomSheetState extends State<_StatusBottomSheet> {
  bool _selecting = false;

  @override
  Widget build(BuildContext context) {
    final options = <ReadingStatus>[
      ReadingStatus.toRead,
      ReadingStatus.reading,
      ReadingStatus.completed,
      ReadingStatus.dropped,
      ReadingStatus.reReading,
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selecting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: AppLoadingIndicator(size: 24, strokeWidth: 2),
            ),
          ...options.map(
            (status) => ListTile(
              enabled: !_selecting,
              leading: Icon(
                widget.current == status
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(_statusLabel(status, AppLocalizations.of(context)!)),
              onTap: _selecting
                  ? null
                  : () async {
                      setState(() => _selecting = true);
                      try {
                        await widget.onSelect(status);
                      } finally {
                        if (mounted) setState(() => _selecting = false);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(ReadingStatus status, AppLocalizations l10n) {
  switch (status) {
    case ReadingStatus.toRead:
      return l10n.toRead;
    case ReadingStatus.reading:
      return l10n.reading;
    case ReadingStatus.completed:
      return l10n.completed;
    case ReadingStatus.dropped:
      return l10n.dropped;
    case ReadingStatus.reReading:
      return l10n.reReading;
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({
    required this.state,
    required this.selectedRating,
    required this.onRetry,
    required this.onChanged,
    required this.onSubmit,
    required this.canEdit,
    required this.hasUserRated,
    required this.isEditing,
    required this.onTapEdit,
    required this.onCancelEdit,
  });

  final AsyncValue<RatingState> state;
  final int selectedRating;
  final VoidCallback onRetry;
  final ValueChanged<int> onChanged;
  final VoidCallback onSubmit;
  final bool canEdit;
  final bool hasUserRated;
  final bool isEditing;
  final VoidCallback onTapEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.maybeWhen(
      data: (data) => data.submitting,
      orElse: () => false,
    );
    final canChangeStars = canEdit && !isSubmitting;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: _bookDetailBorderColor(context), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.rating,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            state.when(
              data: (data) => Text(
                selectedRating > 0
                    ? '${selectedRating.toDouble().toStringAsFixed(1)} / 10'
                    : '${data.average.toStringAsFixed(1)} / 10',
                style: _bookDetailBodyStyle(context),
              ),
              loading: () => const AppSkeletonBox(height: 4, borderRadius: 2),
              error: (error, stackTrace) =>
                  AsyncErrorView(error: error, compact: true, onRetry: onRetry),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: hasUserRated
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: hasUserRated
                          ? Alignment.centerLeft
                          : Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(
                          5,
                          (index) => GestureDetector(
                            onTapDown: canChangeStars
                                ? (details) {
                                    final dx = details.localPosition.dx;
                                    final isLeftHalf = dx < 14;
                                    final value =
                                        (index * 2) + (isLeftHalf ? 1 : 2);
                                    onChanged(value);
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Builder(
                                builder: (context) {
                                  final icon = _starIconFor(
                                    selectedRating,
                                    index,
                                  );
                                  return Icon(
                                    icon,
                                    color: _bookDetailStarColor(
                                      context,
                                      filled: icon != Icons.star_border,
                                    ),
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasUserRated) ...[
                  IconButton(
                    tooltip: isEditing
                        ? AppLocalizations.of(context)!.submitRating
                        : AppLocalizations.of(context)!.editReview,
                    onPressed: isEditing
                        ? (selectedRating == 0 || isSubmitting
                              ? null
                              : onSubmit)
                        : (isSubmitting ? null : onTapEdit),
                    icon: isSubmitting && isEditing
                        ? const AppLoadingIndicator(
                            size: 18,
                            strokeWidth: 2,
                            centered: false,
                          )
                        : Icon(isEditing ? Icons.check : Icons.edit_outlined),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.cancel,
                      onPressed: isSubmitting ? null : onCancelEdit,
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                ] else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onPressed: selectedRating == 0 || isSubmitting
                        ? null
                        : onSubmit,
                    child: isSubmitting
                        ? const AppLoadingIndicator(
                            size: 18,
                            strokeWidth: 2,
                            centered: false,
                          )
                        : Text(AppLocalizations.of(context)!.submitRating),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _starIconFor(int selectedRating, int index) {
  final value = selectedRating - (index * 2);
  if (value >= 2) return Icons.star;
  if (value == 1) return Icons.star_half;
  return Icons.star_border;
}

class _ReviewsAndQuotesSection extends StatelessWidget {
  const _ReviewsAndQuotesSection({
    required this.bookId,
    required this.tabController,
    required this.reviews,
    required this.externalReviews,
    required this.preferExternalReviews,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.onRetryReviews,
    required this.onRetryExternalReviews,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onOpenExternalReview,
    required this.onDeleteExternalReview,
    required this.quotes,
    required this.onRetryQuotes,
    required this.onLikeQuote,
    required this.onLikeReview,
  });

  final String bookId;
  final TabController tabController;
  final AsyncValue<List<ReviewEntity>> reviews;
  final AsyncValue<List<ExternalReviewEntity>> externalReviews;
  final bool preferExternalReviews;
  final String? currentUserId;
  final String currentUserDisplayName;
  final VoidCallback onRetryReviews;
  final VoidCallback onRetryExternalReviews;
  final Future<void> Function(ReviewEntity review) onEditReview;
  final Future<void> Function(ReviewEntity review) onDeleteReview;
  final Future<void> Function(String url) onOpenExternalReview;
  final Future<void> Function(ExternalReviewEntity review)
  onDeleteExternalReview;
  final AsyncValue<List<QuoteEntity>> quotes;
  final VoidCallback onRetryQuotes;
  final Future<void> Function(String quoteId) onLikeQuote;
  final Future<void> Function(String reviewId) onLikeReview;

  static const _tabPanelHeight = 480.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: tabController,
          tabAlignment: TabAlignment.fill,
          tabs: [
            Tab(text: l10n.reviews),
            Tab(text: l10n.notes),
            Tab(text: l10n.quotes),
          ],
        ),
        SizedBox(
          height: _tabPanelHeight,
          child: TabBarView(
            controller: tabController,
            children: [
              _ReviewSection(
                reviews: reviews,
                externalReviews: externalReviews,
                preferExternalReviews: preferExternalReviews,
                currentUserId: currentUserId,
                currentUserDisplayName: currentUserDisplayName,
                onRetryReviews: onRetryReviews,
                onRetryExternalReviews: onRetryExternalReviews,
                onEditReview: onEditReview,
                onDeleteReview: onDeleteReview,
                onOpenExternalReview: onOpenExternalReview,
                onDeleteExternalReview: onDeleteExternalReview,
                onLikeReview: onLikeReview,
              ),
              BookNotesTab(bookId: bookId),
              _QuoteSection(
                quotes: quotes,
                currentUserId: currentUserId,
                currentUserDisplayName: currentUserDisplayName,
                onRetryQuotes: onRetryQuotes,
                onLikeQuote: onLikeQuote,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSection extends StatefulWidget {
  const _ReviewSection({
    required this.reviews,
    required this.externalReviews,
    required this.preferExternalReviews,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.onRetryReviews,
    required this.onRetryExternalReviews,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onOpenExternalReview,
    required this.onDeleteExternalReview,
    required this.onLikeReview,
  });

  final AsyncValue<List<ReviewEntity>> reviews;
  final AsyncValue<List<ExternalReviewEntity>> externalReviews;
  final bool preferExternalReviews;
  final String? currentUserId;
  final String currentUserDisplayName;
  final VoidCallback onRetryReviews;
  final VoidCallback onRetryExternalReviews;
  final Future<void> Function(ReviewEntity review) onEditReview;
  final Future<void> Function(ReviewEntity review) onDeleteReview;
  final Future<void> Function(String url) onOpenExternalReview;
  final Future<void> Function(ExternalReviewEntity review)
  onDeleteExternalReview;
  final Future<void> Function(String reviewId) onLikeReview;

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  late var _showExternal = widget.preferExternalReviews;
  var _hideSpoilers = false;

  @override
  void didUpdateWidget(covariant _ReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preferExternalReviews && !oldWidget.preferExternalReviews) {
      _showExternal = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showExternal = false),
                  child: Text(
                    l10n.userReviews,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _showExternal ? cs.onSurfaceVariant : cs.primary,
                      fontWeight: _showExternal
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: AppToggleSwitch(
                  value: _showExternal,
                  onChanged: (value) => setState(() => _showExternal = value),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showExternal = true),
                  child: Text(
                    l10n.externalReviews,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _showExternal ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: _showExternal
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_showExternal)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: _CompactCheckbox(
              label: l10n.hideSpoilers,
              value: _hideSpoilers,
              labelStyle: Theme.of(context).textTheme.labelMedium,
              onChanged: (value) => setState(() => _hideSpoilers = value),
            ),
          ),
        Expanded(
          child: _showExternal
              ? widget.externalReviews.when(
                  data: (list) => list.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noExternalReviewsYet,
                            style: _bookDetailBodyStyle(context),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.sm,
                            0,
                            AppSpacing.sm,
                            AppSpacing.md,
                          ),
                          itemCount: list.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final own = item.userId == widget.currentUserId;
                            return _ExternalReviewCard(
                              review: item,
                              userName: _externalReviewDisplayName(
                                item,
                                own: own,
                                currentUserDisplayName:
                                    widget.currentUserDisplayName,
                              ),
                              own: own,
                              onOpen: () =>
                                  widget.onOpenExternalReview(item.url),
                              onDelete: () =>
                                  widget.onDeleteExternalReview(item),
                            );
                          },
                        ),
                  loading: () => const AppLoadingIndicator(),
                  error: (error, stackTrace) => AsyncErrorView(
                    error: error,
                    compact: true,
                    onRetry: widget.onRetryExternalReviews,
                  ),
                )
              : widget.reviews.when(
                  data: (list) {
                    final filtered = _hideSpoilers
                        ? list.where((r) => !r.isSpoiler).toList()
                        : list;
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noUserReviewsYet,
                          style: _bookDetailBodyStyle(context),
                        ),
                      );
                    }
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.noReviewsAfterSpoilerFilter,
                          textAlign: TextAlign.center,
                          style: _bookDetailBodyStyle(context),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.md,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final own = item.userId == widget.currentUserId;
                        return _ReviewCard(
                          review: item,
                          userName: _reviewDisplayName(
                            item,
                            own: own,
                            currentUserDisplayName:
                                widget.currentUserDisplayName,
                          ),
                          own: own,
                          onLike: () => widget.onLikeReview(item.id),
                          onEdit: () => widget.onEditReview(item),
                          onDelete: () => widget.onDeleteReview(item),
                        );
                      },
                    );
                  },
                  loading: () => const AppLoadingIndicator(),
                  error: (error, stackTrace) => AsyncErrorView(
                    error: error,
                    compact: true,
                    onRetry: widget.onRetryReviews,
                  ),
                ),
        ),
      ],
    );
  }
}

class _QuoteSection extends StatelessWidget {
  const _QuoteSection({
    required this.quotes,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.onRetryQuotes,
    required this.onLikeQuote,
  });

  final AsyncValue<List<QuoteEntity>> quotes;
  final String? currentUserId;
  final String currentUserDisplayName;
  final VoidCallback onRetryQuotes;
  final Future<void> Function(String quoteId) onLikeQuote;

  @override
  Widget build(BuildContext context) {
    return quotes.when(
      data: (list) => list.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noQuotesYet,
                style: _bookDetailBodyStyle(context),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              itemCount: list.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = list[index];
                final own = item.userId == currentUserId;
                return _QuoteCard(
                  quote: item,
                  userName: _quoteDisplayName(
                    item,
                    own: own,
                    currentUserDisplayName: currentUserDisplayName,
                  ),
                  onLike: () => onLikeQuote(item.id),
                );
              },
            ),
      loading: () => const AppLoadingIndicator(),
      error: (error, stackTrace) =>
          AsyncErrorView(error: error, compact: true, onRetry: onRetryQuotes),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({
    required this.review,
    required this.userName,
    required this.own,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  final ReviewEntity review;
  final String userName;
  final bool own;
  final Future<void> Function() onLike;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _actionBusy = false;
  bool _spoilerRevealed = false;

  @override
  void didUpdateWidget(covariant _ReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review.id != widget.review.id ||
        oldWidget.review.isSpoiler != widget.review.isSpoiler) {
      _spoilerRevealed = false;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final review = widget.review;
    final hideContent = review.isSpoiler && !widget.own && !_spoilerRevealed;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.28)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.userName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (review.isSpoiler) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.spoilerBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (review.userRating != null)
                  _ReadOnlyStarRating(rating: review.userRating!),
                if (review.isFavorite) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.favorite, color: cs.primary, size: 16),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (hideContent)
              InkWell(
                onTap: () => setState(() => _spoilerRevealed = true),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.showSpoiler,
                    textAlign: TextAlign.center,
                    style: _bookDetailBodyStyle(context).copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Text(
                review.content,
                textAlign: TextAlign.start,
                style: _bookDetailBodyStyle(context).copyWith(height: 1.42),
              ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ContentLikeButton(
                  liked: review.likedByCurrentUser,
                  likes: review.likes,
                  onPressed: widget.onLike,
                ),
                if (widget.own) ...[
                  IconButton(
                    tooltip: l10n.editReview,
                    onPressed: _actionBusy ? null : () => _run(widget.onEdit),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    onPressed: _actionBusy ? null : () => _run(widget.onDelete),
                    icon: _actionBusy
                        ? const AppLoadingIndicator(
                            size: 16,
                            strokeWidth: 2,
                            centered: false,
                          )
                        : const Icon(Icons.delete_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  formatRelativeTime(review.createdAt, l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalReviewCard extends StatefulWidget {
  const _ExternalReviewCard({
    required this.review,
    required this.userName,
    required this.own,
    required this.onOpen,
    required this.onDelete,
  });

  final ExternalReviewEntity review;
  final String userName;
  final bool own;
  final Future<void> Function() onOpen;
  final Future<void> Function() onDelete;

  @override
  State<_ExternalReviewCard> createState() => _ExternalReviewCardState();
}

class _ExternalReviewCardState extends State<_ExternalReviewCard> {
  bool _actionBusy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final review = widget.review;
    final host = _externalReviewHost(review.url);
    final description = review.description.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _run(widget.onOpen),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(color: cs.outline.withValues(alpha: 0.28)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize:
                                  (theme.textTheme.labelSmall?.fontSize ?? 11) -
                                  1,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            review.title,
                            textAlign: TextAlign.start,
                            style: _bookDetailBodyStyle(context).copyWith(
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.own)
                      IconButton(
                        tooltip: l10n.delete,
                        onPressed: _actionBusy
                            ? null
                            : () => _run(widget.onDelete),
                        icon: _actionBusy
                            ? const AppLoadingIndicator(
                                size: 16,
                                strokeWidth: 2,
                                centered: false,
                              )
                            : const Icon(Icons.delete_outline, size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    textAlign: TextAlign.start,
                    style: _bookDetailBodyStyle(context).copyWith(height: 1.42),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        host,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.userName,
    required this.onLike,
  });

  final QuoteEntity quote;
  final String userName;
  final Future<void> Function() onLike;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.28)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              userName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              quote.content,
              textAlign: TextAlign.start,
              style: _bookDetailBodyStyle(
                context,
              ).copyWith(height: 1.42, fontStyle: FontStyle.italic),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ContentLikeButton(
                    liked: quote.likedByCurrentUser,
                    likes: quote.likes,
                    onPressed: onLike,
                  ),
                  const Spacer(),
                  Text(
                    formatRelativeTime(quote.createdAt, l10n),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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

class _ContentLikeButton extends StatefulWidget {
  const _ContentLikeButton({
    required this.liked,
    required this.likes,
    required this.onPressed,
  });

  final bool liked;
  final int likes;
  final Future<void> Function() onPressed;

  @override
  State<_ContentLikeButton> createState() => _ContentLikeButtonState();
}

class _ContentLikeButtonState extends State<_ContentLikeButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                await widget.onPressed();
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      style: TextButton.styleFrom(
        foregroundColor: widget.liked ? cs.primary : null,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: _busy
          ? const AppLoadingIndicator(size: 16, strokeWidth: 2, centered: false)
          : Icon(
              widget.liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
            ),
      label: Text(widget.likes.toString()),
    );
  }
}

String _externalReviewHost(String url) {
  final uri = Uri.tryParse(url);
  final host = uri?.host.trim();
  if (host != null && host.isNotEmpty) {
    return host.startsWith('www.') ? host.substring(4) : host;
  }
  return url;
}

String _externalReviewDisplayName(
  ExternalReviewEntity review, {
  required bool own,
  required String currentUserDisplayName,
}) {
  final stored = review.userName?.trim();
  if (stored != null && stored.isNotEmpty) return stored;
  if (own) return currentUserDisplayName;
  return 'user';
}

String _quoteDisplayName(
  QuoteEntity quote, {
  required bool own,
  required String currentUserDisplayName,
}) {
  final stored = quote.userName?.trim();
  if (stored != null && stored.isNotEmpty) return stored;
  if (own) return currentUserDisplayName;
  return 'user';
}

String _reviewDisplayName(
  ReviewEntity review, {
  required bool own,
  required String currentUserDisplayName,
}) {
  final stored = review.userName?.trim();
  if (stored != null && stored.isNotEmpty) return stored;
  if (own) return currentUserDisplayName;
  return 'user';
}

class _ReadOnlyStarRating extends StatelessWidget {
  const _ReadOnlyStarRating({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (index) {
        final icon = _starIconFor(rating, index);
        return Icon(
          icon,
          color: _bookDetailStarColor(
            context,
            filled: icon != Icons.star_border,
          ),
          size: 18,
        );
      }),
    );
  }
}

class _AddContentBottomSheet extends StatefulWidget {
  const _AddContentBottomSheet({
    required this.initialTabIndex,
    required this.reviewController,
    required this.externalTitleController,
    required this.externalUrlController,
    required this.externalDescriptionController,
    required this.quoteController,
    required this.noteTitleController,
    required this.noteContentController,
    required this.notePageController,
    required this.noteChapterController,
    required this.noteTagsController,
    required this.onAddReview,
    required this.onAddExternalReview,
    required this.onAddQuote,
    required this.onAddNote,
  });

  final int initialTabIndex;
  final TextEditingController reviewController;
  final TextEditingController externalTitleController;
  final TextEditingController externalUrlController;
  final TextEditingController externalDescriptionController;
  final TextEditingController quoteController;
  final TextEditingController noteTitleController;
  final TextEditingController noteContentController;
  final TextEditingController notePageController;
  final TextEditingController noteChapterController;
  final TextEditingController noteTagsController;
  final Future<void> Function(bool isSpoiler) onAddReview;
  final Future<void> Function() onAddExternalReview;
  final Future<void> Function() onAddQuote;
  final Future<void> Function({required bool isPublic}) onAddNote;

  @override
  State<_AddContentBottomSheet> createState() => _AddContentBottomSheetState();
}

class _AddContentBottomSheetState extends State<_AddContentBottomSheet> {
  var _showExternalReview = false;
  var _isPublicNote = false;
  var _isSpoilerReview = false;
  var _submitting = false;

  Future<void> _runSubmit(Future<void> Function() action) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
      child: Column(
        children: [
          TabBar(
            tabAlignment: TabAlignment.fill,
            tabs: [
              Tab(text: l10n.reviews),
              Tab(text: l10n.notes),
              Tab(text: l10n.quotes),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AddReviewTab(
                  showExternalReview: _showExternalReview,
                  onExternalReviewChanged: _submitting
                      ? null
                      : (value) => setState(() => _showExternalReview = value),
                  reviewController: widget.reviewController,
                  externalTitleController: widget.externalTitleController,
                  externalUrlController: widget.externalUrlController,
                  externalDescriptionController:
                      widget.externalDescriptionController,
                  isSpoiler: _isSpoilerReview,
                  onSpoilerChanged: _submitting
                      ? null
                      : (value) => setState(() => _isSpoilerReview = value),
                  submitting: _submitting,
                  onAddReview: () =>
                      _runSubmit(() => widget.onAddReview(_isSpoilerReview)),
                  onAddExternalReview: () =>
                      _runSubmit(widget.onAddExternalReview),
                  colorScheme: cs,
                ),
                _AddNoteTab(
                  noteTitleController: widget.noteTitleController,
                  noteContentController: widget.noteContentController,
                  notePageController: widget.notePageController,
                  noteChapterController: widget.noteChapterController,
                  noteTagsController: widget.noteTagsController,
                  isPublic: _isPublicNote,
                  onPublicChanged: _submitting
                      ? null
                      : (value) => setState(() => _isPublicNote = value),
                  submitting: _submitting,
                  onAddNote: () => _runSubmit(
                    () => widget.onAddNote(isPublic: _isPublicNote),
                  ),
                ),
                _AddQuoteTab(
                  quoteController: widget.quoteController,
                  submitting: _submitting,
                  onAddQuote: () => _runSubmit(widget.onAddQuote),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddReviewTab extends StatelessWidget {
  const _AddReviewTab({
    required this.showExternalReview,
    required this.onExternalReviewChanged,
    required this.reviewController,
    required this.externalTitleController,
    required this.externalUrlController,
    required this.externalDescriptionController,
    required this.isSpoiler,
    required this.onSpoilerChanged,
    required this.submitting,
    required this.onAddReview,
    required this.onAddExternalReview,
    required this.colorScheme,
  });

  final bool showExternalReview;
  final ValueChanged<bool>? onExternalReviewChanged;
  final TextEditingController reviewController;
  final TextEditingController externalTitleController;
  final TextEditingController externalUrlController;
  final TextEditingController externalDescriptionController;
  final bool isSpoiler;
  final ValueChanged<bool>? onSpoilerChanged;
  final bool submitting;
  final VoidCallback onAddReview;
  final VoidCallback onAddExternalReview;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onExternalReviewChanged == null
                      ? null
                      : () => onExternalReviewChanged!(false),
                  child: Text(
                    l10n.userReviews,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: showExternalReview
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.primary,
                      fontWeight: showExternalReview
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: AppToggleSwitch(
                  value: showExternalReview,
                  onChanged: onExternalReviewChanged,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onExternalReviewChanged == null
                      ? null
                      : () => onExternalReviewChanged!(true),
                  child: Text(
                    l10n.externalReviews,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: showExternalReview
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: showExternalReview
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: showExternalReview
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: externalTitleController,
                          enabled: !submitting,
                          style: _bookDetailInputStyle(context),
                          decoration: InputDecoration(
                            hintText: l10n.reviewTitle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: externalDescriptionController,
                          enabled: !submitting,
                          minLines: 2,
                          maxLines: 4,
                          style: _bookDetailInputStyle(context),
                          decoration: InputDecoration(
                            hintText: l10n.description,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: externalUrlController,
                          enabled: !submitting,
                          style: _bookDetailInputStyle(context),
                          decoration: InputDecoration(
                            hintText: l10n.reviewUrlHint,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: reviewController,
                          enabled: !submitting,
                          minLines: 2,
                          maxLines: 6,
                          style: _bookDetailInputStyle(context),
                          decoration: InputDecoration(
                            hintText: l10n.writeReviewHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _CompactCheckbox(
                          label: l10n.containsSpoilers,
                          value: isSpoiler,
                          onChanged: onSpoilerChanged,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: submitting
                ? null
                : (showExternalReview ? onAddExternalReview : onAddReview),
            child: submitting
                ? const AppLoadingIndicator(
                    size: 18,
                    strokeWidth: 2,
                    centered: false,
                  )
                : Text(
                    showExternalReview
                        ? l10n.addExternalReview
                        : l10n.addReview,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddNoteTab extends StatelessWidget {
  const _AddNoteTab({
    required this.noteTitleController,
    required this.noteContentController,
    required this.notePageController,
    required this.noteChapterController,
    required this.noteTagsController,
    required this.isPublic,
    required this.onPublicChanged,
    required this.submitting,
    required this.onAddNote,
  });

  final TextEditingController noteTitleController;
  final TextEditingController noteContentController;
  final TextEditingController notePageController;
  final TextEditingController noteChapterController;
  final TextEditingController noteTagsController;
  final bool isPublic;
  final ValueChanged<bool>? onPublicChanged;
  final bool submitting;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AbsorbPointer(
                absorbing: submitting,
                child: BookNoteFormFields(
                  titleController: noteTitleController,
                  contentController: noteContentController,
                  pageController: notePageController,
                  chapterController: noteChapterController,
                  tagsController: noteTagsController,
                  isPublic: isPublic,
                  onPublicChanged: onPublicChanged ?? (_) {},
                  inputStyle: _bookDetailInputStyle(context),
                  contentMaxLines: 4,
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: submitting ? null : onAddNote,
            child: submitting
                ? const AppLoadingIndicator(
                    size: 18,
                    strokeWidth: 2,
                    centered: false,
                  )
                : Text(l10n.addNote),
          ),
        ],
      ),
    );
  }
}

class _AddQuoteTab extends StatelessWidget {
  const _AddQuoteTab({
    required this.quoteController,
    required this.submitting,
    required this.onAddQuote,
  });

  final TextEditingController quoteController;
  final bool submitting;
  final VoidCallback onAddQuote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: TextField(
                controller: quoteController,
                enabled: !submitting,
                minLines: 2,
                maxLines: 6,
                style: _bookDetailInputStyle(context),
                decoration: InputDecoration(hintText: l10n.addMemorableQuote),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: submitting ? null : onAddQuote,
            child: submitting
                ? const AppLoadingIndicator(
                    size: 18,
                    strokeWidth: 2,
                    centered: false,
                  )
                : Text(l10n.addQuote),
          ),
        ],
      ),
    );
  }
}

class _EditReviewDialog extends StatefulWidget {
  const _EditReviewDialog({
    required this.initialValue,
    this.initialIsSpoiler = false,
  });

  final String initialValue;
  final bool initialIsSpoiler;

  @override
  State<_EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<_EditReviewDialog> {
  late final TextEditingController _controller;
  late bool _isSpoiler;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _isSpoiler = widget.initialIsSpoiler;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.editReview),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 5,
            style: _bookDetailInputStyle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompactCheckbox(
            label: l10n.containsSpoilers,
            value: _isSpoiler,
            onChanged: (value) => setState(() => _isSpoiler = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((content: _controller.text.trim(), isSpoiler: _isSpoiler)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _CompactCheckbox extends StatelessWidget {
  const _CompactCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    this.labelStyle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (v) => onChanged!(v ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: labelStyle ?? Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
