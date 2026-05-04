import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ux/app_feedback.dart';
import '../../../core/validation/form_validators.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loading.dart';
import 'auth_provider.dart';
import 'register_page.dart';

/// Full-screen sign-in (e.g. after tapping favorite while signed out).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  final _scrollCtrl = ScrollController();
  bool _submitting = false;
  String? _emailError;
  String? _passwordError;

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
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onEmailBlur(AppLocalizations l10n) {
    final email = _email.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = l10n.uxEmailRequired;
      } else if (!FormValidators.isValidEmail(email)) {
        _emailError = l10n.uxEmailInvalid;
      } else {
        _emailError = null;
      }
    });
  }

  void _onPasswordBlur(AppLocalizations l10n) {
    final password = _password.text;
    setState(() {
      _passwordError = password.isEmpty ? l10n.uxPasswordRequired : null;
    });
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _emailError = email.isEmpty
          ? l10n.uxEmailRequired
          : (!FormValidators.isValidEmail(email) ? l10n.uxEmailInvalid : null);
      _passwordError = password.isEmpty ? l10n.uxPasswordRequired : null;
    });
    if (_emailError != null || _passwordError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
        }
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(authServiceProvider).signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        AppFeedback.showErrorSnackBar(context, e);
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
          controller: _scrollCtrl,
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
                errorText: _emailError,
                onEditingComplete: () => _onEmailBlur(l10n),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              AppInput(
                controller: _password,
                obscureText: true,
                labelText: l10n.password,
                errorText: _passwordError,
                onEditingComplete: () => _onPasswordBlur(l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _submitting ? null : () => _submit(l10n),
                child: _submitting
                    ? const AppLoadingIndicator(
                        size: 22,
                        strokeWidth: 2,
                        centered: false,
                      )
                    : Text(l10n.signIn),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<bool>(builder: (_) => const RegisterPage()),
                        );
                      },
                child: Text(l10n.createAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
