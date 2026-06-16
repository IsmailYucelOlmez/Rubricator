import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/layout/responsive_scaffold_body.dart';
import '../../../core/ux/l10n_app_error.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/async_error_view.dart';
import '../../habit/presentation/widgets/habit_profile_summary.dart';
import '../../favorites/presentation/pages/reading_status_list_page.dart';
import '../../profile/presentation/widgets/language_selector.dart';
import '../../profile/presentation/widgets/notification_selector.dart';
import '../../profile/presentation/widgets/theme_selector.dart';
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
    return SafeArea(
      child: ResponsiveScaffoldBody(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: authAsync.when(
          data: (user) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                user == null ? l10n.profile : l10n.profileZoneTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Nouveau',
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: AppSpacing.md),
                _ProfileHeader(user: user),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showEditProfileDialog(context, user),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          l10n.editProfile,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          await ref.read(authServiceProvider).signOut();
                        },
                        child: Text(
                          l10n.signOut,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const LanguageSelector(),
              const ThemeSelector(),
              const NotificationSelector(),
              if (user != null) const _ProfileReadingListsSection(),
              if (user == null) ...[
                const SizedBox(height: AppSpacing.md),
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
                const HabitProfileSummary(),
                const StatsPreviewCard(),
              ],
              ],
            ),
          ),
          loading: () => const AppLoadingIndicator(),
          error: (error, stackTrace) => AsyncErrorView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(authStateProvider),
          ),
        ),
        ),
      ),
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
    if (s.contains('Token has expired') ||
        s.contains('invalid') && s.toLowerCase().contains('otp') ||
        s.contains('recovery_failed')) {
      return l10n.invalidOrExpiredOtp;
    }
    if (s.contains('User already registered')) {
      return l10n.accountAlreadyExists;
    }
    if (s.contains('Bucket not found') || s.contains('profile-photos')) {
      return l10n.uxProfilePhotoStorageNotReady;
    }
    if (s.contains('row-level security') || s.contains('new row violates row-level security policy')) {
      return l10n.uxProfilePhotoPermissionDenied;
    }
    return l10n.userFacingMessage(e);
  }
}

class _ProfileReadingListsSection extends StatelessWidget {
  const _ProfileReadingListsSection();

  static const _buttonHeight = 40.0;
  static const _iconSize = 18.0;

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
            Text(l10n.readingStatsListsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _buttonRow(
              context,
              [
                _ReadingListButtonSpec(
                  label: l10n.toRead,
                  icon: Icons.menu_book_outlined,
                  onPressed: () => _openStatus(context, ReadingStatus.toRead),
                ),
                _ReadingListButtonSpec(
                  label: l10n.reading,
                  icon: Icons.menu_book_outlined,
                  onPressed: () => _openStatus(context, ReadingStatus.reading),
                ),
                _ReadingListButtonSpec(
                  label: l10n.reReading,
                  icon: Icons.menu_book_outlined,
                  onPressed: () => _openStatus(context, ReadingStatus.reReading),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buttonRow(
              context,
              [
                _ReadingListButtonSpec(
                  label: l10n.completed,
                  icon: Icons.menu_book_outlined,
                  onPressed: () => _openStatus(context, ReadingStatus.completed),
                ),
                _ReadingListButtonSpec(
                  label: l10n.dropped,
                  icon: Icons.menu_book_outlined,
                  onPressed: () => _openStatus(context, ReadingStatus.dropped),
                ),
                _ReadingListButtonSpec(
                  label: l10n.favorites,
                  icon: Icons.favorite_outline,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const ReadingStatusListPage(showFavoritesOnly: true),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _openStatus(BuildContext context, ReadingStatus status) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingStatusListPage(status: status),
      ),
    );
  }

  Widget _buttonRow(BuildContext context, List<_ReadingListButtonSpec> specs) {
    return Row(
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _fixedListButton(context, specs[i])),
        ],
      ],
    );
  }

  Widget _fixedListButton(BuildContext context, _ReadingListButtonSpec spec) {
    return SizedBox(
      height: _buttonHeight,
      width: double.infinity,
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, _buttonHeight),
          fixedSize: const Size.fromHeight(_buttonHeight),
        ),
        onPressed: spec.onPressed,
        icon: Icon(spec.icon, size: _iconSize),
        label: Text(
          spec.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ReadingListButtonSpec {
  const _ReadingListButtonSpec({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  static const _baseAvatarRadius = 24.0;
  static const _avatarScale = 2.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = userDisplayName(user);
    final avatarUrl = userAvatarUrl(user);
    final avatarRadius = _baseAvatarRadius * _avatarScale;

    final nameStyle = Theme.of(context).textTheme.titleMedium!;
    final emailStyle = Theme.of(context).textTheme.bodySmall!;
    final emailText = user.email ?? l10n.signedInFallback;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RoundNetworkAvatar(url: avatarUrl, radius: avatarRadius),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayName, style: nameStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(emailText, style: emailStyle),
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.editProfile),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedAvatarBytes != null)
            CircleAvatar(
              radius: 34,
              backgroundImage: MemoryImage(selectedAvatarBytes),
            )
          else
            _RoundNetworkAvatar(
              url: avatarInput.isEmpty ? null : avatarInput,
              radius: 34,
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickAvatarFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l10n.pickPhotoFromGallery),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          AppInput(
            controller: _userName,
            labelText: l10n.displayNameLabel,
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          AppInput(
            controller: _avatarUrl,
            keyboardType: TextInputType.url,
            labelText: l10n.profilePhotoUrlOptional,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
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
                  final loc = AppLocalizations.of(context)!;
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
                      SnackBar(content: Text(ProfilePage.authMessage(e, loc))),
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
              : Text(l10n.save),
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
        SnackBar(content: Text(l10n.uxGalleryPluginError)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
      );
    }
  }
}

/// Round avatar that renders network images through `Image.network` so that
/// Flutter web can fall back to an HTML `<img>` element when the image host
/// does not allow CORS canvas reads. `CircleAvatar.backgroundImage` uses
/// `DecorationImage`, which forces the Skia path and throws "Same-Origin
/// Policy" errors every frame for cross-origin images (e.g. Supabase Storage).
class _RoundNetworkAvatar extends StatelessWidget {
  const _RoundNetworkAvatar({required this.url, required this.radius});

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diameter = radius * 2;
    final placeholder = Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      color: scheme.primaryContainer,
      child: Icon(
        Icons.person_outline,
        size: radius,
        color: scheme.onPrimaryContainer,
      ),
    );
    final avatarUrl = url;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return ClipOval(child: placeholder);
    }
    return ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Image.network(
          avatarUrl,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return placeholder;
          },
        ),
      ),
    );
  }
}
