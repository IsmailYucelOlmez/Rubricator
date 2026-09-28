import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/book_cover_utils.dart';
import '../../../../../core/widgets/app_loading.dart';
import '../../../domain/entities/book_detail_entities.dart';
import '../../pages/author_detail_page.dart';
import '../../providers/books_providers.dart';
import 'book_detail_common.dart';

/// Cover, title, author and the community rating line.
class BookDetailHeader extends StatelessWidget {
  const BookDetailHeader({
    super.key,
    required this.book,
    required this.isPending,
  });

  /// Fixed height of the cover slot, so the layout never shifts while the
  /// cover is checked / loaded.
  static const coverHeight = 300.0;
  static const _coverAspectRatio = 2 / 3;

  /// Scroll offset after which the title has left the screen and the app
  /// bar shows it instead.
  static const titleRevealOffset = coverHeight + AppSpacing.md + 40;

  final BookEntity book;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Web can't tell Google's blank high-zoom "title page" fallback (zoom=2/3
    // for books without a scanned cover) from a real cover, so it keeps the
    // thumbnail the lists already show; native detects it by pixels and
    // upgrades to zoom=3 only when that image is a real cover.
    final coverUrl = kIsWeb
        ? AppConstants.bookThumbnailUrl(book.coverImageUrl)
        : AppConstants.bookDetailCoverUrl(book.coverImageUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            height: coverHeight,
            width: coverHeight * _coverAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: _BookDetailCover(url: coverUrl),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(book.title, style: theme.textTheme.headlineSmall),
        if (book.isUserSubmitted) ...[
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(l10n.userSubmittedBadgeLabel),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        _AuthorLine(book: book),
        const SizedBox(height: AppSpacing.xs),
        if (isPending)
          const AppSkeletonBox(width: 160, height: 20, borderRadius: 4)
        else
          _RatingSummaryLine(bookId: book.id),
      ],
    );
  }
}

class _AuthorLine extends StatelessWidget {
  const _AuthorLine({required this.book});

  final BookEntity book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (book.authorIds.isEmpty) {
      return Text(book.author, style: theme.textTheme.titleMedium);
    }
    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AuthorDetailPage(authorId: book.authorIds.first),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              book.author,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "★★★★☆ 4.2 (38 ratings)" — watches only the rating summary.
class _RatingSummaryLine extends ConsumerWidget {
  const _RatingSummaryLine({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = ref.watch(
      ratingProvider(bookId).select((s) => s.whenData((v) => v.summary)),
    );
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SizedBox(
      height: 20,
      child: switch (summary) {
        AsyncData(:final value) when value.count == 0 => Align(
          alignment: Alignment.centerLeft,
          child: Text(l10n.noRatingsYet, style: muted),
        ),
        AsyncData(:final value) => Semantics(
          label:
              '${l10n.rating}: ${formatStarRating(value.average)} / 5, '
              '${l10n.ratingCount(value.count)}',
          excludeSemantics: true,
          child: Row(
            children: [
              ReadOnlyStarRating(rating: value.average.round(), size: 16),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                formatStarRating(value.average),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('(${l10n.ratingCount(value.count)})', style: muted),
            ],
          ),
        ),
        AsyncError() => const SizedBox.shrink(),
        _ => const Align(
          alignment: Alignment.centerLeft,
          child: AppSkeletonBox(width: 160, height: 16, borderRadius: 4),
        ),
      },
    );
  }
}

/// Fills its (fixed-size) parent with the cover, a skeleton while the native
/// placeholder check runs, or a neutral placeholder when there's no usable
/// cover. It never changes size, so nothing below it jumps.
class _BookDetailCover extends StatefulWidget {
  const _BookDetailCover({required this.url});

  final String? url;

  @override
  State<_BookDetailCover> createState() => _BookDetailCoverState();
}

enum _CoverState { checking, ready, missing }

class _BookDetailCoverState extends State<_BookDetailCover> {
  _CoverState _state = _CoverState.checking;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stream == null) _precheckCover();
  }

  @override
  void didUpdateWidget(covariant _BookDetailCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _precheckCover();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _removeListener() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  void _precheckCover() {
    _removeListener();
    final url = widget.url;
    if (url == null) {
      _state = _CoverState.missing;
      return;
    }
    // The pixel-based placeholder check needs the image bytes, which on web
    // means an XHR — blocked by CORS for every cover host we use (Google
    // Books, kitapyurdu, dr). Web shows the cover through the HTML <img>
    // path instead; a genuinely broken image falls back via errorBuilder.
    if (kIsWeb) {
      _state = _CoverState.ready;
      return;
    }
    _state = _CoverState.checking;
    final stream = NetworkImage(
      url,
    ).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) async {
        final isPlaceholder = await looksLikePlaceholderCover(info.image);
        if (!mounted || widget.url != url) return;
        setState(
          () =>
              _state = isPlaceholder ? _CoverState.missing : _CoverState.ready,
        );
      },
      onError: (_, _) {
        if (!mounted || widget.url != url) return;
        setState(() => _state = _CoverState.missing);
      },
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _CoverState.checking => const AppSkeletonBox(borderRadius: 0),
      _CoverState.missing => const _CoverPlaceholder(),
      _CoverState.ready => Image.network(
        widget.url!,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _CoverPlaceholder(),
      ),
    };
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? Colors.grey.shade800 : cs.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 48,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
