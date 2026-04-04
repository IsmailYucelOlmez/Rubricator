import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habit/presentation/widgets/habit_profile_summary.dart';
import '../../profile_stats/presentation/widgets/stats_preview_card.dart';
import 'auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: authAsync.when(
          data: (user) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (user == null) ...[
                const Text('Sign in to sync favorites across devices.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _showSignInDialog(context),
                  child: const Text('Sign in'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _showSignUpDialog(context),
                  child: const Text('Create account'),
                ),
              ] else ...[
                Text(
                  user.email ?? 'Signed in',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                  },
                  child: const Text('Sign out'),
                ),
                const HabitProfileSummary(),
                const StatsPreviewCard(),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load session: $error'),
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

  static String authMessage(Object e) {
    final s = e.toString();
    if (s.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (s.contains('User already registered')) {
      return 'An account with this email already exists.';
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
    return AlertDialog(
      title: const Text('Sign in'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
                  SnackBar(content: Text(ProfilePage.authMessage(e))),
                );
              }
            }
          },
          child: const Text('Sign in'),
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
    return AlertDialog(
      title: const Text('Create account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password (min 6 characters)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
                    const SnackBar(
                      content: Text(
                        'Check your email to confirm your account if required.',
                      ),
                    ),
                  );
                }
              });
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ProfilePage.authMessage(e))),
                );
              }
            }
          },
          child: const Text('Sign up'),
        ),
      ],
    );
  }
}
