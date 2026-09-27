import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../providers/lists_providers.dart';
import '../widgets/list_card.dart';
import 'list_detail_page.dart';

/// Full-database search for lists, entered from the search bar on [ListsPage].
class ListSearchPage extends ConsumerStatefulWidget {
  const ListSearchPage({super.key});

  @override
  ConsumerState<ListSearchPage> createState() => _ListSearchPageState();
}

class _ListSearchPageState extends ConsumerState<ListSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(listSearchQueryProvider.notifier).state = raw.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasText = _controller.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.searchListsHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.lightOnSurface,
                  width: 1.5,
                ),
              ),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                        ref.read(listSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {});
              _onSearchChanged(value);
            },
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveScaffoldBody(child: const _ListSearchResults()),
      ),
    );
  }
}

class _ListSearchResults extends ConsumerWidget {
  const _ListSearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(listSearchQueryProvider);
    if (query.isEmpty) {
      return AppEmptyState(
        icon: Icons.search,
        title: l10n.searchListsHint,
      );
    }

    final async = ref.watch(listSearchResultsProvider);
    final userId = ref.watch(authStateProvider).valueOrNull?.id;

    void invalidate() => ref.invalidate(listSearchResultsProvider);

    return async.when(
      data: (lists) {
        if (lists.isEmpty) {
          return AppEmptyState(icon: Icons.search_off, title: l10n.noListsFound);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoCol =
                constraints.maxWidth >= AppBreakpoints.listsTwoColumnMinWidth;
            Widget cardFor(int index) {
              final list = lists[index];
              return ListCard(
                list: list,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => ListDetailPage(list: list)),
                  );
                  invalidate();
                },
                onLikeTap: () async {
                  if (userId == null) return;
                  if (list.isLikedByMe) {
                    await ref.read(listsRepositoryProvider).unlikeList(userId, list.id);
                  } else {
                    await ref.read(listsRepositoryProvider).likeList(userId, list.id);
                  }
                  invalidate();
                },
                onSaveTap: () async {
                  if (userId == null) return;
                  if (list.isSavedByMe) {
                    await ref.read(listsRepositoryProvider).unsaveList(userId, list.id);
                  } else {
                    await ref.read(listsRepositoryProvider).saveList(userId, list.id);
                  }
                  invalidate();
                },
              );
            }

            if (!twoCol) {
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: lists.length,
                itemBuilder: (context, index) => cardFor(index),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.45,
              ),
              itemCount: lists.length,
              itemBuilder: (context, index) => cardFor(index),
            );
          },
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => const AppSkeletonBox(height: 140),
      ),
      error: (e, _) => AsyncErrorView(error: e, onRetry: invalidate),
    );
  }
}
