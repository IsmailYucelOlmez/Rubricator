import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_loading.dart';
import '../../../../../core/widgets/async_error_view.dart';
import 'book_detail_common.dart';

/// Lazily built list for one content tab, with loading / empty / error
/// states sized so switching tabs doesn't collapse the page.
class ContentListSliver<T> extends StatelessWidget {
  const ContentListSliver({
    super.key,
    required this.value,
    required this.emptyText,
    required this.onRetry,
    required this.itemBuilder,
    this.onLastItemBuilt,
    this.showLoadingMore = false,
  });

  static const _stateMinHeight = 160.0;

  final AsyncValue<List<T>> value;
  final String emptyText;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Called when the last item is laid out, i.e. it's within the cache
  /// extent — used for loading the next page.
  final VoidCallback? onLastItemBuilt;
  final bool showLoadingMore;

  @override
  Widget build(BuildContext context) {
    Widget state(Widget child) => SliverToBoxAdapter(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _stateMinHeight),
        child: Center(child: child),
      ),
    );

    return switch (value) {
      AsyncData(:final value) when value.isEmpty => state(
        Text(
          emptyText,
          textAlign: TextAlign.center,
          style: bookDetailBodyStyle(context),
        ),
      ),
      AsyncValue(:final valueOrNull?) => SliverList.separated(
        itemCount: valueOrNull.length + (showLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index >= valueOrNull.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppLoadingIndicator(),
            );
          }
          if (index == valueOrNull.length - 1 && onLastItemBuilt != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onLastItemBuilt!(),
            );
          }
          return itemBuilder(context, valueOrNull[index]);
        },
      ),
      AsyncError(:final error) => state(
        AsyncErrorView(error: error, compact: true, onRetry: onRetry),
      ),
      _ => state(const AppLoadingIndicator()),
    };
  }
}
