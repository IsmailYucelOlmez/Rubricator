import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../favorites/presentation/favorites_provider.dart';
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
    final detailedBookAsync = ref.watch(bookDetailProvider(widget.book.id));
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorite = favoritesAsync.maybeWhen(
      data: (books) => books.any((b) => b.id == widget.book.id),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await ref.read(favoritesProvider.notifier).toggle(widget.book);
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
            padding: const EdgeInsets.all(16),
            children: [
              if (coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    coverUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _CoverPlaceholder(height: 240),
                  ),
                )
              else
                const _CoverPlaceholder(height: 240),
              const SizedBox(height: 16),
              Text(
                detailedBook.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                detailedBook.author,
                style: Theme.of(context).textTheme.titleMedium,
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
                    label: const Text('Author profile'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _RatingSection(
                state: rating,
                selectedRating: _selectedRating,
                onChanged: (value) => setState(() => _selectedRating = value),
                onSubmit: () async {
                  try {
                    await ref
                        .read(ratingProvider(detailedBook.id).notifier)
                        .submit(_selectedRating);
                    _showMessage('Rating submitted.');
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                detailedBook.description.isEmpty
                    ? 'No description available.'
                    : detailedBook.description,
              ),
              const SizedBox(height: 24),
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
                    _showMessage('Review added.');
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
                    _showMessage('Review updated.');
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
                    _showMessage('Review deleted.');
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
                    _showMessage('External review added.');
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                onOpenExternalReview: (url) async {
                  final uri = Uri.tryParse(url);
                  if (uri == null) {
                    _showMessage('Invalid URL');
                    return;
                  }
                  final ok = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!ok && mounted) {
                    _showMessage('Could not open browser.');
                  }
                },
              ),
              const SizedBox(height: 24),
              _QuoteSection(
                controller: _quoteController,
                quotes: quotes,
                onAddQuote: () async {
                  try {
                    await ref
                        .read(quoteProvider(detailedBook.id).notifier)
                        .add(_quoteController.text);
                    _quoteController.clear();
                    _showMessage('Quote added.');
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
              const SizedBox(height: 24),
              Text(
                'Related books',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              related.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Text(
                      'No related titles found (subjects missing or empty results).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }
                  return SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
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
                                    borderRadius: BorderRadius.circular(8),
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
                                                  color: Colors.black12,
                                                  child: Icon(
                                                    Icons.menu_book_outlined,
                                                  ),
                                                ),
                                          )
                                        : const ColoredBox(
                                            color: Colors.black12,
                                            child: Icon(
                                              Icons.menu_book_outlined,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 6),
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
                error: (error, stackTrace) =>
                    const Text('Could not load related books.'),
              ),
              const SizedBox(height: 24),
              Text('AI Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              summary.when(
                data: Text.new,
                loading: () => const CircularProgressIndicator(),
                error: (error, stackTrace) => const Text('AI summary failed'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this book. ${error.toString().replaceFirst('Exception: ', '')}',
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.menu_book_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            state.when(
              data: (data) =>
                  Text('Average: ${data.average.toStringAsFixed(1)} / 5'),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) =>
                  const Text('Could not load rating.'),
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
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: selectedRating == 0 ? null : onSubmit,
              child: const Text('Submit rating'),
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
          Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const TabBar(
            tabs: [
              Tab(text: 'User Reviews'),
              Tab(text: 'External Reviews'),
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
                      decoration: const InputDecoration(
                        hintText: 'Write your review (min 10 chars)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onAddReview,
                        child: const Text('Add review'),
                      ),
                    ),
                    Expanded(
                      child: reviews.when(
                        data: (list) => list.isEmpty
                            ? const Center(child: Text('No user reviews yet.'))
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
                        error: (error, stackTrace) => const Center(
                          child: Text('Could not load reviews.'),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    TextField(
                      controller: externalTitleController,
                      decoration: const InputDecoration(
                        hintText: 'Review title',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: externalUrlController,
                      decoration: const InputDecoration(
                        hintText: 'https://example.com/review',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onAddExternalReview,
                        child: const Text('Add external review'),
                      ),
                    ),
                    Expanded(
                      child: externalReviews.when(
                        data: (list) => list.isEmpty
                            ? const Center(
                                child: Text('No external reviews yet.'),
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
                        error: (error, stackTrace) => const Center(
                          child: Text('Could not load external reviews.'),
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
        Text('Quotes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Add a memorable quote'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: onAddQuote,
            child: const Text('Add quote'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: quotes.when(
            data: (list) => list.isEmpty
                ? const Center(child: Text('No quotes yet.'))
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
            error: (error, stackTrace) =>
                const Center(child: Text('Could not load quotes.')),
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
      title: const Text('Edit review'),
      content: TextField(controller: _controller, minLines: 2, maxLines: 5),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
