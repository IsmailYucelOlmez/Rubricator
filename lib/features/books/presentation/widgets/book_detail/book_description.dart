import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/utils/text_utils.dart';
import 'book_detail_common.dart';

/// Book description clamped to [collapsedLines] with a "Read more" toggle
/// that only appears when the text actually overflows.
class BookDescription extends StatefulWidget {
  const BookDescription({
    super.key,
    required this.description,
    this.collapsedLines = 6,
  });

  /// May contain HTML (Google Books); tags are stripped once per change.
  final String description;
  final int collapsedLines;

  @override
  State<BookDescription> createState() => _BookDescriptionState();
}

class _BookDescriptionState extends State<BookDescription> {
  late String _text = stripHtmlTags(widget.description);
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant BookDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description) {
      _text = stripHtmlTags(widget.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = bookDetailBodyStyle(context).copyWith(height: 1.45);
    if (_text.isEmpty) {
      return Text(l10n.noDescriptionAvailable, style: style);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: _text, style: style),
          maxLines: widget.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: Text(
                _text,
                style: style,
                maxLines: _expanded ? null : widget.collapsedLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
              ),
            ),
            if (overflows)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                ),
                child: Text(_expanded ? l10n.showLess : l10n.readMore),
              ),
          ],
        );
      },
    );
  }
}
