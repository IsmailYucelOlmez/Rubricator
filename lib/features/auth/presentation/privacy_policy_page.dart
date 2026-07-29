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
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.privacyPolicyMeta),
                const SizedBox(height: AppSpacing.md),
                _PolicySection(
                  title: l10n.privacyPolicySection1Title,
                  paragraphs: [
                    l10n.privacyPolicySection1Body1,
                    l10n.privacyPolicySection1Body2,
                    l10n.privacyPolicySection1Body3,
                  ],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection2Title,
                  content: [
                    _PolicySubsection(
                      title: l10n.privacyPolicySection21Title,
                      paragraphs: [l10n.privacyPolicySection21Body],
                      items: [
                        l10n.privacyPolicySection21Item1,
                        l10n.privacyPolicySection21Item2,
                        l10n.privacyPolicySection21Item3,
                        l10n.privacyPolicySection21Item4,
                      ],
                    ),
                    _PolicySubsection(
                      title: l10n.privacyPolicySection22Title,
                      items: [
                        l10n.privacyPolicySection22Item1,
                        l10n.privacyPolicySection22Item2,
                      ],
                    ),
                    _PolicySubsection(
                      title: l10n.privacyPolicySection23Title,
                      paragraphs: [l10n.privacyPolicySection23Body],
                      items: [
                        l10n.privacyPolicySection23Item1,
                        l10n.privacyPolicySection23Item2,
                        l10n.privacyPolicySection23Item3,
                        l10n.privacyPolicySection23Item4,
                        l10n.privacyPolicySection23Item5,
                        l10n.privacyPolicySection23Item6,
                        l10n.privacyPolicySection23Item7,
                        l10n.privacyPolicySection23Item8,
                      ],
                    ),
                    _PolicySubsection(
                      title: l10n.privacyPolicySection24Title,
                      paragraphs: [l10n.privacyPolicySection24Body],
                      items: [
                        l10n.privacyPolicySection24Item1,
                        l10n.privacyPolicySection24Item2,
                        l10n.privacyPolicySection24Item3,
                      ],
                      footnotes: [l10n.privacyPolicySection24Note],
                    ),
                    _PolicySubsection(
                      title: l10n.privacyPolicySection25Title,
                      paragraphs: [l10n.privacyPolicySection25Body],
                    ),
                    _PolicySubsection(
                      title: l10n.privacyPolicySection26Title,
                      items: [
                        l10n.privacyPolicySection26Item1,
                        l10n.privacyPolicySection26Item2,
                        l10n.privacyPolicySection26Item3,
                      ],
                    ),
                    _PolicySubsection(
                      title: l10n.privacyPolicySection27Title,
                      paragraphs: [l10n.privacyPolicySection27Body],
                      items: [
                        l10n.privacyPolicySection27Item1,
                        l10n.privacyPolicySection27Item2,
                        l10n.privacyPolicySection27Item3,
                        l10n.privacyPolicySection27Item4,
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
                    l10n.privacyPolicySection3Item6,
                    l10n.privacyPolicySection3Item7,
                    l10n.privacyPolicySection3Item8,
                  ],
                  trailingParagraphs: [l10n.privacyPolicySection3Body],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection4Title,
                  paragraphs: [l10n.privacyPolicySection4Body],
                  items: [
                    l10n.privacyPolicySection4Item1,
                    l10n.privacyPolicySection4Item2,
                    l10n.privacyPolicySection4Item3,
                    l10n.privacyPolicySection4Item4,
                  ],
                  trailingParagraphs: [l10n.privacyPolicySection4Body2],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection5Title,
                  paragraphs: [l10n.privacyPolicySection5Body],
                  items: [
                    l10n.privacyPolicySection5Item1,
                    l10n.privacyPolicySection5Item2,
                    l10n.privacyPolicySection5Item3,
                    l10n.privacyPolicySection5Item4,
                  ],
                  trailingParagraphs: [l10n.privacyPolicySection5Body2],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection6Title,
                  paragraphs: [l10n.privacyPolicySection6Body],
                  items: [
                    l10n.privacyPolicySection6Item1,
                    l10n.privacyPolicySection6Item2,
                    l10n.privacyPolicySection6Item3,
                  ],
                  trailingParagraphs: [l10n.privacyPolicySection6Body2],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection7Title,
                  items: [
                    l10n.privacyPolicySection7Item1,
                    l10n.privacyPolicySection7Item2,
                    l10n.privacyPolicySection7Item3,
                    l10n.privacyPolicySection7Item4,
                  ],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection8Title,
                  paragraphs: [l10n.privacyPolicySection8Body],
                  items: [
                    l10n.privacyPolicySection8Item1,
                    l10n.privacyPolicySection8Item2,
                    l10n.privacyPolicySection8Item3,
                    l10n.privacyPolicySection8Item4,
                    l10n.privacyPolicySection8Item5,
                    l10n.privacyPolicySection8Item6,
                    l10n.privacyPolicySection8Item7,
                    l10n.privacyPolicySection8Item8,
                  ],
                  trailingParagraphs: [l10n.privacyPolicySection8Body2],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection9Title,
                  paragraphs: [l10n.privacyPolicySection9Body1],
                  items: [
                    l10n.privacyPolicySection9Item1,
                    l10n.privacyPolicySection9Item2,
                    l10n.privacyPolicySection9Item3,
                  ],
                  trailingParagraphs: [l10n.privacyPolicySection9Body2],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection10Title,
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
                  paragraphs: [l10n.privacyPolicySection13Body],
                  items: [
                    l10n.privacyPolicySection13Item1,
                    l10n.privacyPolicySection13Item2,
                    l10n.privacyPolicySection13Item3,
                  ],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection14Title,
                  paragraphs: [l10n.privacyPolicySection14Body],
                ),
                _PolicySection(
                  title: l10n.privacyPolicySection15Title,
                  paragraphs: [
                    l10n.privacyPolicySection15Body,
                    l10n.privacyPolicySection15Contact,
                  ],
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
    this.trailingParagraphs = const [],
    this.content = const [],
  });

  final String title;
  final List<String> items;
  final List<String> paragraphs;
  final List<String> trailingParagraphs;
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
          if (trailingParagraphs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ..._intersperse(
              trailingParagraphs.map(Text.new).toList(),
              const SizedBox(height: AppSpacing.sm),
            ),
          ],
        ],
      ),
    );
  }
}

class _PolicySubsection extends StatelessWidget {
  const _PolicySubsection({
    required this.title,
    this.items = const [],
    this.paragraphs = const [],
    this.footnotes = const [],
  });

  final String title;
  final List<String> items;
  final List<String> paragraphs;
  final List<String> footnotes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        if (paragraphs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ..._intersperse(paragraphs.map(Text.new).toList(), const SizedBox(height: AppSpacing.xs)),
        ],
        ...items.map(Text.new),
        if (footnotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          ..._intersperse(footnotes.map(Text.new).toList(), const SizedBox(height: AppSpacing.xs)),
        ],
      ],
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
