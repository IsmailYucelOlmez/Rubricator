import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../favorites/presentation/favorites_provider.dart';
import '../../domain/entities/book.dart';
import '../providers/books_providers.dart';
import 'author_detail_page.dart';

class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailedBookAsync = ref.watch(bookDetailProvider(book));
    final isFavorite =
        ref.watch(favoritesProvider.notifier).isFavorite(book.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await ref.read(favoritesProvider.notifier).toggle(book);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_outline),
          ),
        ],
      ),
      body: detailedBookAsync.when(
        data: (detailedBook) {
          final summary = ref.watch(aiSummaryProvider(detailedBook));
          final coverUrl = AppConstants.workCoverUrl(detailedBook.coverId, size: 'L');
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
              Text(
                detailedBook.description.isEmpty
                    ? 'No description available.'
                    : detailedBook.description,
              ),
              const SizedBox(height: 24),
              Text('Related books', style: Theme.of(context).textTheme.titleLarge),
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
                        final u = AppConstants.workCoverUrl(b.coverId, size: 'M');
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
                                                (context, error, stackTrace) =>
                                                    const ColoredBox(
                                              color: Colors.black12,
                                              child: Icon(Icons.menu_book_outlined),
                                            ),
                                          )
                                        : const ColoredBox(
                                            color: Colors.black12,
                                            child: Icon(Icons.menu_book_outlined),
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
