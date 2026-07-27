import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/env.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/providers/book_resolve_providers.dart';
import '../../../semantic_discovery/domain/entities/semantic_book_result.dart';
import '../../../semantic_discovery/domain/entities/semantic_search_request.dart';
import '../../../semantic_discovery/presentation/providers/semantic_discovery_providers.dart';
import '../../data/datasources/virgil_usage_remote_datasource.dart';
import '../providers/virgil_usage_providers.dart';
import '../virgil_auth_guard.dart';
import '../widgets/virgil_brand_header.dart';
import '../widgets/virgil_colors.dart';

/// Route: `virgil/recommendation`
///
/// Deep-mode semantic recommendations (category filter only — no tone/emotion).
class VirgilRecommendationPage extends ConsumerStatefulWidget {
  const VirgilRecommendationPage({super.key});

  @override
  ConsumerState<VirgilRecommendationPage> createState() =>
      _VirgilRecommendationPageState();
}

class _VirgilRecommendationPageState
    extends ConsumerState<VirgilRecommendationPage> with RouteAware {
  static const _apiCategories = [
    'All',
    'Fiction',
    'Nonfiction',
    "Children's Fiction",
    "Children's Nonfiction",
  ];

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _activeQuery;
  bool _genrePanelOpen = false;

  @override
  void initState() {
    super.initState();
    // Deep mode only; clear any leftover tone from other entry points.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(semanticSearchFiltersProvider);
      ref.read(semanticSearchFiltersProvider.notifier).state = current.copyWith(
        mode: SemanticSearchMode.advanced,
        tone: 'All',
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _clearFocus();
  }

  void _clearFocus() {
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _submit() async {
    final query = _controller.text.trim();
    if (query.length < 3) return;

    final l10n = AppLocalizations.of(context)!;
    if (!await ensureVirgilSignedIn(context, ref)) return;
    if (!mounted) return;

    try {
      await ref.read(virgilUsageServiceProvider).consumeRecommendation();
    } on VirgilUsageLimitException catch (e) {
      if (!mounted) return;
      showVirgilSnackBar(context, virgilUsageLimitMessage(l10n, e));
      return;
    } catch (e) {
      if (!mounted) return;
      showVirgilSnackBar(context, e.toString());
      return;
    }
    if (!mounted) return;

    final filters = ref.read(semanticSearchFiltersProvider);
    ref.read(semanticSearchFiltersProvider.notifier).state = filters.copyWith(
      mode: SemanticSearchMode.advanced,
      tone: 'All',
    );
    _clearFocus();
    setState(() {
      _activeQuery = query;
      _genrePanelOpen = false;
    });
  }

  void _prefetchResolve(SemanticBookResult result) {
    ref.read(resolveBookProvider(result.toUnresolvedBook()));
  }

  void _openResult(BuildContext context, SemanticBookResult result) {
    _clearFocus();
    final unresolved = result.toUnresolvedBook();
    // Warm / reuse resolve cache; BookDetailPage awaits the same provider.
    ref.read(resolveBookProvider(unresolved));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailPage(book: unresolved),
      ),
    );
  }

  String _genreLabel(AppLocalizations l10n, String apiValue) {
    switch (apiValue) {
      case 'All':
        return l10n.virgilGenreAll;
      case 'Fiction':
        return l10n.virgilGenreFiction;
      case 'Nonfiction':
        return l10n.virgilGenreNonfiction;
      case "Children's Fiction":
        return l10n.virgilGenreChildrensFiction;
      case "Children's Nonfiction":
        return l10n.virgilGenreChildrensNonfiction;
      default:
        return apiValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);
    final filters = ref.watch(semanticSearchFiltersProvider);
    final activeQuery = _activeQuery;
    final searchEnabled = _controller.text.trim().length >= 3;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: !Env.hasSemanticApiConfig
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                l10n.semanticApiNotConfigured,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  color: colors.ink,
                                ),
                              ),
                            ),
                          )
                        : activeQuery == null
                            ? _EmptyBody(
                                body: l10n.virgilRecommendationEmptyBody,
                              )
                            : _ResultsBody(
                                query: activeQuery,
                                categoryLabel: filters.category == 'All'
                                    ? null
                                    : _genreLabel(l10n, filters.category),
                                onOpen: (result) =>
                                    _openResult(context, result),
                                onPrefetch: _prefetchResolve,
                              ),
                  ),
                  if (_genrePanelOpen)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: colors.paper,
                        child: _GenrePanel(
                          selected: filters.category,
                          labels: {
                            for (final value in _apiCategories)
                              value: _genreLabel(l10n, value),
                          },
                          onClose: () =>
                              setState(() => _genrePanelOpen = false),
                          onSelect: (category) {
                            ref
                                .read(semanticSearchFiltersProvider.notifier)
                                .state = filters.copyWith(
                              category: category,
                              mode: SemanticSearchMode.advanced,
                              tone: 'All',
                            );
                            if (activeQuery != null &&
                                activeQuery.length >= 3) {
                              ref.invalidate(
                                semanticSearchResultsProvider(activeQuery),
                              );
                            }
                          },
                          genreLabel: l10n.virgilGenreLabel,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _BottomBar(
              controller: _controller,
              focusNode: _focusNode,
              hintText: l10n.virgilRecommendationInputHint,
              searchEnabled: searchEnabled,
              genrePanelOpen: _genrePanelOpen,
              onChanged: (_) => setState(() {}),
              onToggleGenre: () =>
                  setState(() => _genrePanelOpen = !_genrePanelOpen),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Center(
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: 15,
            height: 1.45,
            color: colors.ink,
          ),
        ),
      ),
    );
  }
}

class _ResultsBody extends ConsumerWidget {
  const _ResultsBody({
    required this.query,
    required this.categoryLabel,
    required this.onOpen,
    required this.onPrefetch,
  });

  final String query;
  final String? categoryLabel;
  final void Function(SemanticBookResult result) onOpen;
  final void Function(SemanticBookResult result) onPrefetch;

  static const _prefetchCount = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);
    final results = ref.watch(semanticSearchResultsProvider(query));

    ref.listen(semanticSearchResultsProvider(query), (previous, next) {
      final books = next.asData?.value;
      if (books == null || books.isEmpty) return;
      if (identical(previous?.asData?.value, books)) return;
      for (final result in books.take(_prefetchCount)) {
        onPrefetch(result);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                query,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  height: 1.2,
                  color: colors.ink,
                ),
              ),
              if (categoryLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  categoryLabel!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: colors.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: results.when(
            loading: () => GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.lg,
                childAspectRatio: 0.58,
              ),
              itemCount: 6,
              itemBuilder: (_, index) => const _SkeletonCard(),
            ),
            error: (error, _) => AsyncErrorView(
              error: error,
              onRetry: () =>
                  ref.invalidate(semanticSearchResultsProvider(query)),
            ),
            data: (books) {
              if (books.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noBooksFoundFor(query),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: colors.ink,
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 0.58,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final result = books[index];
                  return _BookGridCard(
                    result: result,
                    onTap: () => onOpen(result),
                    onTapDown: () => onPrefetch(result),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookGridCard extends StatelessWidget {
  const _BookGridCard({
    required this.result,
    required this.onTap,
    required this.onTapDown,
  });

  final SemanticBookResult result;
  final VoidCallback onTap;
  final VoidCallback onTapDown;

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return InkWell(
      onTap: onTap,
      onTapDown: (_) => onTapDown(),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _CoverFillImage(coverImageUrl: result.coverImageUrl),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.25,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            result.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverFillImage extends StatelessWidget {
  const _CoverFillImage({this.coverImageUrl});

  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    final url = AppConstants.bookThumbnailUrl(coverImageUrl);
    if (url == null) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(
          child: Icon(Icons.menu_book_outlined, color: Color(0xFF9E9E9E)),
        ),
      );
    }
    return Image.network(
      url,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Colors.white,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF9E9E9E)),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: colors.coverBg,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: AppLoadingIndicator(size: 20, strokeWidth: 2, centered: false),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ColoredBox(color: colors.coverBg),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 14,
          width: double.infinity,
          color: colors.coverBg,
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          width: 80,
          color: colors.coverBg,
        ),
      ],
    );
  }
}

class _GenrePanel extends StatelessWidget {
  const _GenrePanel({
    required this.selected,
    required this.labels,
    required this.onClose,
    required this.onSelect,
    required this.genreLabel,
  });

  final String selected;
  final Map<String, String> labels;
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;
  final String genreLabel;

  static const _height = 63.0;
  static const _chipHeight = 22.5; // 18 * 1.25
  /// Design base 48/96 × 1.25
  static const _narrowChipWidth = 60.0;
  static const _wideChipWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    final entries = labels.entries.toList();

    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 24,
              child: Row(
                children: [
                  Text(
                    genreLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      height: 1,
                      color: colors.ink,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: _chipHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _GenreChip(
                        label: entries[i].value,
                        selected: selected == entries[i].key,
                        width: i < 3 ? _narrowChipWidth : _wideChipWidth,
                        onTap: () => onSelect(entries[i].key),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  static const _height = 22.5; // 18 * 1.25
  static const _radius = 6.25; // 5 * 1.25
  static const _fontSize = 11.25; // 9 * 1.25

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return Material(
      color: selected ? colors.ink : colors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(
          color: selected ? colors.ink : colors.ink.withValues(alpha: 0.55),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: SizedBox(
          width: width,
          height: _height,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w300,
                fontSize: _fontSize,
                height: 1,
                color: selected ? colors.paper : colors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.searchEnabled,
    required this.genrePanelOpen,
    required this.onChanged,
    required this.onToggleGenre,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool searchEnabled;
  final bool genrePanelOpen;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleGenre;
  final VoidCallback onSubmit;

  static const _sectionHeight = 64.0;
  static const _controlSize = 36.0;
  static const _gap = 17.0;
  static const _redBtnAsset = 'assets/Virgil/recommendation/redBtn.svg';

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return SizedBox(
      height: _sectionHeight,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: _controlSize,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                  child: Material(
                    color: colors.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: colors.ink,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => focusNode.requestFocus(),
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: onChanged,
                            textInputAction: TextInputAction.search,
                            textAlignVertical: TextAlignVertical.center,
                            cursorHeight: 14,
                            cursorColor: colors.ink,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1,
                              color: colors.ink,
                            ),
                            decoration: InputDecoration.collapsed(
                              hintText: hintText,
                              hintStyle: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w100,
                                fontSize: 12,
                                height: 1,
                                color: colors.muted,
                              ),
                            ),
                            onSubmitted: (_) {
                              if (searchEnabled) onSubmit();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            _CircleActionButton(
              filled: genrePanelOpen,
              fillColor: colors.ink,
              borderColor: colors.ink,
              icon: Icons.tune,
              iconColor: genrePanelOpen ? colors.paper : colors.ink,
              paper: colors.paper,
              onTap: onToggleGenre,
            ),
            const SizedBox(width: _gap),
            _RedSubmitButton(
              assetPath: _redBtnAsset,
              onTap: searchEnabled ? onSubmit : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.filled,
    required this.fillColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.paper,
    required this.onTap,
  });

  final bool filled;
  final Color fillColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final Color paper;
  final VoidCallback? onTap;

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: filled ? fillColor : paper,
        shape: CircleBorder(side: BorderSide(color: borderColor, width: 1)),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }
}

class _RedSubmitButton extends StatelessWidget {
  const _RedSubmitButton({
    required this.assetPath,
    required this.onTap,
  });

  final String assetPath;
  final VoidCallback? onTap;

  static const _size = 36.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SvgPicture.asset(
            assetPath,
            width: _size,
            height: _size,
          ),
        ),
      ),
    );
  }
}
