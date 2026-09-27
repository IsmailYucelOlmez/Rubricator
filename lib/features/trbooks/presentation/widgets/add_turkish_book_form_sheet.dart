import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../../books/presentation/widgets/book_cover_leading.dart';
import '../../domain/usecases/trbooks_submission_exceptions.dart';
import '../providers/trbooks_providers.dart';
import 'add_turkish_book_feedback.dart';

class AddTurkishBookFormSheet extends ConsumerStatefulWidget {
  const AddTurkishBookFormSheet({super.key});

  @override
  ConsumerState<AddTurkishBookFormSheet> createState() => _AddTurkishBookFormSheetState();
}

class _AddTurkishBookFormSheetState extends ConsumerState<AddTurkishBookFormSheet> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _publisherController = TextEditingController();
  final _categoryController = TextEditingController();

  Timer? _previewDebounce;
  String? _previewUrl;
  String? _isbnError;
  bool _submitting = false;
  bool _generatingDescription = false;
  bool _moreDetailsExpanded = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_titleController, _authorController, _isbnController]) {
      controller.addListener(_onRequiredFieldsChanged);
    }
    _imageUrlController.addListener(_onImageUrlChanged);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _publisherController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _onRequiredFieldsChanged() => setState(() {});

  void _onImageUrlChanged() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _previewUrl = _imageUrlController.text.trim());
    });
  }

  bool get _canGenerateDescription =>
      _titleController.text.trim().isNotEmpty &&
      _authorController.text.trim().isNotEmpty &&
      _normalizedIsbnLength(_isbnController.text) != null;

  int? _normalizedIsbnLength(String raw) {
    final normalized = raw.replaceAll(RegExp(r'[^0-9Xx]'), '');
    return normalized.length == 10 || normalized.length == 13 ? normalized.length : null;
  }

  Future<void> _generateDescription() async {
    if (_generatingDescription || !_canGenerateDescription) return;
    setState(() => _generatingDescription = true);
    try {
      final description = await ref.read(generateTrbookDescriptionUseCaseProvider).call(
            title: _titleController.text,
            author: _authorController.text,
            isbn: _isbnController.text,
          );
      if (!mounted) return;
      setState(() {
        _descriptionController.text = description;
        _moreDetailsExpanded = true;
      });
    } catch (e) {
      if (mounted) showAddTurkishBookFeedback(context, e);
    } finally {
      if (mounted) setState(() => _generatingDescription = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _isbnError = null;
    });
    try {
      final book = await ref.read(submitUserTrbookUseCaseProvider).call(
            title: _titleController.text,
            author: _authorController.text,
            isbn: _isbnController.text,
            description: _descriptionController.text,
            imageUrl: _imageUrlController.text,
            publisher: _publisherController.text,
            category: _categoryController.text,
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book)),
      );
      Navigator.of(context).pop();
    } on TrbooksDuplicateIsbnException catch (e) {
      if (!mounted) return;
      await _offerOpenExisting(e.existingId);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (e is TrbooksValidationException && e.message.contains('ISBN')) {
        setState(() => _isbnError = l10n.addTurkishBookIsbnInvalid);
      } else {
        showAddTurkishBookFeedback(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _offerOpenExisting(String existingId) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.addTurkishBookDuplicate),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.addTurkishBookOpenExisting),
          ),
        ],
      ),
    );
    if (shouldOpen != true || !mounted) return;
    try {
      final book = await ref.read(resolveBookByIdUseCaseProvider).call(existingId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showAddTurkishBookFeedback(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addTurkishBookTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(hintText: l10n.addTurkishBookTitleHint),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _authorController,
                    decoration: InputDecoration(hintText: l10n.addTurkishBookAuthorHint),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _isbnController,
                    decoration: InputDecoration(
                      hintText: l10n.addTurkishBookIsbnHint,
                      errorText: _isbnError,
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () => setState(() => _moreDetailsExpanded = !_moreDetailsExpanded),
                    child: Row(
                      children: [
                        Text(l10n.addTurkishBookMoreDetails),
                        Icon(
                          _moreDetailsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                  if (_moreDetailsExpanded) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: l10n.addTurkishBookDescriptionHint,
                      ),
                      minLines: 2,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _canGenerateDescription && !_generatingDescription
                            ? _generateDescription
                            : null,
                        icon: _generatingDescription
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: AppLoadingIndicator(
                                  size: 16,
                                  strokeWidth: 2,
                                  centered: false,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(l10n.addTurkishBookGenerateDescription),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        hintText: l10n.addTurkishBookImageUrlHint,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    if (_previewUrl != null && _previewUrl!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          BookCoverLeading(coverImageUrl: _previewUrl, size: 56),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.addTurkishBookImagePreviewHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _publisherController,
                      decoration: InputDecoration(
                        hintText: l10n.addTurkishBookPublisherHint,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        hintText: l10n.addTurkishBookCategoryHint,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ],
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
                : Text(l10n.addTurkishBookSubmit),
          ),
        ],
      ),
    );
  }
}

Future<void> showAddTurkishBookSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      final preferredHeight = (mq.size.height * 0.75).clamp(480.0, 640.0);
      final maxSheetHeight = mq.size.height - mq.viewInsets.bottom - 24;
      final sheetHeight = preferredHeight.clamp(320.0, maxSheetHeight);

      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SizedBox(
          height: sheetHeight,
          child: const SafeArea(top: false, child: AddTurkishBookFormSheet()),
        ),
      );
    },
  );
}
