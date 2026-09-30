import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../domain/entities/list_entities.dart';

class ListCard extends StatefulWidget {
  const ListCard({
    super.key,
    required this.list,
    required this.onTap,
    required this.onLikeTap,
    required this.onSaveTap,
  });

  final ListEntity list;
  final VoidCallback onTap;
  final Future<void> Function() onLikeTap;
  final Future<void> Function() onSaveTap;

  @override
  State<ListCard> createState() => _ListCardState();
}

class _ListCardState extends State<ListCard> {
  bool _likeBusy = false;
  bool _saveBusy = false;

  Future<void> _runLike() async {
    if (_likeBusy) return;
    setState(() => _likeBusy = true);
    try {
      await widget.onLikeTap();
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  Future<void> _runSave() async {
    if (_saveBusy) return;
    setState(() => _saveBusy = true);
    try {
      await widget.onSaveTap();
    } finally {
      if (mounted) setState(() => _saveBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final previewCount = list.previewCoverImageUrls.isEmpty
        ? 4
        : list.previewCoverImageUrls.length.clamp(1, 5);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 0.8,
    );
    final descriptionStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * 0.8,
    );
    final statsStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * 0.9,
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const overlap = 18.0;
                          final maxWidth = constraints.maxWidth;
                          final coverWidth =
                              (maxWidth + (previewCount - 1) * overlap) /
                              previewCount;
                          return Stack(
                            fit: StackFit.expand,
                            children: List.generate(previewCount, (idx) {
                              final imageUrl =
                                  idx < list.previewCoverImageUrls.length
                                  ? AppConstants.bookThumbnailUrl(
                                      list.previewCoverImageUrls[idx],
                                    )
                                  : null;
                              return Positioned(
                                left: idx * (coverWidth - overlap),
                                top: 0,
                                bottom: 0,
                                child: SizedBox(
                                  width: coverWidth,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                    child: imageUrl == null
                                        ? Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                          )
                                        : Image.network(
                                            imageUrl,
                                            webHtmlElementStrategy:
                                                WebHtmlElementStrategy.prefer,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
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
                  flex: 1,
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
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            list.description.trim().isEmpty
                                ? list.title
                                : list.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: descriptionStyle,
                          ),
                        ),
                      ),
                      // The save button keeps its size; like and comment
                      // share what's left and their counts shrink to fit
                      // instead of overflowing on narrow cards.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: _Stat(
                              icon: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _likeBusy ? null : _runLike,
                                icon: _likeBusy
                                    ? const AppLoadingIndicator(
                                        size: 14,
                                        strokeWidth: 2,
                                        centered: false,
                                      )
                                    : Icon(
                                        list.isLikedByMe
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 16,
                                      ),
                              ),
                              count: list.likeCount,
                              style: statsStyle,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _saveBusy ? null : _runSave,
                            icon: _saveBusy
                                ? const AppLoadingIndicator(
                                    size: 14,
                                    strokeWidth: 2,
                                    centered: false,
                                  )
                                : Icon(
                                    list.isSavedByMe
                                        ? Icons.bookmark
                                        : Icons.bookmark_outline,
                                    size: 16,
                                  ),
                          ),
                          Flexible(
                            child: _Stat(
                              icon: const Padding(
                                padding: EdgeInsets.only(right: AppSpacing.xs),
                                child: Icon(
                                  Icons.mode_comment_outlined,
                                  size: 16,
                                ),
                              ),
                              count: list.commentCount,
                              style: statsStyle,
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

/// Icon (or icon button) followed by a count that scales down rather than
/// overflow when the space is tight.
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.count, this.style});

  final Widget icon;
  final int count;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$count', style: style),
          ),
        ),
      ],
    );
  }
}
