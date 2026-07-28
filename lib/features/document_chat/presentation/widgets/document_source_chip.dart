import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/document_chat_source.dart';

class DocumentSourceChip extends StatelessWidget {
  const DocumentSourceChip({
    super.key,
    required this.source,
  });

  final DocumentChatSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final page = source.metadata['page'];
    final label = page != null
        ? l10n.documentChatSourcePage(page is int ? page : int.tryParse('$page') ?? 0)
        : (source.chapterLabel ?? 'chunk ${source.chunkIndex}');

    return Tooltip(
      message: source.excerpt,
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(label, style: Theme.of(context).textTheme.labelSmall),
        avatar: const Icon(Icons.menu_book_outlined, size: 16),
      ),
    );
  }
}

class DocumentSourceChipRow extends StatelessWidget {
  const DocumentSourceChipRow({
    super.key,
    required this.sources,
  });

  final List<DocumentChatSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: sources
            .map((source) => DocumentSourceChip(source: source))
            .toList(),
      ),
    );
  }
}
