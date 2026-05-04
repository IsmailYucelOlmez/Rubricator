import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/form_validators.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loading.dart';
import 'auth_provider.dart';
import 'privacy_policy_page.dart';
import 'profile_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _userName;
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedAvatar;
  Uint8List? _selectedAvatarBytes;
  bool _acceptedPrivacy = false;
  bool _submitting = false;
  String? _emailError;
  String? _passwordError;
  String? _userNameError;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
    _userName = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _userName.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _email.text.trim();
    final password = _password.text;
    final userName = _userName.text.trim();

    setState(() {
      _emailError = email.isEmpty
          ? l10n.uxEmailRequired
          : (!FormValidators.isValidEmail(email) ? l10n.uxEmailInvalid : null);
      _passwordError = password.isEmpty
          ? l10n.uxPasswordRequired
          : (password.length < 6 ? l10n.passwordMin6 : null);
      _userNameError = userName.isEmpty ? l10n.uxUserNameRequired : null;
    });

    final hasErrors = _emailError != null || _passwordError != null || _userNameError != null;
    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uxAcceptPrivacyRequired)),
      );
      return;
    }
    if (hasErrors) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        }
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      final authResponse = await authService.signUp(
            email: email,
            password: password,
            displayName: userName,
            privacyPolicyAcceptedAt: DateTime.now().toUtc(),
            privacyPolicyVersion: '2026-04-17',
          );

      if (_selectedAvatar != null && _selectedAvatarBytes != null) {
        final currentUser = authService.currentUser;
        final userId = currentUser?.id ?? authResponse.user?.id;
        if (currentUser != null && userId != null) {
          final uploadedUrl = await authService.uploadProfilePhoto(
            userId: userId,
            bytes: _selectedAvatarBytes!,
            fileName: _selectedAvatar!.name,
          );
          await authService.updateProfile(
            displayName: userName,
            avatarUrl: uploadedUrl,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.confirmAccountEmailNotice)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  Future<void> _pickAvatarFromGallery() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final selected = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (!mounted || selected == null) return;
      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedAvatar = selected;
        _selectedAvatarBytes = bytes;
      });
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.uxGalleryPluginError)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
      );
    }
  }

  void _clearSelectedAvatar() {
    setState(() {
      _selectedAvatar = null;
      _selectedAvatarBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInput(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                labelText: l10n.email,
                errorText: _emailError,
                onEditingComplete: () => setState(() {
                  final v = _email.text.trim();
                  _emailError = v.isEmpty
                      ? l10n.uxEmailRequired
                      : (!FormValidators.isValidEmail(v) ? l10n.uxEmailInvalid : null);
                }),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              AppInput(
                controller: _password,
                obscureText: true,
                labelText: l10n.passwordMin6,
                errorText: _passwordError,
                onEditingComplete: () => setState(() {
                  final v = _password.text;
                  if (v.isEmpty) {
                    _passwordError = l10n.uxPasswordRequired;
                  } else if (v.length < 6) {
                    _passwordError = l10n.passwordMin6;
                  } else {
                    _passwordError = null;
                  }
                }),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              AppInput(
                controller: _userName,
                labelText: l10n.displayNameLabel,
                errorText: _userNameError,
                onEditingComplete: () => setState(() {
                  _userNameError =
                      _userName.text.trim().isEmpty ? l10n.uxUserNameRequired : null;
                }),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        _selectedAvatarBytes != null ? MemoryImage(_selectedAvatarBytes!) : null,
                    child: _selectedAvatarBytes == null ? const Icon(Icons.person_outline) : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: _submitting ? null : _pickAvatarFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _selectedAvatar == null
                          ? l10n.pickProfilePhotoFromGallery
                          : l10n.changeProfilePhoto,
                    ),
                  ),
                  if (_selectedAvatar != null)
                    IconButton(
                      onPressed: _submitting ? null : _clearSelectedAvatar,
                      tooltip: l10n.removeProfilePhotoTooltip,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedPrivacy,
                onChanged: _submitting
                    ? null
                    : (value) {
                        setState(() => _acceptedPrivacy = value ?? false);
                      },
                controlAffinity: ListTileControlAffinity.leading,
                title: InkWell(
                  onTap: _openPrivacyPolicy,
                  child: Text(l10n.privacyPolicyCheckbox),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const AppLoadingIndicator(
                        size: 22,
                        strokeWidth: 2,
                        centered: false,
                      )
                    : Text(l10n.signUp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
