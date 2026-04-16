import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/book.dart';
import '../pages/book_detail_page.dart';
import 'book_cover_with_favorite_button.dart';

/// Narrow column: full-bleed cover + title + author (matches home horizontal rows).
class VerticalBookCard extends ConsumerWidget {
  const VerticalBookCard({super.key, required this.book, this.width = 145});

  final Book book;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final titleFontSize = (titleStyle?.fontSize ?? 14) * 0.80;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BookCoverWithFavoriteButton(
                bookId: book.id,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: _BookCoverFillImage(coverImageUrl: book.coverImageUrl),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: titleStyle?.copyWith(
                fontSize: titleFontSize,
                fontFamily: 'Yellowtail',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCoverFillImage extends StatelessWidget {
  const _BookCoverFillImage({this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = AppConstants.bookThumbnailUrl(coverImageUrl);
    if (url == null) {
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(child: Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: cs.surfaceContainer,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
