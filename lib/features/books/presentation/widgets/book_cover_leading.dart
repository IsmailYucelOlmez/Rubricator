import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_loading.dart';

/// List tile leading: cover or placeholder (no API calls).
class BookCoverLeading extends StatelessWidget {
  const BookCoverLeading({
    super.key,
    this.coverImageUrl,
    this.size = 44,
  });

  final String? coverImageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mutedIcon = cs.onSurfaceVariant.withValues(alpha: 0.65);
    final url = AppConstants.bookThumbnailUrl(coverImageUrl);
    if (url == null) {
      return SizedBox(
        width: size,
        height: size * 1.4,
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.menu_book_outlined, color: mutedIcon),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        url,
        width: size,
        height: size * 1.4,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size * 1.4,
          child: ColoredBox(
            color: cs.surfaceContainerHighest,
            child: Icon(Icons.broken_image_outlined, color: mutedIcon),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size * 1.4,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: AppLoadingIndicator(size: 20, strokeWidth: 2, centered: false),
              ),
            ),
          );
        },
      ),
    );
  }
}
