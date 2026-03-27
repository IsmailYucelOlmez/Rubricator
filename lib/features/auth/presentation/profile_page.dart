import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  onPressed: () => _showSignInDialog(context, ref),
                  child: const Text('Sign in'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _showSignUpDialog(context, ref),
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

  Future<void> _showSignInDialog(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign in'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text;
                if (email.isEmpty || password.isEmpty) return;
                try {
                  await ref.read(authServiceProvider).signIn(
                        email: email,
                        password: password,
                      );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(_authMessage(e))),
                    );
                  }
                }
              },
              child: const Text('Sign in'),
            ),
          ],
        );
      },
    );
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _showSignUpDialog(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (min 6 characters)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text;
                if (email.isEmpty || password.length < 6) return;
                try {
                  await ref.read(authServiceProvider).signUp(
                        email: email,
                        password: password,
                      );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Check your email to confirm your account if required.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(_authMessage(e))),
                    );
                  }
                }
              },
              child: const Text('Sign up'),
            ),
          ],
        );
      },
    );
    emailController.dispose();
    passwordController.dispose();
  }

  String _authMessage(Object e) {
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
