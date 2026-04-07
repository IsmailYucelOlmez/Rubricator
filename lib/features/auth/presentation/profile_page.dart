import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../habit/presentation/widgets/habit_profile_summary.dart';
import '../../profile/presentation/widgets/language_selector.dart';
import '../../profile_stats/presentation/widgets/stats_preview_card.dart';
import 'auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: authAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profile, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const LanguageSelector(),
              const SizedBox(height: 12),
              if (user == null) ...[
                Text(l10n.signInPrompt),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _showSignInDialog(context),
                  child: Text(l10n.signIn),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _showSignUpDialog(context),
                  child: Text(l10n.createAccount),
                ),
              ] else ...[
                Text(
                  user.email ?? l10n.signedInFallback,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                  },
                  child: Text(l10n.signOut),
                ),
                const HabitProfileSummary(),
                const StatsPreviewCard(),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(l10n.loadSessionError(error.toString())),
          ),
        ),
      ),
    );
  }

  Future<void> _showSignInDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _ProfileSignInDialog(),
    );
  }

  Future<void> _showSignUpDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ProfileSignUpDialog(parentContext: context),
    );
  }

  static String authMessage(Object e, AppLocalizations l10n) {
    final s = e.toString();
    if (s.contains('Invalid login credentials')) {
      return l10n.invalidEmailOrPassword;
    }
    if (s.contains('User already registered')) {
      return l10n.accountAlreadyExists;
    }
    return s;
  }
}

class _ProfileSignInDialog extends StatefulWidget {
  const _ProfileSignInDialog();

  @override
  State<_ProfileSignInDialog> createState() => _ProfileSignInDialogState();
}

class _ProfileSignInDialogState extends State<_ProfileSignInDialog> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.signIn),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.email),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: l10n.password),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final email = _email.text.trim();
            final password = _password.text;
            if (email.isEmpty || password.isEmpty) return;
            try {
              final container = ProviderScope.containerOf(context);
              await container.read(authServiceProvider).signIn(
                    email: email,
                    password: password,
                  );
              if (!mounted) return;
              // Defer pop so auth stream rebuilds don't overlap dialog dispose
              // (avoids framework _dependents.isEmpty assertion with Riverpod).
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
              });
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
                );
              }
            }
          },
          child: Text(l10n.signIn),
        ),
      ],
    );
  }
}

class _ProfileSignUpDialog extends StatefulWidget {
  const _ProfileSignUpDialog({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_ProfileSignUpDialog> createState() => _ProfileSignUpDialogState();
}

class _ProfileSignUpDialogState extends State<_ProfileSignUpDialog> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.createAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.email),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.passwordMin6,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () async {
            final email = _email.text.trim();
            final password = _password.text;
            if (email.isEmpty || password.length < 6) return;
            try {
              final container = ProviderScope.containerOf(context);
              await container.read(authServiceProvider).signUp(
                    email: email,
                    password: password,
                  );
              if (!mounted) return;
              final messengerCtx = widget.parentContext;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
                if (messengerCtx.mounted) {
                  ScaffoldMessenger.of(messengerCtx).showSnackBar(
                    SnackBar(
                      content: Text(l10n.confirmAccountEmailNotice),
                    ),
                  );
                }
              });
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
                );
              }
            }
          },
          child: Text(l10n.signUp),
        ),
      ],
    );
  }
}
