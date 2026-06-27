import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/login_page.dart';
import '../../../auth/presentation/profile_page.dart';
import '../../../user_books/domain/entities/user_book_snapshot.dart';
import '../../../user_books/presentation/providers/user_books_provider.dart';

/// Puts a favorite control on the top-right of [child] (book cover).
class BookCoverWithFavoriteButton extends ConsumerWidget {
  const BookCoverWithFavoriteButton({
    super.key,
    required this.bookId,
    required this.child,
    this.compact = false,
    this.title,
    this.author,
    this.categories = const [],
    this.isFavorite,
  });

  final String bookId;
  final Widget child;
  final bool compact;
  final String? title;
  final String? author;
  final List<String> categories;
  /// When set, skips per-card [userBookProvider] read (home page bulk favorites).
  final bool? isFavorite;

  UserBookSnapshot? get _bookSnapshot {
    final resolvedTitle = title?.trim();
    final resolvedAuthor = author?.trim();
    if (resolvedTitle == null ||
        resolvedTitle.isEmpty ||
        resolvedAuthor == null ||
        resolvedAuthor.isEmpty) {
      return null;
    }
    return UserBookSnapshot(
      title: resolvedTitle,
      author: resolvedAuthor,
      categories: categories,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;
    final userBookAsync = isFavorite == null
        ? ref.watch(userBookProvider(bookId))
        : null;
    final resolvedFavorite =
        isFavorite ?? userBookAsync?.valueOrNull?.isFavorite ?? false;

    // Tight circle around the glyph (small padding for tap + ink).
    final iconSize = compact ? 16.0 : 20.0;
    final buttonSize = compact ? 22.0 : 26.0;
    final top = compact ? 2.0 : 6.0;
    final right = compact ? 2.0 : 6.0;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top,
          right: right,
          child: Tooltip(
            message: resolvedFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  if (user == null) {
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(builder: (_) => const LoginPage()),
                    );
                    return;
                  }
                  try {
                    await ref
                        .read(userBookProvider(bookId).notifier)
                        .toggleFavorite(snapshot: _bookSnapshot);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ProfilePage.authMessage(e, l10n))),
                    );
                  }
                },
                child: SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: iconSize,
                          color: AppColors.textPrimary,
                        ),
                        Icon(
                          resolvedFavorite ? Icons.favorite : Icons.favorite_border,
                          size: iconSize,
                          color: resolvedFavorite
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
