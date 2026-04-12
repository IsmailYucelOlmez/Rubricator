import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/list_entities.dart';

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.list,
    required this.onTap,
    required this.onLikeTap,
    required this.onSaveTap,
  });

  final ListEntity list;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback onSaveTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(list.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('@${list.userName}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              SizedBox(
                height: 74,
                child: Row(
                  children: List.generate(4, (idx) {
                    final imageUrl = idx < list.previewCoverImageUrls.length
                        ? list.previewCoverImageUrls[idx]
                        : null;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: imageUrl == null
                              ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  IconButton(
                    onPressed: onLikeTap,
                    icon: Icon(list.isLikedByMe ? Icons.favorite : Icons.favorite_border),
                  ),
                  Text('${list.likeCount}'),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: onSaveTap,
                    icon: Icon(list.isSavedByMe ? Icons.bookmark : Icons.bookmark_outline),
                  ),
                  Text(l10n.commentsCount(list.commentCount)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
