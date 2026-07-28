import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/login_page.dart';
import '../widgets/virgil_brand_header.dart';
import '../widgets/virgil_colors.dart';
import 'virgil_about_book_page.dart';
import 'virgil_recommendation_page.dart';

/// Virgil hub: split screen with a horizontal rule at the vertical center.
///
/// The brand header is excluded from center-line math (same as the bottom tab
/// living outside this page). Midpoint is measured only in the remaining body.
///
/// Tap zones:
/// - From the tagline down to the center line → [VirgilRecommendationPage]
/// - From the center line down to the bottom tab → [VirgilAboutBookPage]
///
/// Only signed-in users can open either flow.
class VirgilHubPage extends ConsumerWidget {
  const VirgilHubPage({super.key});

  Future<void> _openRecommendation(BuildContext context, WidgetRef ref) async {
    if (!await _ensureSignedIn(context, ref)) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'virgil/recommendation'),
        builder: (_) => const VirgilRecommendationPage(),
      ),
    );
  }

  Future<void> _openAboutBook(BuildContext context, WidgetRef ref) async {
    if (!await _ensureSignedIn(context, ref)) return;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'virgil/qa'),
        builder: (_) => const VirgilAboutBookPage(),
      ),
    );
  }

  Future<bool> _ensureSignedIn(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) return true;
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.signInForVirgil)),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => const LoginPage(),
      ),
    );
    return ref.read(authStateProvider).valueOrNull != null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);

    return ColoredBox(
      color: colors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: VirgilBrandHeader.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VirgilBrandHeader(badge: l10n.virgilBetaBadge),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Midpoint of body only — header is outside this box.
                  final midY = constraints.maxHeight / 2;
                  return Stack(
                    children: [
                      // Upper hit area: tagline → center line
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: midY,
                        child: Material(
                          color: colors.paper,
                          child: InkWell(
                            onTap: () => _openRecommendation(context, ref),
                            splashColor: colors.ink.withValues(alpha: 0.06),
                            highlightColor: colors.ink.withValues(alpha: 0.03),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                0,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(
                                      l10n.virgilTagline,
                                      style: TextStyle(
                                        fontFamily: 'Quicksand',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        height: 1.35,
                                        color: colors.ink,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Column(
                                    children: [
                                      Text(
                                        l10n.virgilRecommendationHint,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w300,
                                          fontSize: 11,
                                          height: 1.35,
                                          color: colors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        l10n.virgilRecommendationTitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 32,
                                          height: 1.15,
                                          color: colors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Vertical center of body (header excluded)
                      Positioned(
                        top: midY - 0.5,
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        child: ColoredBox(
                          color: colors.ink,
                          child: const SizedBox(height: 1),
                        ),
                      ),

                      // Lower hit area: center line → bottom of body
                      Positioned(
                        top: midY,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: colors.paper,
                          child: InkWell(
                            onTap: () => _openAboutBook(context, ref),
                            splashColor: colors.ink.withValues(alpha: 0.06),
                            highlightColor: colors.ink.withValues(alpha: 0.03),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.md,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: Column(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        l10n.virgilAboutBookTitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 32,
                                          height: 1.15,
                                          color: colors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        l10n.virgilAboutBookHint,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w300,
                                          fontSize: 11,
                                          height: 1.35,
                                          color: colors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
