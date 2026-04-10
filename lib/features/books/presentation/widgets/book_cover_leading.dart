import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// List tile leading: cover or placeholder (no API calls).
class BookCoverLeading extends StatelessWidget {
  const BookCoverLeading({super.key, this.coverId, this.size = 44});

  final int? coverId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = AppConstants.workCoverUrl(coverId, size: 'M');
    if (url == null) {
      return SizedBox(
        width: size,
        height: size * 1.4,
        child: ColoredBox(
          color: AppColors.card,
          child: Icon(Icons.menu_book_outlined, color: AppColors.textSecondary.withValues(alpha: 0.6)),
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
            color: AppColors.card,
            child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary.withValues(alpha: 0.6)),
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
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
