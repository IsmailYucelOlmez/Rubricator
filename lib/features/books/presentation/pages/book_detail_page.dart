import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../user_books/domain/entities/user_book_entity.dart';
import '../../../user_books/presentation/providers/user_books_provider.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../providers/books_providers.dart';
import 'author_detail_page.dart';

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
  int _selectedRating = 0;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailedBookAsync = ref.watch(bookDetailProvider(widget.book.id));
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
              final notifier = ref.read(userBookProvider(widget.book.id).notifier);
              try {
                await showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => _StatusBottomSheet(
                    current: status,
                    onSelect: (selected) async {
                      await notifier.upsert(
                        status: selected,
                        isFavorite: isFavorite,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                _showMessage(e.toString());
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
                _showMessage(e.toString());
              }
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
          ),
        ],
      ),
      body: detailedBookAsync.when(
        data: (detailedBook) {
          final summary = ref.watch(aiSummaryProvider(detailedBook));
          final reviews = ref.watch(reviewListProvider(detailedBook.id));
          final externalReviews = ref.watch(
            externalReviewProvider(detailedBook.id),
          );
          final quotes = ref.watch(quoteProvider(detailedBook.id));
          final rating = ref.watch(ratingProvider(detailedBook.id));
          final coverUrl = AppConstants.workCoverUrl(
            detailedBook.coverId,
            size: 'L',
          );
          final related = ref.watch(
            relatedBooksProvider((
              workId: detailedBook.id,
              subjects: detailedBook.subjectKeys,
            )),
          );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    coverUrl,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _CoverPlaceholder(height: 320),
                  ),
                )
              else
                const _CoverPlaceholder(height: 320),
              const SizedBox(height: AppSpacing.md),
              Text(
                detailedBook.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
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
                          await ref
                              .read(userBookProvider(widget.book.id).notifier)
                              .upsert(
                                status: selected,
                                isFavorite: isFavorite,
                              );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString());
                  }
                },
                onProgressChanged: (value) async {
                  final current = userBook?.status ?? ReadingStatus.toRead;
                  try {
                    await ref
                        .read(userBookProvider(widget.book.id).notifier)
                        .upsert(
                          status: current,
                          isFavorite: isFavorite,
                          progress: value,
                        );
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString());
                  }
                },
              ),
              if (detailedBook.authorIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AuthorDetailPage(
                            authorId: detailedBook.authorIds.first,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outlined),
                    label: Text(l10n.authorProfile),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _RatingSection(
                state: rating,
                selectedRating: _selectedRating,
                onChanged: (value) => setState(() => _selectedRating = value),
                onSubmit: () async {
                  try {
                    await ref
                        .read(ratingProvider(detailedBook.id).notifier)
                        .submit(_selectedRating);
                    _showMessage(l10n.ratingSubmitted);
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                detailedBook.description.isEmpty
                    ? l10n.noDescriptionAvailable
                    : detailedBook.description,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReviewTabsSection(
                reviewController: _reviewController,
                externalTitleController: _externalTitleController,
                externalUrlController: _externalUrlController,
                reviews: reviews,
                externalReviews: externalReviews,
                currentUserId: ref.watch(currentUserIdProvider),
                onAddReview: () async {
                  try {
                    await ref
                        .read(reviewListProvider(detailedBook.id).notifier)
                        .add(_reviewController.text);
                    _reviewController.clear();
                    _showMessage(l10n.reviewAdded);
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
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
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                onDeleteReview: (review) async {
                  try {
                    await ref
                        .read(reviewListProvider(detailedBook.id).notifier)
                        .remove(review);
                    _showMessage(l10n.reviewDeleted);
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                onAddExternalReview: () async {
                  try {
                    await ref
                        .read(externalReviewProvider(detailedBook.id).notifier)
                        .add(
                          title: _externalTitleController.text,
                          url: _externalUrlController.text,
                        );
                    _externalTitleController.clear();
                    _externalUrlController.clear();
                    _showMessage(l10n.externalReviewAdded);
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
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
              ),
              const SizedBox(height: AppSpacing.lg),
              _QuoteSection(
                controller: _quoteController,
                quotes: quotes,
                onAddQuote: () async {
                  try {
                    await ref
                        .read(quoteProvider(detailedBook.id).notifier)
                        .add(_quoteController.text);
                    _quoteController.clear();
                    _showMessage(l10n.quoteAdded);
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                onLikeQuote: (quoteId) async {
                  try {
                    await ref
                        .read(quoteProvider(detailedBook.id).notifier)
                        .like(quoteId);
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.relatedBooks, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              related.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Text(
                      l10n.noRelatedTitlesFound,
                      style: Theme.of(context).textTheme.bodyMedium,
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
                        final u = AppConstants.workCoverUrl(
                          b.coverId,
                          size: 'M',
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    child: u != null
                                        ? Image.network(
                                            u,
                                            width: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => const ColoredBox(
                                                  color: AppColors.card,
                                                  child: Icon(
                                                    Icons.menu_book_outlined,
                                                  ),
                                                ),
                                          )
                                        : const ColoredBox(
                                            color: AppColors.card,
                                            child: Icon(
                                              Icons.menu_book_outlined,
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
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text(l10n.couldNotLoadRelatedBooks),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.aiSummary, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              summary.when(
                data: Text.new,
                loading: () => const CircularProgressIndicator(),
                error: (error, stackTrace) => Text(l10n.aiSummaryFailed),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l10n.couldNotLoadThisBook(
                error.toString().replaceFirst('Exception: ', ''),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        Icons.menu_book_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.outline,
      ),
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
              Text(l10n.progressPercent(progress)),
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
                title: Text(_statusLabel(status, AppLocalizations.of(context)!)),
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
    required this.onChanged,
    required this.onSubmit,
  });

  final AsyncValue<RatingState> state;
  final int selectedRating;
  final ValueChanged<int> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.rating,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            state.when(
              data: (data) => Text(
                AppLocalizations.of(context)!.averageOutOfFive(
                  data.average.toStringAsFixed(1),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) =>
                  Text(AppLocalizations.of(context)!.couldNotLoadRating),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: List<Widget>.generate(
                5,
                (index) => IconButton(
                  onPressed: () => onChanged(index + 1),
                  icon: Icon(
                    selectedRating > index ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: selectedRating == 0 ? null : onSubmit,
              child: Text(AppLocalizations.of(context)!.submitRating),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTabsSection extends StatelessWidget {
  const _ReviewTabsSection({
    required this.reviewController,
    required this.externalTitleController,
    required this.externalUrlController,
    required this.reviews,
    required this.externalReviews,
    required this.currentUserId,
    required this.onAddReview,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onAddExternalReview,
    required this.onOpenExternalReview,
  });

  final TextEditingController reviewController;
  final TextEditingController externalTitleController;
  final TextEditingController externalUrlController;
  final AsyncValue<List<ReviewEntity>> reviews;
  final AsyncValue<List<ExternalReviewEntity>> externalReviews;
  final String? currentUserId;
  final VoidCallback onAddReview;
  final Future<void> Function(ReviewEntity review) onEditReview;
  final Future<void> Function(ReviewEntity review) onDeleteReview;
  final VoidCallback onAddExternalReview;
  final Future<void> Function(String url) onOpenExternalReview;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.reviews,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.userReviews),
              Tab(text: AppLocalizations.of(context)!.externalReviews),
            ],
          ),
          SizedBox(
            height: 380,
            child: TabBarView(
              children: [
                Column(
                  children: [
                    TextField(
                      controller: reviewController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.writeReviewHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onAddReview,
                        child: Text(AppLocalizations.of(context)!.addReview),
                      ),
                    ),
                    Expanded(
                      child: reviews.when(
                        data: (list) => list.isEmpty
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.noUserReviewsYet,
                                ),
                              )
                            : ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  final own = item.userId == currentUserId;
                                  return ListTile(
                                    title: Text(item.content),
                                    subtitle: Text(
                                      item.createdAt.toLocal().toString(),
                                    ),
                                    trailing: own
                                        ? Wrap(
                                            spacing: 4,
                                            children: [
                                              IconButton(
                                                onPressed: () =>
                                                    onEditReview(item),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    onDeleteReview(item),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                              ),
                                            ],
                                          )
                                        : null,
                                  );
                                },
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Center(
                          child: Text(
                            AppLocalizations.of(context)!.couldNotLoadReviews,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    TextField(
                      controller: externalTitleController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.reviewTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: externalUrlController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.reviewUrlHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onAddExternalReview,
                        child: Text(
                          AppLocalizations.of(context)!.addExternalReview,
                        ),
                      ),
                    ),
                    Expanded(
                      child: externalReviews.when(
                        data: (list) => list.isEmpty
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .noExternalReviewsYet,
                                ),
                              )
                            : ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final item = list[index];
                                  return ListTile(
                                    title: Text(item.title),
                                    subtitle: Text(item.url),
                                    trailing: IconButton(
                                      onPressed: () =>
                                          onOpenExternalReview(item.url),
                                      icon: const Icon(Icons.open_in_new),
                                    ),
                                  );
                                },
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) => Center(
                          child: Text(
                            AppLocalizations.of(context)!
                                .couldNotLoadExternalReviews,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteSection extends StatelessWidget {
  const _QuoteSection({
    required this.controller,
    required this.quotes,
    required this.onAddQuote,
    required this.onLikeQuote,
  });

  final TextEditingController controller;
  final AsyncValue<List<QuoteEntity>> quotes;
  final VoidCallback onAddQuote;
  final Future<void> Function(String quoteId) onLikeQuote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quotes,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.addMemorableQuote,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: onAddQuote,
            child: Text(AppLocalizations.of(context)!.addQuote),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: quotes.when(
            data: (list) => list.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.noQuotesYet))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        title: Text(item.content),
                        trailing: TextButton.icon(
                          onPressed: () => onLikeQuote(item.id),
                          icon: const Icon(Icons.thumb_up_outlined),
                          label: Text(item.likes.toString()),
                        ),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text(AppLocalizations.of(context)!.couldNotLoadQuotes),
            ),
          ),
        ),
      ],
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
      content: TextField(controller: _controller, minLines: 2, maxLines: 5),
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
