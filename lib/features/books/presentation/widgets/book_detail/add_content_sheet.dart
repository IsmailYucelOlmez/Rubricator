import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../book_notes/presentation/providers/book_notes_providers.dart';
import '../../../../book_notes/presentation/widgets/book_note_form_sheet.dart';
import '../../providers/books_providers.dart';
import 'book_content_tabs.dart';
import 'book_detail_common.dart';
import 'reviews_sliver.dart';

/// Bottom sheet for adding a review (app or external), note or quote,
/// opened on [initialTab]. Closes itself on success.
Future<void> showAddContentSheet(
  BuildContext context, {
  required String bookId,
  required BookContentTab initialTab,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      final keyboard = mq.viewInsets.bottom;
      final preferredHeight = (mq.size.height * 0.58).clamp(420.0, 560.0);
      final maxHeight = (mq.size.height - keyboard - 24).clamp(
        200.0,
        mq.size.height,
      );
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: preferredHeight > maxHeight ? maxHeight : preferredHeight,
          // Own Scaffold so validation snackbars show above the sheet.
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              top: false,
              child: _AddContentSheet(bookId: bookId, initialTab: initialTab),
            ),
          ),
        ),
      );
    },
  );
}

class _AddContentSheet extends ConsumerStatefulWidget {
  const _AddContentSheet({required this.bookId, required this.initialTab});

  final String bookId;
  final BookContentTab initialTab;

  @override
  ConsumerState<_AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends ConsumerState<_AddContentSheet> {
  final _review = TextEditingController();
  final _externalTitle = TextEditingController();
  final _externalUrl = TextEditingController();
  final _externalDescription = TextEditingController();
  final _quote = TextEditingController();
  final _noteTitle = TextEditingController();
  final _noteContent = TextEditingController();
  final _notePage = TextEditingController();
  final _noteChapter = TextEditingController();
  final _noteTags = TextEditingController();

  late bool _external = ref.read(reviewsShowExternalProvider(widget.bookId));
  bool _isSpoiler = false;
  bool _isPublicNote = false;
  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in [
      _review,
      _externalTitle,
      _externalUrl,
      _externalDescription,
      _quote,
      _noteTitle,
      _noteContent,
      _notePage,
      _noteChapter,
      _noteTags,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Runs [action]; on success closes the sheet and shows [successMessage]
  /// on the page, on failure keeps the sheet (and the draft) open.
  Future<void> _submit(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await action();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (mounted) showBookDetailError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _addReview() {
    final l10n = AppLocalizations.of(context)!;
    if (_external) {
      _submit(() async {
        await ref
            .read(externalReviewProvider(widget.bookId).notifier)
            .add(
              title: _externalTitle.text,
              url: _externalUrl.text,
              description: _externalDescription.text,
            );
        ref.read(reviewsShowExternalProvider(widget.bookId).notifier).state =
            true;
      }, l10n.externalReviewAdded);
    } else {
      _submit(
        () => ref
            .read(reviewListProvider(widget.bookId).notifier)
            .add(_review.text, isSpoiler: _isSpoiler),
        l10n.reviewAdded,
      );
    }
  }

  void _addNote() {
    final chapter = _noteChapter.text.trim();
    _submit(
      () => ref
          .read(publicBookNotesProvider(widget.bookId).notifier)
          .addNote(
            noteTitle: _noteTitle.text,
            noteContent: _noteContent.text,
            pageNumber: parseBookNotePage(_notePage.text),
            chapterTitle: chapter.isEmpty ? null : chapter,
            tags: parseBookNoteTags(_noteTags.text),
            isPublic: _isPublicNote,
          ),
      AppLocalizations.of(context)!.noteAdded,
    );
  }

  void _addQuote() {
    _submit(
      () => ref.read(quoteProvider(widget.bookId).notifier).add(_quote.text),
      AppLocalizations.of(context)!.quoteAdded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: BookContentTab.values.length,
      initialIndex: widget.initialTab.index,
      child: Column(
        children: [
          TabBar(
            tabAlignment: TabAlignment.fill,
            tabs: [
              Tab(text: l10n.reviews),
              Tab(text: l10n.notes),
              Tab(text: l10n.quotes),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SheetTab(
                  button: BusyFilledButton(
                    busy: _submitting,
                    onPressed: _addReview,
                    label: _external ? l10n.addExternalReview : l10n.addReview,
                  ),
                  children: [
                    ReviewSourceToggle(
                      showExternal: _external,
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() => _external = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_external) ...[
                      _field(_externalTitle, hint: l10n.reviewTitle),
                      const SizedBox(height: AppSpacing.sm),
                      _field(
                        _externalDescription,
                        hint: l10n.description,
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _field(
                        _externalUrl,
                        hint: l10n.reviewUrlHint,
                        keyboardType: TextInputType.url,
                      ),
                    ] else ...[
                      _field(
                        _review,
                        hint: l10n.writeReviewHint,
                        minLines: 2,
                        maxLines: 6,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      CompactCheckbox(
                        label: l10n.containsSpoilers,
                        value: _isSpoiler,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _isSpoiler = value),
                      ),
                    ],
                  ],
                ),
                _SheetTab(
                  button: BusyFilledButton(
                    busy: _submitting,
                    onPressed: _addNote,
                    label: l10n.addNote,
                  ),
                  children: [
                    AbsorbPointer(
                      absorbing: _submitting,
                      child: BookNoteFormFields(
                        titleController: _noteTitle,
                        contentController: _noteContent,
                        pageController: _notePage,
                        chapterController: _noteChapter,
                        tagsController: _noteTags,
                        isPublic: _isPublicNote,
                        onPublicChanged: (value) =>
                            setState(() => _isPublicNote = value),
                        inputStyle: bookDetailInputStyle(context),
                        contentMaxLines: 4,
                      ),
                    ),
                  ],
                ),
                _SheetTab(
                  button: BusyFilledButton(
                    busy: _submitting,
                    onPressed: _addQuote,
                    label: l10n.addQuote,
                  ),
                  children: [
                    _field(
                      _quote,
                      hint: l10n.addMemorableQuote,
                      minLines: 2,
                      maxLines: 6,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String hint,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: !_submitting,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: bookDetailInputStyle(context),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

/// Scrollable form fields with the submit button pinned below.
class _SheetTab extends StatelessWidget {
  const _SheetTab({required this.children, required this.button});

  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          button,
        ],
      ),
    );
  }
}
