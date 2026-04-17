import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loading.dart';
import '../../habit/presentation/widgets/habit_profile_summary.dart';
import '../../favorites/presentation/pages/reading_status_list_page.dart';
import '../../profile/presentation/widgets/language_selector.dart';
import '../../profile_stats/presentation/widgets/stats_preview_card.dart';
import '../../user_books/domain/entities/user_book_entity.dart';
import 'auth_provider.dart';
import 'login_page.dart';
import 'register_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: authAsync.when(
          data: (user) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Zone',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'EFCOBrookshire',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const LanguageSelector(),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              Text(l10n.themeAppearance, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                    icon: const Icon(Icons.light_mode_outlined, size: 18),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                    icon: const Icon(Icons.dark_mode_outlined, size: 18),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selected) {
                  ref.read(themeModeProvider.notifier).setTheme(selected.first);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (user == null) ...[
                Text(l10n.signInPrompt),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<bool>(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Text(l10n.signIn),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<bool>(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: Text(l10n.createAccount),
                ),
              ] else ...[
                _ProfileHeader(user: user),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: () => _showEditProfileDialog(context, user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Profili duzenle'),
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                FilledButton(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                  },
                  child: Text(l10n.signOut),
                ),
                const HabitProfileSummary(),
                const StatsPreviewCard(),
                const _ProfileReadingListsSection(),
              ],
              ],
            ),
          ),
          loading: () => const AppLoadingIndicator(),
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

  Future<void> _showEditProfileDialog(BuildContext context, User user) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ProfileEditDialog(user: user),
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
    if (s.contains('Bucket not found') || s.contains('profile-photos')) {
      return 'Profil fotografi alani hazir degil. Veritabani migrationlarini calistir.';
    }
    if (s.contains('row-level security') || s.contains('new row violates row-level security policy')) {
      return 'Profil fotografi icin Storage izinleri eksik. Supabase policy migrationini uygula.';
    }
    return s;
  }
}

class _ProfileReadingListsSection extends StatelessWidget {
  const _ProfileReadingListsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reading Stats Lists', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _statusButton(context, l10n.toRead, ReadingStatus.toRead),
                _statusButton(context, l10n.reading, ReadingStatus.reading),
                _statusButton(context, l10n.reReading, ReadingStatus.reReading),
                _statusButton(context, l10n.completed, ReadingStatus.completed),
                _statusButton(context, l10n.dropped, ReadingStatus.dropped),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const ReadingStatusListPage(showFavoritesOnly: true),
                    ),
                  ),
                  icon: const Icon(Icons.favorite_outline),
                  label: Text(l10n.favorites),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    String label,
    ReadingStatus status,
  ) {
    return FilledButton.tonalIcon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReadingStatusListPage(status: status),
        ),
      ),
      icon: const Icon(Icons.menu_book_outlined),
      label: Text(label),
    );
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
  late final TextEditingController _userName;
  late final TextEditingController _avatarUrl;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
    _userName = TextEditingController();
    _avatarUrl = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _userName.dispose();
    _avatarUrl.dispose();
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
          AppInput(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            labelText: l10n.email,
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          AppInput(
            controller: _password,
            obscureText: true,
            labelText: l10n.passwordMin6,
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          AppInput(
            controller: _userName,
            labelText: 'Kullanici adi',
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          AppInput(
            controller: _avatarUrl,
            keyboardType: TextInputType.url,
            labelText: 'Profil foto URL (opsiyonel)',
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
            final userName = _userName.text.trim();
            final avatarUrl = _avatarUrl.text.trim();
            if (email.isEmpty || password.length < 6 || userName.isEmpty) return;
            try {
              final container = ProviderScope.containerOf(context);
              await container.read(authServiceProvider).signUp(
                    email: email,
                    password: password,
                    displayName: userName,
                    avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final displayName = userDisplayName(user);
    final avatarUrl = userAvatarUrl(user);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? const Icon(Icons.person_outline) : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                user.email ?? AppLocalizations.of(context)!.signedInFallback,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.user});

  final User user;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _userName;
  late final TextEditingController _avatarUrl;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedAvatarBytes;
  XFile? _selectedAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _userName = TextEditingController(text: userDisplayName(widget.user));
    _avatarUrl = TextEditingController(text: userAvatarUrl(widget.user) ?? '');
  }

  @override
  void dispose() {
    _userName.dispose();
    _avatarUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAvatarBytes = _selectedAvatarBytes;
    final avatarInput = _avatarUrl.text.trim();
    return AlertDialog(
      title: const Text('Profili duzenle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundImage: selectedAvatarBytes != null
                ? MemoryImage(selectedAvatarBytes)
                : (avatarInput.isNotEmpty ? NetworkImage(avatarInput) : null),
            child: selectedAvatarBytes == null && avatarInput.isEmpty
                ? const Icon(Icons.person_outline)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickAvatarFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeriden foto sec'),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          AppInput(
            controller: _userName,
            labelText: 'Kullanici adi',
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          AppInput(
            controller: _avatarUrl,
            keyboardType: TextInputType.url,
            labelText: 'Profil foto URL (opsiyonel)',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final name = _userName.text.trim();
                  final avatar = _avatarUrl.text.trim();
                  if (name.isEmpty) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = AppLocalizations.of(context)!;
                  setState(() => _saving = true);
                  try {
                    final container = ProviderScope.containerOf(context);
                    String? avatarUrl = avatar.isEmpty ? null : avatar;
                    final pickedAvatar = _selectedAvatar;
                    if (pickedAvatar != null) {
                      final userId =
                          container.read(authServiceProvider).currentUser?.id;
                      if (userId == null) {
                        throw StateError('No signed-in user found.');
                      }
                      final bytes = await pickedAvatar.readAsBytes();
                      avatarUrl = await container
                          .read(authServiceProvider)
                          .uploadProfilePhoto(
                            userId: userId,
                            bytes: bytes,
                            fileName: pickedAvatar.name,
                          );
                    }
                    await container.read(authServiceProvider).updateProfile(
                          displayName: name,
                          avatarUrl: avatarUrl,
                        );
                    if (!mounted) return;
                    navigator.pop();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const AppLoadingIndicator(
                  size: 18,
                  strokeWidth: 2,
                  centered: false,
                )
              : const Text('Kaydet'),
        ),
      ],
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
        _avatarUrl.clear();
      });
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Galeri eklentisi yuklenemedi. Uygulamayi tam kapatip yeniden ac.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
      );
    }
  }
}
