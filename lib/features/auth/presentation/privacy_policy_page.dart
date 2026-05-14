import 'package:flutter/material.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/layout/responsive_scaffold_body.dart';
import '../../../core/theme/app_spacing.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicyAppBar)),
      body: SafeArea(
        child: ResponsiveScaffoldBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                l10n.privacyPolicyTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.privacyPolicyLastUpdated,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              _PolicySection(
                title: l10n.privacyPolicySection1Title,
                paragraphs: [l10n.privacyPolicySection1Body1, l10n.privacyPolicySection1Body2],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection2Title,
                content: [
                  _PolicySubsection(
                    title: l10n.privacyPolicySection21Title,
                    items: [
                      l10n.privacyPolicySection21Item1,
                      l10n.privacyPolicySection21Item2,
                      l10n.privacyPolicySection21Item3,
                    ],
                  ),
                  _PolicySubsection(
                    title: l10n.privacyPolicySection22Title,
                    items: [
                      l10n.privacyPolicySection22Item1,
                      l10n.privacyPolicySection22Item2,
                      l10n.privacyPolicySection22Item3,
                      l10n.privacyPolicySection22Item4,
                      l10n.privacyPolicySection22Item5,
                    ],
                  ),
                  _PolicySubsection(
                    title: l10n.privacyPolicySection23Title,
                    items: [
                      l10n.privacyPolicySection23Item1,
                      l10n.privacyPolicySection23Item2,
                      l10n.privacyPolicySection23Item3,
                    ],
                  ),
                  _PolicySubsection(
                    title: l10n.privacyPolicySection24Title,
                    items: [
                      l10n.privacyPolicySection24Item1,
                      l10n.privacyPolicySection24Item2,
                    ],
                  ),
                ],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection3Title,
                items: [
                  l10n.privacyPolicySection3Item1,
                  l10n.privacyPolicySection3Item2,
                  l10n.privacyPolicySection3Item3,
                  l10n.privacyPolicySection3Item4,
                  l10n.privacyPolicySection3Item5,
                ],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection4Title,
                paragraphs: [l10n.privacyPolicySection4Body],
                items: [
                  l10n.privacyPolicySection4Item1,
                  l10n.privacyPolicySection4Item2,
                  l10n.privacyPolicySection4Item3,
                ],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection5Title,
                paragraphs: [l10n.privacyPolicySection5Body],
                items: [
                  l10n.privacyPolicySection5Item1,
                  l10n.privacyPolicySection5Item2,
                  l10n.privacyPolicySection5Item3,
                ],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection6Title,
                items: [
                  l10n.privacyPolicySection6Item1,
                  l10n.privacyPolicySection6Item2,
                  l10n.privacyPolicySection6Item3,
                ],
                paragraphs: [l10n.privacyPolicySection6Body],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection7Title,
                items: [l10n.privacyPolicySection7Item1, l10n.privacyPolicySection7Item2],
                paragraphs: [l10n.privacyPolicySection7Body],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection8Title,
                items: [
                  l10n.privacyPolicySection8Item1,
                  l10n.privacyPolicySection8Item2,
                  l10n.privacyPolicySection8Item3,
                  l10n.privacyPolicySection8Item4,
                ],
                paragraphs: [l10n.privacyPolicySection8Body, l10n.privacyPolicySection8Email],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection9Title,
                paragraphs: [l10n.privacyPolicySection9Body1, l10n.privacyPolicySection9Body2],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection10Title,
                items: [l10n.privacyPolicySection10Item1, l10n.privacyPolicySection10Item2],
                paragraphs: [l10n.privacyPolicySection10Body],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection11Title,
                paragraphs: [l10n.privacyPolicySection11Body],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection12Title,
                paragraphs: [l10n.privacyPolicySection12Body],
              ),
              _PolicySection(
                title: l10n.privacyPolicySection13Title,
                paragraphs: [l10n.privacyPolicySection13Body, l10n.privacyPolicySection13Email],
              ),
              Text(l10n.privacyPolicyFooter),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    this.items = const [],
    this.paragraphs = const [],
    this.content = const [],
  });

  final String title;
  final List<String> items;
  final List<String> paragraphs;
  final List<Widget> content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PrivacyPolicyPage._sectionTitleStyle),
          const SizedBox(height: AppSpacing.sm),
          ..._intersperse(paragraphs.map(Text.new).toList(), const SizedBox(height: AppSpacing.sm)),
          if (paragraphs.isNotEmpty && items.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          ...items.map(Text.new),
          if ((paragraphs.isNotEmpty || items.isNotEmpty) && content.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          ..._intersperse(content, const SizedBox(height: AppSpacing.sm)),
        ],
      ),
    );
  }
}

class _PolicySubsection extends StatelessWidget {
  const _PolicySubsection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title), ...items.map(Text.new)],
    );
  }
}

List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
  if (widgets.length < 2) return widgets;
  final result = <Widget>[];
  for (var i = 0; i < widgets.length; i++) {
    if (i > 0) result.add(separator);
    result.add(widgets[i]);
  }
  return result;
}
