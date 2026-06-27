import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/book_note_entity.dart';

class BookNoteCard extends StatelessWidget {
  const BookNoteCard({
    super.key,
    required this.note,
    required this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.subtitle,
  });

  final BookNoteEntity note;
  final String? currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? subtitle;

  bool get _isOwner =>
      currentUserId != null && currentUserId == note.userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.noteTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isOwner) ...[
                  if (onEdit != null)
                    IconButton(
                      tooltip: l10n.editNote,
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: l10n.delete,
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ],
            ),
            if (note.pageNumber != null || note.chapterTitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _locationLabel(l10n, note),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              note.noteContent,
              style: theme.textTheme.bodyMedium,
            ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in note.tags)
                    Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
            if (!note.isPublic && _isOwner) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.privateNote,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
    return parts.join(' · ');
  }
}
