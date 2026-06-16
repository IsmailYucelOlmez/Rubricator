import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_scaffold_body.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/form_validators.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loading.dart';
import 'auth_provider.dart';
import 'profile_page.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  late final TextEditingController _email;
  final _scrollCtrl = ScrollController();
  bool _submitting = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode(AppLocalizations l10n) async {
    final email = _email.text.trim();
    setState(() {
      _emailError = email.isEmpty
          ? l10n.uxEmailRequired
          : (!FormValidators.isValidEmail(email) ? l10n.uxEmailInvalid : null);
    });
    if (_emailError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
        }
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetOtp(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resetCodeSent)),
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VerifyOtpScreen(email: email),
        ),
      );
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
    final inputStyle = Theme.of(context).textTheme.bodyLarge!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: ResponsiveScaffoldBody(
          maxWidth: AppBreakpoints.formMaxWidth,
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.forgotPasswordPrompt, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  labelText: l10n.email,
                  errorText: _emailError,
                  style: inputStyle,
                  onEditingComplete: () => setState(() {
                    final v = _email.text.trim();
                    _emailError = v.isEmpty
                        ? l10n.uxEmailRequired
                        : (!FormValidators.isValidEmail(v) ? l10n.uxEmailInvalid : null);
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _submitting ? null : () => _sendCode(l10n),
                  child: _submitting
                      ? const AppLoadingIndicator(
                          size: 22,
                          strokeWidth: 2,
                          centered: false,
                        )
                      : Text(l10n.sendResetCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
