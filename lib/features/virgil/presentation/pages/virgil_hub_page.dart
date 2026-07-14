import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
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
class VirgilHubPage extends StatelessWidget {
  const VirgilHubPage({super.key});

  static const _ink = Color(0xFF000000);
  static const _paper = Color(0xFFFFFFFF);
  static const double _headerHeight = 64;

  void _openRecommendation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'virgil/recommendation'),
        builder: (_) => const VirgilRecommendationPage(),
      ),
    );
  }

  void _openAboutBook(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'virgil/aboutbook'),
        builder: (_) => const VirgilAboutBookPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ColoredBox(
      color: _paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _headerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _VirgilBrandRow(badge: l10n.virgilBetaBadge),
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
                          color: _paper,
                          child: InkWell(
                            onTap: () => _openRecommendation(context),
                            splashColor: _ink.withValues(alpha: 0.06),
                            highlightColor: _ink.withValues(alpha: 0.03),
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
                                      style: const TextStyle(
                                        fontFamily: 'Quicksand',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        height: 1.35,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Column(
                                    children: [
                                      Text(
                                        l10n.virgilRecommendationHint,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w300,
                                          fontSize: 11,
                                          height: 1.35,
                                          color: _ink,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        l10n.virgilRecommendationTitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 32,
                                          height: 1.15,
                                          color: _ink,
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
                        child: const ColoredBox(
                          color: _ink,
                          child: SizedBox(height: 1),
                        ),
                      ),

                      // Lower hit area: center line → bottom of body
                      Positioned(
                        top: midY,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: _paper,
                          child: InkWell(
                            onTap: () => _openAboutBook(context),
                            splashColor: _ink.withValues(alpha: 0.06),
                            highlightColor: _ink.withValues(alpha: 0.03),
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
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 32,
                                          height: 1.15,
                                          color: _ink,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        l10n.virgilAboutBookHint,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.w300,
                                          fontSize: 11,
                                          height: 1.35,
                                          color: _ink,
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

class _VirgilBrandRow extends StatelessWidget {
  const _VirgilBrandRow({required this.badge});

  final String badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Virgil',
          style: TextStyle(
            fontFamily: 'Megrim',
            fontSize: 40,
            height: 1,
            letterSpacing: 2,
            color: VirgilHubPage._ink,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 24,
          height: 12,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: VirgilHubPage._ink, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            badge.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Megrim',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0.2,
              color: VirgilHubPage._ink,
            ),
          ),
        ),
      ],
    );
  }
}
