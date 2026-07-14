import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class SemanticSearchBar extends StatelessWidget {
  const SemanticSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.searchLabel,
    required this.searchEnabled,
    required this.onChanged,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String hintText;
  final String searchLabel;
  final bool searchEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.auto_awesome_outlined),
            ),
            textInputAction: TextInputAction.search,
            maxLines: 2,
            minLines: 1,
            onChanged: onChanged,
            onSubmitted: (_) {
              if (searchEnabled) onSearch();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton(
          onPressed: searchEnabled ? onSearch : null,
          child: Text(searchLabel),
        ),
      ],
    );
  }
}

class SemanticFiltersRow extends StatelessWidget {
  const SemanticFiltersRow({
    super.key,
    required this.category,
    required this.tone,
    required this.onFiltersTap,
    required this.filtersLabel,
  });

  final String category;
  final String tone;
  final VoidCallback onFiltersTap;
  final String filtersLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = category != 'All' || tone != 'All';
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onFiltersTap,
        icon: Icon(
          Icons.tune,
          size: 18,
          color: hasFilters ? theme.colorScheme.primary : null,
        ),
        label: Text(
          hasFilters ? '$filtersLabel: $category · $tone' : filtersLabel,
        ),
      ),
    );
  }
}
