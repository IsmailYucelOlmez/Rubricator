import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../favorites/presentation/favorites_provider.dart';
import '../domain/book.dart';
import 'books_controller.dart';

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
          final coverUrl = detailedBook.coverId == null
              ? null
              : '${AppConstants.openLibraryCoverBaseUrl}/b/id/${detailedBook.coverId}-L.jpg';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(coverUrl, height: 240, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Text(detailedBook.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(detailedBook.author, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Text(
                detailedBook.description.isEmpty
                    ? 'No description available.'
                    : detailedBook.description,
              ),
              const SizedBox(height: 20),
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
        error: (error, stackTrace) =>
            const Center(child: Text('Failed to load details')),
      ),
    );
  }
}
