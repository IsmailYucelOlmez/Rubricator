import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/navigation/web_page_title.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/sign_in_guard.dart';
import '../../domain/entities/list_entities.dart';
import '../providers/lists_providers.dart';
import '../widgets/list_card.dart';
import 'list_detail_page.dart';

/// Public lists (plus the viewer's own) that contain a book, most liked
/// first. Opened from the book detail page.
class BookListsPage extends ConsumerWidget {
  const BookListsPage({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  final String bookId;
  final String bookTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(listsContainingBookProvider(bookId));

    void refresh() {
      ref.invalidate(listsContainingBookProvider(bookId));
      ref.invalidate(listsContainingBookCountProvider(bookId));
    }

    Future<void> toggle(
      ListEntity list, {
      required bool active,
      required Future<void> Function(String userId) on,
      required Future<void> Function(String userId) off,
    }) async {
      if (!await ensureSignedIn(context, ref)) return;
      final userId = ref.read(authStateProvider).valueOrNull?.id;
      if (userId == null) return;
      try {
        await (active ? off(userId) : on(userId));
      } catch (e) {
        if (context.mounted) AppFeedback.showErrorSnackBar(context, e);
      }
      refresh();
    }

    Widget cardFor(ListEntity list) {
      final repo = ref.read(listsRepositoryProvider);
      return ListCard(
        list: list,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ListDetailPage(list: list)),
          );
          refresh();
        },
        onLikeTap: () => toggle(
          list,
          active: list.isLikedByMe,
          on: (userId) => repo.likeList(userId, list.id),
          off: (userId) => repo.unlikeList(userId, list.id),
        ),
        onSaveTap: () => toggle(
          list,
          active: list.isSavedByMe,
          on: (userId) => repo.saveList(userId, list.id),
          off: (userId) => repo.unsaveList(userId, list.id),
        ),
      );
    }

    final Widget body = switch (async) {
      AsyncValue(:final valueOrNull?) when valueOrNull.isEmpty => AppEmptyState(
        icon: Icons.playlist_remove,
        title: l10n.noListsContainBook,
      ),
      AsyncValue(:final valueOrNull?) => RefreshIndicator(
        onRefresh: () async {
          refresh();
          await ref.read(listsContainingBookProvider(bookId).future);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoCol =
                constraints.maxWidth >= AppBreakpoints.listsTwoColumnMinWidth;
            if (!twoCol) {
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: valueOrNull.length,
                itemBuilder: (context, index) => cardFor(valueOrNull[index]),
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
              itemCount: valueOrNull.length,
              itemBuilder: (context, index) => cardFor(valueOrNull[index]),
            );
          },
        ),
      ),
      AsyncError(:final error) => AsyncErrorView(
        error: error,
        onRetry: refresh,
      ),
      _ => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => const AppSkeletonBox(height: 140),
      ),
    };

    return WebPageTitle(
      label: '${l10n.listsContainingBook} · $bookTitle · Rubricator',
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.listsContainingBook),
              Text(
                bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(top: false, child: ResponsiveScaffoldBody(child: body)),
      ),
    );
  }
}
