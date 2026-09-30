import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import 'auth_provider.dart';
import 'login_page.dart';

bool isSignedIn(WidgetRef ref) =>
    ref.read(authStateProvider).valueOrNull != null;

/// Returns `true` when signed in. Otherwise opens [LoginPage] and returns
/// whether the user signed in there.
Future<bool> ensureSignedIn(BuildContext context, WidgetRef ref) async {
  if (isSignedIn(ref)) return true;
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<bool>(builder: (_) => const LoginPage()));
  return isSignedIn(ref);
}

/// Inline call to action shown in place of actions that need an account.
class SignInPromptCard extends ConsumerWidget {
  const SignInPromptCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () => ensureSignedIn(context, ref),
              child: Text(l10n.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
