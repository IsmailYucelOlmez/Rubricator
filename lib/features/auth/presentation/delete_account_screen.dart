import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/layout/responsive_scaffold_body.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_loading.dart';
import '../data/services/auth_service.dart';
import 'auth_provider.dart';
import 'profile_page.dart';

const int _otpLength = 8;

/// Permanent account deletion: explain what is lost, email a one-time code,
/// then send the code to the `delete-account` edge function, which verifies it
/// and deletes the account server-side.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _otp = TextEditingController();
  bool _codeSent = false;
  bool _sending = false;
  bool _deleting = false;
  String? _otpError;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendCode(AppLocalizations l10n) async {
    setState(() => _sending = true);
    try {
      await ref.read(authServiceProvider).sendAccountDeletionOtp();
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showMessage(l10n.deleteAccountCodeSent);
    } catch (e) {
      if (mounted) _showMessage(ProfilePage.authMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(AppLocalizations l10n) async {
    final otp = _otp.text.trim();
    if (otp.length < _otpLength) {
      setState(() => _otpError = l10n.uxOtpIncomplete);
      return;
    }
    setState(() {
      _otpError = null;
      _deleting = true;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).deleteAccount(otp);
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountSuccess)),
      );
    } on AccountDeletionException catch (e) {
      if (!mounted) return;
      if (e.isInvalidCode) {
        setState(() => _otpError = l10n.invalidOrExpiredOtp);
      } else {
        _showMessage(l10n.deleteAccountFailed);
      }
    } catch (e) {
      if (mounted) _showMessage(ProfilePage.authMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = ref.watch(authStateProvider).valueOrNull?.email ?? '';
    final busy = _sending || _deleting;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: SafeArea(
        child: ResponsiveScaffoldBody(
          maxWidth: AppBreakpoints.formMaxWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  color: scheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.deleteAccountWarning,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _codeSent
                      ? l10n.resetPasswordPrompt(email)
                      : l10n.deleteAccountOtpExplain(email),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (!_codeSent)
                  FilledButton(
                    onPressed: busy ? null : () => _sendCode(l10n),
                    child: _sending
                        ? const AppLoadingIndicator(
                            size: 22,
                            strokeWidth: 2,
                            centered: false,
                          )
                        : Text(l10n.deleteAccountSendCode),
                  )
                else ...[
                  TextField(
                    controller: _otp,
                    style: theme.textTheme.bodyLarge,
                    keyboardType: TextInputType.number,
                    maxLength: _otpLength,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.otpCodeLabel,
                      errorText: _otpError,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    ),
                    onPressed: busy ? null : () => _delete(l10n),
                    child: _deleting
                        ? const AppLoadingIndicator(
                            size: 22,
                            strokeWidth: 2,
                            centered: false,
                          )
                        : Text(l10n.deleteAccountConfirm),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: busy ? null : () => _sendCode(l10n),
                    child: _sending
                        ? const AppLoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                            centered: false,
                          )
                        : Text(l10n.resendCode),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
