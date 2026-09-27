import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/book_cover_cache_manager.dart';
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
  static const double crossAxisSpacing = 30;
  static const double mainAxisSpacing = AppSpacing.lg;
  static const double childAspectRatio = 0.58;
  static const double horizontalPadding = AppSpacing.lg + 8;

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
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.menu_book_outlined, color: cs.onSurfaceVariant),
        ),
      );
    }
    final errorWidget = ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
      ),
    );
    final loadingWidget = ColoredBox(
      color: cs.surfaceContainer,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: AppLoadingIndicator(size: 20, strokeWidth: 2, centered: false),
        ),
      ),
    );
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Web keeps plain Image.network: it can render via the HTML <img> path
    // (webHtmlElementStrategy), which cached_network_image cannot do and
    // which avoids canvas same-origin errors for cross-origin covers (see
    // _webPageTransitions in app.dart). Native platforms get disk caching
    // via CachedNetworkImage so covers don't refetch on every cold start.
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeWidth = decodePixels(constraints.maxWidth, dpr);
        final decodeHeight = decodePixels(constraints.maxHeight, dpr);
        if (kIsWeb) {
          return Image.network(
            url,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: decodeWidth,
            cacheHeight: decodeHeight,
            errorBuilder: (context, error, stackTrace) => errorWidget,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : loadingWidget,
          );
        }
        return CachedNetworkImage(
          imageUrl: url,
          cacheManager: BookCoverCacheManager(),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: decodeWidth,
          memCacheHeight: decodeHeight,
          errorWidget: (context, url, error) => errorWidget,
          placeholder: (context, url) => loadingWidget,
        );
      },
    );
  }
}

/// Target decode resolution for a box of [logicalExtent] on a screen with
/// device pixel ratio [dpr] — caps decode cost for oversized source images
/// (e.g. hotlinked trbooks covers of unknown/uncontrolled dimensions)
/// without softening covers that are already small enough.
int? decodePixels(double logicalExtent, double dpr) {
  if (!logicalExtent.isFinite || logicalExtent <= 0) return null;
  return (logicalExtent * dpr).round();
}

/// How many not-yet-visible list items to prefetch covers for, so a cover is
/// often already downloading (or done) by the time its card scrolls into
/// view. Call from a horizontal list's itemBuilder for the next few indices.
const int kBookCoverPrefetchAhead = 3;

/// Starts loading [coverImageUrl] into the image cache ahead of time. Native
/// only: on web, precacheImage would force the canvas-decode path that
/// _BookCoverFillImage avoids for cross-origin covers (see its comment).
void precacheBookCover(BuildContext context, String? coverImageUrl) {
  if (kIsWeb) return;
  final url = AppConstants.bookThumbnailUrl(coverImageUrl);
  if (url == null) return;
  precacheImage(
    CachedNetworkImageProvider(url, cacheManager: BookCoverCacheManager()),
    context,
  ).catchError((_) {});
}
