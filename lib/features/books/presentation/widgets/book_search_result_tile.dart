import 'package:flutter/material.dart';

import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/book.dart';
import 'book_cover_leading.dart';
import 'book_cover_with_favorite_button.dart';

/// List row typography: title prominent, author secondary.
TextStyle? bookListTitleStyle(TextTheme theme) {
  final titleMedium = theme.titleMedium;
  return titleMedium?.copyWith(
    fontFamily: 'LTSoul',
    fontSize: (titleMedium?.fontSize ?? 16) * 1.1,
  );
}

TextStyle? bookListAuthorStyle(TextTheme theme) {
  final bodySmall = theme.bodySmall;
  return bodySmall?.copyWith(
    fontSize: (bodySmall?.fontSize ?? 12) * 1.05,
  );
}

/// Search-result style book row (flat divider list, responsive cover).
class BookSearchResultTile extends StatelessWidget {
  const BookSearchResultTile({
    super.key,
    required this.book,
    required this.onTap,
    this.showFavorite = true,
    this.author,
  });

  final Book book;
  final VoidCallback onTap;
  final bool showFavorite;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final imageWidth = context.isTabletLayout
        ? (screenW * 0.18).clamp(96.0, 132.0)
        : screenW * 0.25;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = bookListTitleStyle(textTheme);
    final authorStyle = bookListAuthorStyle(textTheme);
    final authorLine = author ?? book.author;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: imageWidth,
              height: imageWidth * 1.4,
              child: showFavorite
                  ? BookCoverWithFavoriteButton(
                      bookId: book.id,
                      title: book.title,
                      author: book.author,
                      categories: book.subjectKeys,
                      compact: true,
                      child: BookCoverLeading(coverImageUrl: book.coverImageUrl),
                    )
                  : BookCoverLeading(coverImageUrl: book.coverImageUrl),
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
                    style: titleStyle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    authorLine,
                    softWrap: true,
                    style: authorStyle,
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
