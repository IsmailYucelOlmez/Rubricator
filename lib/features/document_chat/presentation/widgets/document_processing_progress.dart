import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/document_session.dart';

class DocumentProcessingProgress extends StatelessWidget {
  const DocumentProcessingProgress({
    super.key,
    required this.session,
  });

  final DocumentSession session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = session.embedProgress;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.documentChatProcessing,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            if (progress != null) ...[
              LinearProgressIndicator(value: progress),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.documentChatEmbedProgress(
                  session.chunksEmbedded,
                  session.chunksTotal,
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.documentChatExtracting,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (session.filename.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                session.filename,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
