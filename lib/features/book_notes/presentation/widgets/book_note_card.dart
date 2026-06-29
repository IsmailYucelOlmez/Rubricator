import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
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

  bool get _isOwner => currentUserId != null && currentUserId == note.userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.7,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.28),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            Icons.note_alt_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
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
                      ],
                    ),
                  ),
                  if (_isOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                    ),
                ],
              ),
              if (note.pageNumber != null ||
                  note.chapterTitle != null ||
                  (!note.isPublic && _isOwner)) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (note.pageNumber != null || note.chapterTitle != null)
                      _NoteMetaPill(
                        text: _locationLabel(l10n, note),
                        color: theme.colorScheme.primary,
                      ),
                    if (!note.isPublic && _isOwner)
                      _NoteMetaPill(
                        text: l10n.privateNote,
                        color: theme.colorScheme.onSurface,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  note.noteContent,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.42),
                ),
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
            ],
          ),
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
  const _NoteMetaPill({required this.text, required this.color});

  final String text;
  final Color color;

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
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
