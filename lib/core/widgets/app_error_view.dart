import 'package:flutter/material.dart';

import '../i18n/l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../ux/l10n_app_error.dart';

/// Generic failure UI (timeout, server, unknown) — not used for offline.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: compact ? 32 : 44,
          color: scheme.error,
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(
          l10n.userFacingMessage(error),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        FilledButton(onPressed: onRetry, child: Text(l10n.uxRetry)),
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: content,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      ),
    );
  }
}
