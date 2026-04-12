import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_input.dart';
import 'auth_provider.dart';
import 'profile_page.dart';

/// Full-screen sign-in (e.g. after tapping favorite while signed out).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool _submitting = false;

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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authServiceProvider).signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signIn)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.signInPrompt, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                labelText: l10n.email,
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              AppInput(
                controller: _password,
                obscureText: true,
                labelText: l10n.password,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.signIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
