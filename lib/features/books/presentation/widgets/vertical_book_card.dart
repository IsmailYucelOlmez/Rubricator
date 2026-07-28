import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/book.dart';
import '../pages/book_detail_page.dart';
import 'book_cover_with_favorite_button.dart';

/// Cover radius matching Virgil recommendation grid cards.
const double kBookGridCoverRadius = 10;

/// Shared 2-column book grid metrics (Virgil recommendation layout).
abstract final class BookGridLayout {
  static const int crossAxisCount = 2;
  static const double crossAxisSpacing = AppSpacing.md;
  static const double mainAxisSpacing = AppSpacing.lg;
  static const double childAspectRatio = 0.58;

  static const SliverGridDelegateWithFixedCrossAxisCount delegate =
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      );
}

/// Full-bleed cover + title + author column (Virgil recommendation card).
class VerticalBookCard extends ConsumerWidget {
  const VerticalBookCard({
    super.key,
    required this.book,
    this.width,
    this.onTap,
    this.author,
    this.showFavorite = true,
    this.isFavorite,
  });

  final Book book;
  /// When set, constrains the card (e.g. horizontal carousels). Null fills the parent.
  final double? width;
  final VoidCallback? onTap;
  final String? author;
  final bool showFavorite;
  /// When set, skips per-card favorite provider read (home bulk favorites).
  final bool? isFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final authorLine = author ?? book.author;
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(kBookGridCoverRadius),
      child: _BookCoverFillImage(coverImageUrl: book.coverImageUrl),
    );

    final card = InkWell(
      onTap: onTap ??
          () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BookDetailPage(book: book),
                ),
              ),
      borderRadius: BorderRadius.circular(kBookGridCoverRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: showFavorite
                ? BookCoverWithFavoriteButton(
                    bookId: book.id,
                    title: book.title,
                    author: authorLine,
                    categories: book.subjectKeys,
                    isFavorite: isFavorite,
                    child: cover,
                  )
                : cover,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.25,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            authorLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: card);
    }
    return card;
  }
}

/// Placeholder matching [VerticalBookCard] proportions in a grid.
class VerticalBookCardSkeleton extends StatelessWidget {
  const VerticalBookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(kBookGridCoverRadius),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const SizedBox(height: 14, width: double.infinity),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const SizedBox(height: 12, width: 96),
        ),
      ],
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
      return const ColoredBox(
        color: Colors.white,
        child: Center(
          child: Icon(Icons.menu_book_outlined, color: Color(0xFF9E9E9E)),
        ),
      );
    }
    return Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Colors.white,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF9E9E9E)),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: cs.surfaceContainer,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: AppLoadingIndicator(size: 20, strokeWidth: 2, centered: false),
            ),
          ),
        );
      },
    );
  }
}
