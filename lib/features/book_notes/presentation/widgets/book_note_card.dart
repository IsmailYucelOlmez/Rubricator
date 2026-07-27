import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/relative_time_utils.dart';
import '../../domain/entities/book_note_entity.dart';

class BookNoteCard extends StatelessWidget {
  const BookNoteCard({
    super.key,
    required this.note,
    required this.currentUserId,
    required this.currentUserDisplayName,
    this.onEdit,
    this.onDelete,
    this.subtitle,
  });

  final BookNoteEntity note;
  final String? currentUserId;
  final String currentUserDisplayName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? subtitle;

  bool get _isOwner => currentUserId != null && currentUserId == note.userId;

  String get _userName {
    final stored = note.userName?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    if (_isOwner) return currentUserDisplayName;
    return 'user';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final metaTextStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final hasLocation = note.pageNumber != null || note.chapterTitle != null;
    final showPrivateBadge = !note.isPublic && _isOwner;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.28)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _userName,
                    style: metaTextStyle,
                  ),
                ),
                if (hasLocation || showPrivateBadge)
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (hasLocation)
                        Text(
                          _locationLabel(l10n, note),
                          textAlign: TextAlign.end,
                          style: metaTextStyle?.copyWith(color: cs.primary),
                        ),
                      if (showPrivateBadge)
                        _NoteMetaPill(
                          text: l10n.privateNote,
                          color: cs.onSurface,
                          textStyle: metaTextStyle,
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              note.noteTitle,
              textAlign: TextAlign.start,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.start,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              note.noteContent,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
            ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tag in note.tags)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Chip(
                          label: Text(tag),
                          labelStyle: theme.textTheme.labelSmall,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          labelPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_isOwner && onEdit != null)
                  IconButton(
                    tooltip: l10n.editNote,
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                if (_isOwner && onDelete != null)
                  IconButton(
                    tooltip: l10n.delete,
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                const Spacer(),
                Text(
                  formatRelativeTime(note.createdAt, l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _locationLabel(AppLocalizations l10n, BookNoteEntity note) {
    final parts = <String>[];
    if (note.pageNumber != null) {
      parts.add(l10n.notePageLabel(note.pageNumber!));
    }
    if (note.chapterTitle != null && note.chapterTitle!.isNotEmpty) {
      parts.add(note.chapterTitle!);
    }
    return parts.join(' / ');
  }
}

class _NoteMetaPill extends StatelessWidget {
  const _NoteMetaPill({
    required this.text,
    required this.color,
    this.textStyle,
  });

  final String text;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: textStyle?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ) ??
            theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
