import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';

class DocumentChatInputBar extends StatefulWidget {
  const DocumentChatInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
  });

  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  State<DocumentChatInputBar> createState() => _DocumentChatInputBarState();
}

class _DocumentChatInputBarState extends State<DocumentChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.enabled) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSend = widget.enabled && _controller.text.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(
              hintText: l10n.documentChatAskPlaceholder,
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          onPressed: canSend ? _submit : null,
          icon: const Icon(Icons.send),
          tooltip: l10n.documentChatAskPlaceholder,
        ),
      ],
    );
  }
}
