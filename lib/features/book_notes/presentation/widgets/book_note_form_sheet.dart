import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/book_note_entity.dart';

List<String> parseBookNoteTags(String raw) {
  return raw
      .split(RegExp(r'[,;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

int? parseBookNotePage(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

class BookNoteFormFields extends StatelessWidget {
  const BookNoteFormFields({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.pageController,
    required this.chapterController,
    required this.tagsController,
    required this.isPublic,
    required this.onPublicChanged,
    this.inputStyle,
    this.contentMaxLines = 6,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final TextEditingController pageController;
  final TextEditingController chapterController;
  final TextEditingController tagsController;
  final bool isPublic;
  final ValueChanged<bool> onPublicChanged;
  final TextStyle? inputStyle;
  final int contentMaxLines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleController,
          style: inputStyle,
          decoration: InputDecoration(hintText: l10n.noteTitleHint),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: contentController,
          style: inputStyle,
          decoration: InputDecoration(hintText: l10n.noteContentHint),
          minLines: 2,
          maxLines: contentMaxLines,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: pageController,
                style: inputStyle,
                decoration: InputDecoration(hintText: l10n.notePageHint),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: TextField(
                controller: chapterController,
                style: inputStyle,
                decoration: InputDecoration(hintText: l10n.noteChapterHint),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: tagsController,
          style: inputStyle,
          decoration: InputDecoration(hintText: l10n.noteTagsHint),
        ),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.publicNote),
          value: isPublic,
          onChanged: onPublicChanged,
        ),
      ],
    );
  }
}

class BookNoteFormSheet extends StatefulWidget {
  const BookNoteFormSheet({
    super.key,
    required this.bookId,
    this.initial,
    required this.onSubmit,
  });

  final String bookId;
  final BookNoteEntity? initial;
  final Future<void> Function({
    required String noteTitle,
    required String noteContent,
    int? pageNumber,
    String? chapterTitle,
    required List<String> tags,
    required bool isPublic,
  }) onSubmit;

  @override
  State<BookNoteFormSheet> createState() => _BookNoteFormSheetState();
}

class _BookNoteFormSheetState extends State<BookNoteFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _pageController;
  late final TextEditingController _chapterController;
  late final TextEditingController _tagsController;
  late bool _isPublic;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.noteTitle ?? '');
    _contentController = TextEditingController(text: initial?.noteContent ?? '');
    _pageController = TextEditingController(
      text: initial?.pageNumber?.toString() ?? '',
    );
    _chapterController = TextEditingController(
      text: initial?.chapterTitle ?? '',
    );
    _tagsController = TextEditingController(
      text: initial?.tags.join(', ') ?? '',
    );
    _isPublic = initial?.isPublic ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _pageController.dispose();
    _chapterController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        noteTitle: _titleController.text,
        noteContent: _contentController.text,
        pageNumber: parseBookNotePage(_pageController.text),
        chapterTitle: _chapterController.text.trim().isEmpty
            ? null
            : _chapterController.text.trim(),
        tags: parseBookNoteTags(_tagsController.text),
        isPublic: _isPublic,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.initial != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? l10n.editNote : l10n.addNote,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: BookNoteFormFields(
                titleController: _titleController,
                contentController: _contentController,
                pageController: _pageController,
                chapterController: _chapterController,
                tagsController: _tagsController,
                isPublic: _isPublic,
                onPublicChanged: (value) => setState(() => _isPublic = value),
                contentMaxLines: 8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEditing ? l10n.save : l10n.addNote),
          ),
        ],
      ),
    );
  }
}

Future<void> showBookNoteFormSheet(
  BuildContext context, {
  required String bookId,
  BookNoteEntity? initial,
  required Future<void> Function({
    required String noteTitle,
    required String noteContent,
    int? pageNumber,
    String? chapterTitle,
    required List<String> tags,
    required bool isPublic,
  }) onSubmit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      final preferredHeight = (mq.size.height * 0.58).clamp(420.0, 560.0);
      final maxSheetHeight = mq.size.height - mq.viewInsets.bottom - 24;
      final sheetHeight = preferredHeight.clamp(280.0, maxSheetHeight);

      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SizedBox(
          height: sheetHeight,
          child: SafeArea(
            top: false,
            child: BookNoteFormSheet(
              bookId: bookId,
              initial: initial,
              onSubmit: onSubmit,
            ),
          ),
        ),
      );
    },
  );
}
