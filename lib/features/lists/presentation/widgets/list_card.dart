import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(list.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('@${list.userName}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 74,
                child: Row(
                  children: List.generate(4, (idx) {
                    final coverId = idx < list.previewCoverIds.length ? list.previewCoverIds[idx] : null;
                    final imageUrl = AppConstants.workCoverUrl(coverId, size: 'M');
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: onLikeTap,
                    icon: Icon(list.isLikedByMe ? Icons.favorite : Icons.favorite_border),
                  ),
                  Text('${list.likeCount}'),
                  const SizedBox(width: 8),
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
