import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/env.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/providers/book_resolve_providers.dart';
import '../../domain/entities/semantic_book_result.dart';
import '../../domain/entities/semantic_search_request.dart';
import '../providers/semantic_discovery_providers.dart';
import '../widgets/semantic_filters_sheet.dart';
import '../widgets/semantic_result_card.dart';
import '../widgets/semantic_search_bar.dart';

class SemanticDiscoveryView extends ConsumerStatefulWidget {
  const SemanticDiscoveryView({super.key});

  @override
  ConsumerState<SemanticDiscoveryView> createState() =>
      _SemanticDiscoveryViewState();
}

class _SemanticDiscoveryViewState extends ConsumerState<SemanticDiscoveryView> {
  final _controller = TextEditingController();
  String? _activeQuery;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.length < 3) return;
    setState(() => _activeQuery = query);
  }

  Future<void> _openResult(BuildContext context, SemanticBookResult result) async {
    final unresolved = result.toUnresolvedBook();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingIndicator()),
    );
    try {
      final resolved = await ref.read(resolveBookUseCaseProvider).call(unresolved);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookDetailPage(book: resolved),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookDetailPage(book: unresolved),
        ),
      );
    }
  }

  Future<void> _openFilters() async {
    final filters = ref.read(semanticSearchFiltersProvider);
    final updated = await SemanticFiltersSheet.show(
      context,
      initialCategory: filters.category,
      initialTone: filters.tone,
    );
    if (updated == null) return;
    ref.read(semanticSearchFiltersProvider.notifier).state =
        filters.copyWith(category: updated.category, tone: updated.tone);
    final query = _activeQuery;
    if (query != null && query.length >= 3) {
      ref.invalidate(semanticSearchResultsProvider(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = ref.watch(semanticSearchFiltersProvider);

    if (!Env.hasSemanticApiConfig) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            l10n.semanticApiNotConfigured,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final activeQuery = _activeQuery;
    final searchEnabled = _controller.text.trim().length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SemanticSearchBar(
          controller: _controller,
          hintText: l10n.semanticSearchHint,
          searchLabel: l10n.search,
          searchEnabled: searchEnabled,
          onChanged: (_) => setState(() {}),
          onSearch: _submit,
        ),
        SemanticFiltersRow(
          category: filters.category,
          tone: filters.tone,
          onFiltersTap: _openFilters,
          filtersLabel: l10n.semanticFiltersTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: l10n.semanticModeAdvancedHint,
          child: SegmentedButton<SemanticSearchMode>(
            segments: [
              ButtonSegment(
                value: SemanticSearchMode.simple,
                label: Text(l10n.semanticModeSimple),
                icon: const Icon(Icons.bolt_outlined, size: 18),
              ),
              ButtonSegment(
                value: SemanticSearchMode.advanced,
                label: Text(l10n.semanticModeAdvanced),
                icon: const Icon(Icons.auto_awesome, size: 18),
              ),
            ],
            selected: {filters.mode},
            onSelectionChanged: (selected) {
              final mode = selected.first;
              ref.read(semanticSearchFiltersProvider.notifier).state =
                  filters.copyWith(mode: mode);
              final query = _activeQuery;
              if (query != null && query.length >= 3) {
                ref.invalidate(semanticSearchResultsProvider(query));
              }
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: activeQuery == null
              ? Center(
                  child: Text(
                    l10n.semanticSearchMinHint,
                    textAlign: TextAlign.center,
                  ),
                )
              : _SemanticResultsList(
                  query: activeQuery,
                  onOpen: (result) => _openResult(context, result),
                ),
        ),
      ],
    );
  }
}

class _SemanticResultsList extends ConsumerWidget {
  const _SemanticResultsList({
    required this.query,
    required this.onOpen,
  });

  final String query;
  final void Function(SemanticBookResult result) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(semanticSearchResultsProvider(query));

    return results.when(
      loading: () => ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, index) => const Divider(height: 1),
        itemBuilder: (_, index) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: AppListTileSkeleton(),
        ),
      ),
      error: (error, _) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(semanticSearchResultsProvider(query)),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Center(child: Text(l10n.noBooksFoundFor(query)));
        }
        return ListView.separated(
          itemCount: books.length,
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = books[index];
            return SemanticResultCard(
              result: result,
              onTap: () => onOpen(result),
            );
          },
        );
      },
    );
  }
}
