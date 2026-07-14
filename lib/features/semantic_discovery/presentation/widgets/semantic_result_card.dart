import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../books/presentation/widgets/book_cover_leading.dart';
import '../../domain/entities/semantic_book_result.dart';

class SemanticResultCard extends StatelessWidget {
  const SemanticResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  final SemanticBookResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = result.description.trim();
    final snippet = description.length > 160
        ? '${description.substring(0, 160).trim()}…'
        : description;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCoverLeading(coverImageUrl: result.coverImageUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.author,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (snippet.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      snippet,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
