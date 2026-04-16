import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../domain/entities/home_book_entity.dart';
import '../providers/home_providers.dart';

class GenreBooksPage extends ConsumerWidget {
  const GenreBooksPage({
    required this.genreKey,
    required this.genreLabel,
    super.key,
  });

  final String genreKey;
  final String genreLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksState = ref.watch(genreBooksProvider(genreKey));
    return Scaffold(
      appBar: AppBar(title: Text(genreLabel)),
      body: booksState.when(
        data: (books) {
          if (books.isEmpty) {
            return const Center(child: Text('No books found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final book = books[index];
              return _GenreBookTile(book: book);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Could not load books for $genreLabel.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreBookTile extends StatelessWidget {
  const _GenreBookTile({required this.book});

  final HomeBookEntity book;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book.toBook())),
      ),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: _GenreCoverImage(coverImageUrl: book.coverImageUrl),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.authorNames,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _GenreCoverImage extends StatelessWidget {
  const _GenreCoverImage({this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = AppConstants.bookThumbnailUrl(coverImageUrl);
    if (url == null) {
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: SizedBox(
          width: 56,
          height: 84,
          child: Center(child: Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant)),
        ),
      );
    }
    return Image.network(
      url,
      width: 56,
      height: 84,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: SizedBox(
          width: 56,
          height: 84,
          child: Center(
            child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
          ),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: cs.surfaceContainer,
          child: const SizedBox(
            width: 56,
            height: 84,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
