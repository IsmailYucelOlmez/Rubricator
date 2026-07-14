import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';

class SemanticFiltersSheet extends StatefulWidget {
  const SemanticFiltersSheet({
    super.key,
    required this.initialCategory,
    required this.initialTone,
  });

  final String initialCategory;
  final String initialTone;

  static Future<({String category, String tone})?> show(
    BuildContext context, {
    required String initialCategory,
    required String initialTone,
  }) {
    return showModalBottomSheet<({String category, String tone})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SemanticFiltersSheet(
        initialCategory: initialCategory,
        initialTone: initialTone,
      ),
    );
  }

  @override
  State<SemanticFiltersSheet> createState() => _SemanticFiltersSheetState();
}

class _SemanticFiltersSheetState extends State<SemanticFiltersSheet> {
  static const _categories = ['All', 'Fiction', 'Nonfiction'];
  static const _tones = [
    'All',
    'Happy',
    'Sad',
    'Suspenseful',
    'Angry',
    'Surprising',
  ];

  late String _category;
  late String _tone;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _tone = widget.initialTone;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.semanticFiltersTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.semanticCategoryLabel),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: _categories
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value),
                      selected: _category == value,
                      onSelected: (_) => setState(() => _category = value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.semanticToneLabel),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _tones
                  .map(
                    (value) => ChoiceChip(
                      label: Text(value),
                      selected: _tone == value,
                      onSelected: (_) => setState(() => _tone = value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    (category: _category, tone: _tone),
                  ),
                  child: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
