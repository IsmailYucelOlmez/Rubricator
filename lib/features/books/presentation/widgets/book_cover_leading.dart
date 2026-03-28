import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

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
        child: const Icon(Icons.menu_book_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: size,
        height: size * 1.4,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: size,
          height: size * 1.4,
          child: const Icon(Icons.broken_image_outlined),
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
