import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/document_session.dart';
import '../providers/document_chat_providers.dart';
import '../widgets/document_chat_input_bar.dart';
import '../widgets/document_chat_message_list.dart';
import '../widgets/document_processing_progress.dart';
import '../widgets/document_upload_card.dart';

class DocumentChatView extends ConsumerWidget {
  const DocumentChatView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (!Env.hasSemanticApiConfig) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            l10n.semanticApiNotConfigured,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final state = ref.watch(documentChatProvider);
    final notifier = ref.read(documentChatProvider.notifier);
    final session = state.session;

    if (session == null) {
      return Column(
        children: [
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _errorText(l10n, state),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          Expanded(
            child: DocumentUploadCard(
              isUploading: state.isUploading,
              onPickFile: notifier.pickAndUpload,
            ),
          ),
        ],
      );
    }

    if (state.isUploading) {
      return DocumentUploadCard(
        isUploading: true,
        onPickFile: () {},
      );
    }

    if (session.isProcessing || state.isPolling) {
      return DocumentProcessingProgress(session: session);
    }

    if (session.isFailed ||
        state.errorKind == DocumentChatErrorKind.processingFailed ||
        state.errorKind == DocumentChatErrorKind.sessionExpired ||
        state.errorKind == DocumentChatErrorKind.pollTimeout) {
      return _ErrorState(
        message: _errorText(l10n, state),
        onRetry: notifier.resetSession,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SessionHeader(
          session: session,
          onNewFile: notifier.resetSession,
        ),
        if (session.truncated)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  l10n.documentChatTruncatedWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        if (state.error != null &&
            state.errorKind != DocumentChatErrorKind.stillProcessing)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              _errorText(l10n, state),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        Expanded(
          child: state.messages.isEmpty && !state.isSending
              ? Center(
                  child: Text(
                    l10n.documentChatEmptyHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : DocumentChatMessageList(
                  messages: state.messages,
                  isSending: state.isSending,
                ),
        ),
        DocumentChatInputBar(
          enabled: state.canSendQuestion,
          onSend: notifier.sendQuestion,
        ),
      ],
    );
  }

  String _errorText(AppLocalizations l10n, DocumentChatState state) {
    switch (state.errorKind) {
      case DocumentChatErrorKind.fileTooLarge:
        return l10n.documentChatFileTooLarge(20);
      case DocumentChatErrorKind.unsupportedFormat:
        return l10n.documentChatUnsupportedFormat;
      case DocumentChatErrorKind.sessionExpired:
        return l10n.documentChatSessionExpired;
      case DocumentChatErrorKind.processingFailed:
        final detail = state.error;
        if (detail != null &&
            detail.isNotEmpty &&
            detail != 'processing_failed') {
          return detail;
        }
        return l10n.documentChatProcessingFailed;
      case DocumentChatErrorKind.questionLimit:
        return l10n.documentChatQuestionsRemaining(0);
      case DocumentChatErrorKind.stillProcessing:
        return l10n.documentChatStillProcessing;
      case DocumentChatErrorKind.pollTimeout:
        return l10n.documentChatProcessingFailed;
      case DocumentChatErrorKind.generic:
      case null:
        return state.error ?? l10n.documentChatProcessingFailed;
    }
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.session,
    required this.onNewFile,
  });

  final DocumentSession session;
  final VoidCallback onNewFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parts = <String>[session.filename];
    if (session.pageCount != null) {
      parts.add('${session.pageCount} ${l10n.documentChatPages}');
    } else if (session.chapterCount != null) {
      parts.add('${session.chapterCount} ${l10n.documentChatChapters}');
    }
    parts.add(l10n.documentChatQuestionsRemaining(session.questionsRemaining));

    final remaining = session.expiresAt.toUtc().difference(DateTime.now().toUtc());
    if (!remaining.isNegative) {
      final mins = remaining.inMinutes;
      parts.add(l10n.documentChatExpiresIn(mins));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parts.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onNewFile,
            child: Text(l10n.documentChatNewFile),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: Text(l10n.documentChatPickFile),
            ),
          ],
        ),
      ),
    );
  }
}
