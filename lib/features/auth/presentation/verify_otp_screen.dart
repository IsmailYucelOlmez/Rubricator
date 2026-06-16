import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_scaffold_body.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/password_validation_messages.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loading.dart';
import 'auth_provider.dart';
import 'profile_page.dart';

const int _recoveryOtpLength = 8;

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  late final TextEditingController _otp;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;
  final _scrollCtrl = ScrollController();
  bool _submitting = false;
  bool _resending = false;
  String? _otpError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _otp = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      }
    });
  }

  bool _validate(AppLocalizations l10n) {
    final otp = _otp.text.trim();
    final password = _password.text;
    final confirmPassword = _confirmPassword.text;

    setState(() {
      _otpError = otp.length < _recoveryOtpLength ? l10n.uxOtpIncomplete : null;
      _passwordError = l10n.passwordFieldError(password);
      _confirmPasswordError = confirmPassword != password ? l10n.uxPasswordMismatch : null;
    });

    final hasErrors = _otpError != null || _passwordError != null || _confirmPasswordError != null;
    if (hasErrors) _scrollToTop();
    return !hasErrors;
  }

  Future<void> _resetPassword(AppLocalizations l10n) async {
    if (!_validate(l10n)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authServiceProvider).verifyOtpAndResetPassword(
            email: widget.email,
            otpToken: _otp.text.trim(),
            newPassword: _password.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetSuccess)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
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

  Future<void> _resendCode(AppLocalizations l10n) async {
    setState(() => _resending = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resetCodeSent)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inputStyle = Theme.of(context).textTheme.bodyLarge!;
    final busy = _submitting || _resending;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: ResponsiveScaffoldBody(
          maxWidth: AppBreakpoints.formMaxWidth,
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.resetPasswordPrompt(widget.email),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _otp,
                  style: inputStyle,
                  keyboardType: TextInputType.number,
                  maxLength: _recoveryOtpLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onEditingComplete: () => setState(() {
                    _otpError = _otp.text.trim().length < _recoveryOtpLength ? l10n.uxOtpIncomplete : null;
                  }),
                  decoration: InputDecoration(
                    labelText: l10n.otpCodeLabel,
                    errorText: _otpError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                AppInput(
                  controller: _password,
                  obscureText: true,
                  labelText: l10n.passwordMin6,
                  errorText: _passwordError,
                  style: inputStyle,
                  onEditingComplete: () => setState(() {
                    _passwordError = l10n.passwordFieldError(_password.text);
                  }),
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                AppInput(
                  controller: _confirmPassword,
                  obscureText: true,
                  labelText: l10n.confirmPassword,
                  errorText: _confirmPasswordError,
                  style: inputStyle,
                  onEditingComplete: () => setState(() {
                    _confirmPasswordError =
                        _confirmPassword.text != _password.text ? l10n.uxPasswordMismatch : null;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: busy ? null : () => _resetPassword(l10n),
                  child: _submitting
                      ? const AppLoadingIndicator(
                          size: 22,
                          strokeWidth: 2,
                          centered: false,
                        )
                      : Text(l10n.updatePassword),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: busy ? null : () => _resendCode(l10n),
                  child: _resending
                      ? const AppLoadingIndicator(
                          size: 20,
                          strokeWidth: 2,
                          centered: false,
                        )
                      : Text(l10n.resendCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
