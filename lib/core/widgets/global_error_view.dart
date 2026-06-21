import 'dart:ui';

import 'package:flutter/material.dart';

import '../i18n/l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Fallback UI when a widget fails to build (via [ErrorWidget.builder]).
class GlobalErrorView extends StatelessWidget {
  const GlobalErrorView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final locale = PlatformDispatcher.instance.locale;
    final l10n = lookupAppLocalizations(
      locale.languageCode == 'tr' ? const Locale('tr') : const Locale('en'),
    );
    final brightness = PlatformDispatcher.instance.platformBrightness;
    final theme = brightness == Brightness.dark
        ? AppTheme.dark()
        : AppTheme.light();

    return Theme(
      data: theme,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.uxErrorBoundaryTitle,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.uxErrorUnknown,
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: onRetry,
                      child: Text(l10n.uxRetry),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
