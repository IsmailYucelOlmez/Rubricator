import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/book_cover_utils.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../user_books/domain/entities/user_book_entity.dart';
import '../../../user_books/domain/entities/user_book_snapshot.dart';
import '../../../user_books/presentation/providers/user_books_provider.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../providers/books_providers.dart';
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

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  final _reviewController = TextEditingController();
  final _externalTitleController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _quoteController = TextEditingController();
  // Rating is stored on a 1-10 scale (half-star steps on a 5-star UI).
  int _selectedRating = 0;
  bool _isEditingRating = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _externalTitleController.dispose();
    _externalUrlController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    required bool isFavorite,
    required String title,
    required String author,
    required List<String> categories,
  }) async {
    await ref.read(userBookProvider(widget.book.id).notifier).upsert(
          status: selected,
          isFavorite: isFavorite,
          snapshot: selected == ReadingStatus.completed
              ? _snapshotFor(
                  title: title,
                  author: author,
                  categories: categories,
                )
              : null,
        );
  }

  void _feedbackError(Object e) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final s = e.toString().toLowerCase();
    if (s.contains('sign in required') || s.contains('sign in to')) {
      _showMessage(l10n.uxMustSignIn);
      return;
    }
    if (s.contains('10 characters')) {
      _showMessage(l10n.uxReviewMinLength);
      return;
    }
    AppFeedback.showErrorSnackBar(context, e);
  }

  Future<void> _showAddContentSheet(
    BuildContext context, {
    required String bookId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SafeArea(
            top: false,
            child: _AddContentBottomSheet(
              reviewController: _reviewController,
              externalTitleController: _externalTitleController,
              externalUrlController: _externalUrlController,
              quoteController: _quoteController,
              onAddReview: () async {
                try {
                  await ref
                      .read(reviewListProvider(bookId).notifier)
                      .add(_reviewController.text);
                  _reviewController.clear();
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (!mounted) return;
                  _showMessage(l10n.reviewAdded);
                } catch (e) {
                  if (!mounted) return;
                  _feedbackError(e);
                }
              },
              onAddExternalReview: () async {
                try {
                  await ref
                      .read(externalReviewProvider(bookId).notifier)
                      .add(
                        title: _externalTitleController.text,
                        url: _externalUrlController.text,
                      );
                  _externalTitleController.clear();
                  _externalUrlController.clear();
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (!mounted) return;
                  _showMessage(l10n.externalReviewAdded);
                } catch (e) {
                  if (!mounted) return;
                  _feedbackError(e);
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
                  if (!mounted) return;
                  _feedbackError(e);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailedBookAsync = ref.watch(bookDetailProvider(widget.book));
    final detailedBook = detailedBookAsync.valueOrNull;
    final userBookAsync = ref.watch(userBookProvider(widget.book.id));
    final userBook = userBookAsync.valueOrNull;
    final isFavorite = userBook?.isFavorite ?? false;
    final status = userBook?.status;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookDetails),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => _StatusBottomSheet(
                    current: status,
                    onSelect: (selected) async {
                      await _setReadingStatus(
                        selected,
                        isFavorite: isFavorite,
                        title: widget.book.title,
                        author: widget.book.author,
                        categories: widget.book.subjectKeys,
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
            onPressed: () async {
              try {
                await ref
                    .read(userBookProvider(widget.book.id).notifier)
                    .toggleFavorite();
              } catch (e) {
                if (!mounted) return;
                _feedbackError(e);
              }
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
          ),
        ],
      ),
      floatingActionButton: detailedBook != null
          ? FloatingActionButton(
              onPressed: () => _showAddContentSheet(
                context,
                bookId: detailedBook.id,
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: ResponsiveScaffoldBody(
        child: detailedBookAsync.when(
            data: (detailedBook) {
          final reviews = ref.watch(reviewListProvider(detailedBook.id));
          final externalReviews = ref.watch(
            externalReviewProvider(detailedBook.id),
          );
          final quotes = ref.watch(quoteProvider(detailedBook.id));
          final rating = ref.watch(ratingProvider(detailedBook.id));
          final hasUserRated = rating.valueOrNull?.userRating != null;
          final userRating = rating.valueOrNull?.userRating;
          final selectedRatingForUi = _selectedRating > 0
              ? _selectedRating
              : (userRating ?? 0);
          final coverUrl = AppConstants.bookDetailCoverUrl(
            detailedBook.coverImageUrl,
          );
          final related = ref.watch(
            relatedBooksProvider((
              workId: detailedBook.id,
              subjects: detailedBook.subjectKeys,
              author: detailedBook.author,
            )),
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md +
                  72 +
                  MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (coverUrl != null) _BookDetailCover(url: coverUrl),
              Text(
                detailedBook.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              if (detailedBook.authorIds.isNotEmpty)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AuthorDetailPage(
                          authorId: detailedBook.authorIds.first,
                        ),
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
                  final status =
                      completed ? ReadingStatus.completed : current;
                  try {
                    await ref
                        .read(userBookProvider(widget.book.id).notifier)
                        .upsert(
                          status: status,
                          isFavorite: isFavorite,
                          progress: completed ? null : value,
                          snapshot: completed
                              ? _snapshotFor(
                                  title: detailedBook.title,
                                  author: detailedBook.author,
                                  categories: detailedBook.subjectKeys,
                                )
                              : null,
                        );
                  } catch (e) {
                    if (!mounted) return;
                    _feedbackError(e);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
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
                detailedBook.description.isEmpty
                    ? l10n.noDescriptionAvailable
                    : detailedBook.description,
                style: _bookDetailBodyStyle(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.relatedBooks,
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                        final u = AppConstants.bookThumbnailUrl(
                          b.coverImageUrl,
                        );
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
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => ColoredBox(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    child: Icon(
                                                      Icons.menu_book_outlined,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                            )
                                          : ColoredBox(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
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
              _ReviewsAndQuotesSection(
                reviews: reviews,
                externalReviews: externalReviews,
                currentUserId: ref.watch(currentUserIdProvider),
                onRetryReviews: () => ref.invalidate(reviewListProvider(detailedBook.id)),
                onRetryExternalReviews: () =>
                    ref.invalidate(externalReviewProvider(detailedBook.id)),
                onEditReview: (review) async {
                  _reviewController.text = review.content;
                  final edited = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) =>
                        _EditReviewDialog(initialValue: review.content),
                  );
                  if (edited == null) return;
                  try {
                    await ref
                        .read(reviewListProvider(detailedBook.id).notifier)
                        .editReview(review, edited);
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
                quotes: quotes,
                onRetryQuotes: () => ref.invalidate(quoteProvider(detailedBook.id)),
                onLikeQuote: (quoteId) async {
                  try {
                    await ref
                        .read(quoteProvider(detailedBook.id).notifier)
                        .like(quoteId);
                  } catch (e) {
                    if (!mounted) return;
                    _feedbackError(e);
                  }
                },
              ),
            ],
          );
        },
            loading: () => const AppLoadingIndicator(),
            error: (error, stackTrace) => AsyncErrorView(
              error: error,
              onRetry: () => ref.invalidate(bookDetailProvider(widget.book)),
            ),
          ),
        ),
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

class _ReadingStatusCard extends StatelessWidget {
  const _ReadingStatusCard({
    required this.userBook,
    required this.onTapSelectStatus,
    required this.onProgressChanged,
  });

  final UserBookEntity? userBook;
  final VoidCallback onTapSelectStatus;
  final Future<void> Function(int value) onProgressChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = userBook?.status;
    final progress = userBook?.progress ?? 0;
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
                  onPressed: onTapSelectStatus,
                  child: Text(l10n.change),
                ),
              ],
            ),
            if (status == ReadingStatus.reading) ...[
              const SizedBox(height: 8),
              Text(
                l10n.progressPercent(progress),
                style: _bookDetailBodyStyle(context),
              ),
              Slider(
                value: progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '$progress%',
                onChanged: (value) => onProgressChanged(value.round()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBottomSheet extends StatelessWidget {
  const _StatusBottomSheet({required this.current, required this.onSelect});

  final ReadingStatus? current;
  final Future<void> Function(ReadingStatus status) onSelect;

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
        children: options
            .map(
              (status) => ListTile(
                leading: Icon(
                  current == status
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(
                  _statusLabel(status, AppLocalizations.of(context)!),
                ),
                onTap: () => onSelect(status),
              ),
            )
            .toList(),
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
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
              error: (error, stackTrace) => AsyncErrorView(
                    error: error,
                    compact: true,
                    onRetry: onRetry,
                  ),
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
                            onTapDown: canEdit
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
                                  final icon =
                                      _starIconFor(selectedRating, index);
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
                        ? (selectedRating == 0 ? null : onSubmit)
                        : onTapEdit,
                    icon: Icon(isEditing ? Icons.check : Icons.edit_outlined),
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
                      onPressed: onCancelEdit,
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                ],
              ],
            ),
            if (!hasUserRated) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onPressed: selectedRating == 0 ? null : onSubmit,
                  child: Text(AppLocalizations.of(context)!.submitRating),
                ),
              ),
            ],
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
    required this.reviews,
    required this.externalReviews,
    required this.currentUserId,
    required this.onRetryReviews,
    required this.onRetryExternalReviews,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onOpenExternalReview,
    required this.quotes,
    required this.onRetryQuotes,
    required this.onLikeQuote,
  });

  final AsyncValue<List<ReviewEntity>> reviews;
  final AsyncValue<List<ExternalReviewEntity>> externalReviews;
  final String? currentUserId;
  final VoidCallback onRetryReviews;
  final VoidCallback onRetryExternalReviews;
  final Future<void> Function(ReviewEntity review) onEditReview;
  final Future<void> Function(ReviewEntity review) onDeleteReview;
  final Future<void> Function(String url) onOpenExternalReview;
  final AsyncValue<List<QuoteEntity>> quotes;
  final VoidCallback onRetryQuotes;
  final Future<void> Function(String quoteId) onLikeQuote;

  static const _tabPanelHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.reviews),
              Tab(text: l10n.quotes),
            ],
          ),
          SizedBox(
            height: _tabPanelHeight,
            child: TabBarView(
              children: [
                _ReviewSection(
                  reviews: reviews,
                  externalReviews: externalReviews,
                  currentUserId: currentUserId,
                  onRetryReviews: onRetryReviews,
                  onRetryExternalReviews: onRetryExternalReviews,
                  onEditReview: onEditReview,
                  onDeleteReview: onDeleteReview,
                  onOpenExternalReview: onOpenExternalReview,
                ),
                _QuoteSection(
                  quotes: quotes,
                  onRetryQuotes: onRetryQuotes,
                  onLikeQuote: onLikeQuote,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatefulWidget {
  const _ReviewSection({
    required this.reviews,
    required this.externalReviews,
    required this.currentUserId,
    required this.onRetryReviews,
    required this.onRetryExternalReviews,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onOpenExternalReview,
  });

  final AsyncValue<List<ReviewEntity>> reviews;
  final AsyncValue<List<ExternalReviewEntity>> externalReviews;
  final String? currentUserId;
  final VoidCallback onRetryReviews;
  final VoidCallback onRetryExternalReviews;
  final Future<void> Function(ReviewEntity review) onEditReview;
  final Future<void> Function(ReviewEntity review) onDeleteReview;
  final Future<void> Function(String url) onOpenExternalReview;

  @override
  State<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<_ReviewSection> {
  var _showExternal = false;

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
                child: Text(
                  l10n.userReviews,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _showExternal ? cs.onSurfaceVariant : cs.primary,
                    fontWeight:
                        _showExternal ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _showExternal,
                onChanged: (value) => setState(() => _showExternal = value),
              ),
              Expanded(
                child: Text(
                  l10n.externalReviews,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _showExternal ? cs.primary : cs.onSurfaceVariant,
                    fontWeight:
                        _showExternal ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
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
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return ListTile(
                              title: Text(
                                item.title,
                                style: _bookDetailBodyStyle(context),
                              ),
                              subtitle: Text(
                                item.url,
                                style: _bookDetailBodyStyle(context),
                              ),
                              trailing: IconButton(
                                onPressed: () =>
                                    widget.onOpenExternalReview(item.url),
                                icon: const Icon(Icons.open_in_new),
                              ),
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
                  data: (list) => list.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noUserReviewsYet,
                            style: _bookDetailBodyStyle(context),
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final own = item.userId == widget.currentUserId;
                            return ListTile(
                              title: Text(
                                item.content,
                                style: _bookDetailBodyStyle(context),
                              ),
                              subtitle: Text(
                                item.createdAt.toLocal().toString(),
                                style: _bookDetailBodyStyle(context),
                              ),
                              trailing: own
                                  ? Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              widget.onEditReview(item),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              widget.onDeleteReview(item),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          },
                        ),
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
    required this.onRetryQuotes,
    required this.onLikeQuote,
  });

  final AsyncValue<List<QuoteEntity>> quotes;
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
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return ListTile(
                  title: Text(
                    item.content,
                    style: _bookDetailBodyStyle(context),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => onLikeQuote(item.id),
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: Text(item.likes.toString()),
                  ),
                );
              },
            ),
      loading: () => const AppLoadingIndicator(),
      error: (error, stackTrace) => AsyncErrorView(
            error: error,
            compact: true,
            onRetry: onRetryQuotes,
          ),
    );
  }
}

class _AddContentBottomSheet extends StatefulWidget {
  const _AddContentBottomSheet({
    required this.reviewController,
    required this.externalTitleController,
    required this.externalUrlController,
    required this.quoteController,
    required this.onAddReview,
    required this.onAddExternalReview,
    required this.onAddQuote,
  });

  final TextEditingController reviewController;
  final TextEditingController externalTitleController;
  final TextEditingController externalUrlController;
  final TextEditingController quoteController;
  final Future<void> Function() onAddReview;
  final Future<void> Function() onAddExternalReview;
  final Future<void> Function() onAddQuote;

  @override
  State<_AddContentBottomSheet> createState() => _AddContentBottomSheetState();
}

class _AddContentBottomSheetState extends State<_AddContentBottomSheet> {
  var _showExternalReview = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final panelHeight = (MediaQuery.sizeOf(context).height * 0.38).clamp(
      260.0,
      320.0,
    );

    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              Tab(text: l10n.reviews),
              Tab(text: l10n.quotes),
            ],
          ),
          SizedBox(
            height: panelHeight,
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.userReviews,
                              textAlign: TextAlign.end,
                              style:
                                  Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: _showExternalReview
                                    ? cs.onSurfaceVariant
                                    : cs.primary,
                                fontWeight: _showExternalReview
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _showExternalReview,
                            onChanged: (value) =>
                                setState(() => _showExternalReview = value),
                          ),
                          Expanded(
                            child: Text(
                              l10n.externalReviews,
                              style:
                                  Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: _showExternalReview
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                fontWeight: _showExternalReview
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: _showExternalReview
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller:
                                        widget.externalTitleController,
                                    style: _bookDetailInputStyle(context),
                                    decoration: InputDecoration(
                                      hintText: l10n.reviewTitle,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  TextField(
                                    controller: widget.externalUrlController,
                                    style: _bookDetailInputStyle(context),
                                    decoration: InputDecoration(
                                      hintText: l10n.reviewUrlHint,
                                    ),
                                  ),
                                  const Spacer(),
                                  FilledButton(
                                    onPressed: widget.onAddExternalReview,
                                    child: Text(l10n.addExternalReview),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: widget.reviewController,
                                      minLines: 2,
                                      maxLines: 6,
                                      style: _bookDetailInputStyle(context),
                                      decoration: InputDecoration(
                                        hintText: l10n.writeReviewHint,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  FilledButton(
                                    onPressed: widget.onAddReview,
                                    child: Text(l10n.addReview),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.quoteController,
                          minLines: 2,
                          maxLines: 6,
                          style: _bookDetailInputStyle(context),
                          decoration: InputDecoration(
                            hintText: l10n.addMemorableQuote,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        onPressed: widget.onAddQuote,
                        child: Text(l10n.addQuote),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditReviewDialog extends StatefulWidget {
  const _EditReviewDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_EditReviewDialog> createState() => _EditReviewDialogState();
}

class _EditReviewDialogState extends State<_EditReviewDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.editReview),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 5,
        style: _bookDetailInputStyle(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
