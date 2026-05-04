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
    final previewCount = list.previewCoverImageUrls.isEmpty ? 4 : list.previewCoverImageUrls.length.clamp(1, 5);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 0.8,
    );
    final descriptionStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * 0.8,
    );
    final userNameStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * 0.8,
    );
    final metaStyle = Theme.of(context).textTheme.bodySmall;
    final statsStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * 0.9,
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
          child: SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const overlap = 18.0;
                          final maxWidth = constraints.maxWidth;
                          final coverWidth = (maxWidth + (previewCount - 1) * overlap) / previewCount;
                          return Stack(
                            fit: StackFit.expand,
                            children: List.generate(previewCount, (idx) {
                              final imageUrl = idx < list.previewCoverImageUrls.length
                                  ? list.previewCoverImageUrls[idx]
                                  : null;
                              return Positioned(
                                left: idx * (coverWidth - overlap),
                                top: 0,
                                bottom: 0,
                                child: SizedBox(
                                  width: coverWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    child: imageUrl == null
                                        ? Container(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          )
                                        : Image.network(
                                            imageUrl,
                                            webHtmlElementStrategy:
                                                WebHtmlElementStrategy.prefer,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '@${list.userName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: userNameStyle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          list.description.trim().isEmpty ? list.title : list.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: descriptionStyle,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onLikeTap,
                            icon: Icon(
                              list.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 0),
                          Text('${list.likeCount}', style: statsStyle),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onSaveTap,
                            icon: Icon(
                              list.isSavedByMe ? Icons.bookmark : Icons.bookmark_outline,
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.mode_comment_outlined, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              '${list.commentCount}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: statsStyle,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
