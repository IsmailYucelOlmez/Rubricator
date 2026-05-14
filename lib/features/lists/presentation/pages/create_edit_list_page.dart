import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/presentation/widgets/book_cover_leading.dart';
import '../../../books/presentation/providers/books_providers.dart';
import '../../domain/entities/list_entities.dart';
import '../providers/lists_providers.dart';

class CreateEditListPage extends ConsumerStatefulWidget {
  const CreateEditListPage({super.key, this.initialList});

  final ListEntity? initialList;

  @override
  ConsumerState<CreateEditListPage> createState() => _CreateEditListPageState();
}

class _PickedBook {
  const _PickedBook({
    required this.bookId,
    required this.title,
    required this.author,
    this.coverImageUrl,
    this.itemId,
  });

  final String bookId;
  final String title;
  final String author;
  final String? coverImageUrl;
  final String? itemId;
}

class _CreateEditListPageState extends ConsumerState<CreateEditListPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _isPublic = true;
  bool _saving = false;
  bool _loadingItems = false;
  List<Book> _searchResults = const <Book>[];
  List<_PickedBook> _picked = <_PickedBook>[];
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialList;
    if (initial != null) {
      _titleCtrl.text = initial.title;
      _descCtrl.text = initial.description;
      _isPublic = initial.isPublic;
      _loadInitialItems(initial.id);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.initialList != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? l10n.editList : l10n.createList,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize:
                (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * 1.1,
          ),
        ),
      ),
      body: ResponsiveScaffoldBody(
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.1)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _titleCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.title,
                              errorText: _titleError,
                            ),
                            onEditingComplete: () {
                              FocusScope.of(context).nextFocus();
                              final empty = _titleCtrl.text.trim().isEmpty;
                              setState(() {
                                _titleError = empty
                                    ? l10n.uxTitleRequired
                                    : null;
                              });
                            },
                            onChanged: (_) {
                              if (_titleError != null) {
                                setState(() => _titleError = null);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                          TextField(
                            controller: _descCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.description,
                            ),
                            minLines: 3,
                            maxLines: 5,
                          ),
                          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                          SwitchListTile(
                            value: _isPublic,
                            onChanged: (value) =>
                                setState(() => _isPublic = value),
                            title: Text(l10n.public),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.selectedBooks,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_loadingItems)
                            const AppLoadingIndicator()
                          else if (_picked.isEmpty)
                            Text(l10n.noBooksSelectedYet)
                          else
                            Expanded(
                              child: ReorderableListView.builder(
                                buildDefaultDragHandles: false,
                                itemCount: _picked.length,
                                onReorder: _reorder,
                                itemBuilder: (context, index) {
                                  final item = _picked[index];
                                  return ListTile(
                                    key: ValueKey(item.bookId),
                                    leading: ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: IconTheme.of(context).color,
                                      ),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontFamily: 'LTSoul'),
                                    ),
                                    subtitle: Text(item.author),
                                    trailing: IconButton(
                                      onPressed: () =>
                                          _confirmRemoveBook(index, l10n),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                          Text(
                            l10n.searchBooksTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontSize:
                                            (Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.fontSize ??
                                                16) *
                                            1.1,
                                      ),
                                  decoration: InputDecoration(
                                    hintText: l10n.searchViaGoogleBooks,
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.fontSize ??
                                                  16) *
                                              1.1,
                                        ),
                                  ),
                                  onSubmitted: (_) => _searchBooks(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              FilledButton(
                                onPressed: _searchBooks,
                                child: MediaQuery(
                                  data: MediaQuery.of(
                                    context,
                                  ).copyWith(textScaler: TextScaler.noScaling),
                                  child: Text(l10n.search),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) =>
                            _buildSearchResultItem(context, index),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const AppLoadingIndicator(
                        size: 18,
                        strokeWidth: 2,
                        centered: false,
                      )
                    : MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.noScaling),
                        child: Text(l10n.save),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSearchResultItem(BuildContext context, int index) {
    final book = _searchResults[index];
    final alreadyAdded = _picked.any((b) => b.bookId == book.id);
    final layoutW = MediaQuery.sizeOf(context).width;
    final basis = context.isTabletLayout ? AppBreakpoints.contentMaxWidth : layoutW;
    final imageWidth = (basis * 0.20).clamp(72.0, 120.0);
    final resultTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontFamily: 'LTSoul',
      fontSize:
          ((Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 0.8) *
          1.1,
    );
    final resultAuthorStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize:
          ((Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * 0.9) *
          1.1,
    );
    return InkWell(
      onTap: alreadyAdded ? null : () => _addBook(book),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: imageWidth,
              height: imageWidth * 1.4,
              child: BookCoverLeading(coverImageUrl: book.coverImageUrl),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: resultTitleStyle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: resultAuthorStyle,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(alreadyAdded ? Icons.check : Icons.add),
              onPressed: alreadyAdded ? null : () => _addBook(book),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadInitialItems(String listId) async {
    setState(() => _loadingItems = true);
    try {
      final items = await ref
          .read(listsRepositoryProvider)
          .getListItems(listId);
      if (!mounted) return;
      setState(() {
        _picked = items
            .map(
              (i) => _PickedBook(
                bookId: i.bookId,
                title: i.bookTitle,
                author: i.bookAuthor,
                coverImageUrl: i.coverImageUrl,
                itemId: i.id,
              ),
            )
            .toList();
      });
    } finally {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  Future<void> _searchBooks() async {
    final query = _searchCtrl.text.trim();
    if (query.length < 2) return;
    try {
      final result = await ref
          .read(bookRepositoryProvider)
          .searchBooks(query: query, page: 1);
      if (!mounted) return;
      setState(() => _searchResults = result.books.take(20).toList());
    } catch (e) {
      if (mounted) AppFeedback.showErrorSnackBar(context, e);
    }
  }

  Future<void> _confirmRemoveBook(int index, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.uxRemoveBookFromListTitle),
        content: Text(l10n.uxRemoveBookFromListMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.uxRemove),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _picked.removeAt(index));
  }

  void _addBook(Book book) {
    setState(() {
      _picked.add(
        _PickedBook(
          bookId: book.id,
          title: book.title,
          author: book.author,
          coverImageUrl: book.coverImageUrl,
        ),
      );
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _picked.removeAt(oldIndex);
      _picked.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final titleTrim = _titleCtrl.text.trim();
    if (titleTrim.isEmpty) {
      setState(() => _titleError = l10n.uxTitleRequired);
      return;
    }

    setState(() {
      _titleError = null;
      _saving = true;
    });
    final repo = ref.read(listsRepositoryProvider);
    try {
      final displayName = userDisplayName(user);
      final initial = widget.initialList;
      late final String listId;
      if (initial == null) {
        final created = await repo.createList(
          userId: user.id,
          userName: displayName,
          title: titleTrim,
          description: _descCtrl.text.trim(),
          isPublic: _isPublic,
        );
        listId = created.id;
      } else {
        listId = initial.id;
        await repo.updateList(
          listId: listId,
          title: titleTrim,
          description: _descCtrl.text.trim(),
          isPublic: _isPublic,
        );
      }

      final existing = await repo.getListItems(listId);
      final existingByBookId = {for (final e in existing) e.bookId: e};
      final selectedBookIds = _picked.map((e) => e.bookId).toSet();

      for (final old in existing) {
        if (!selectedBookIds.contains(old.bookId)) {
          await repo.removeBookFromList(old.id);
        }
      }
      for (final pick in _picked) {
        if (!existingByBookId.containsKey(pick.bookId)) {
          await repo.addBookToList(
            listId: listId,
            bookId: pick.bookId,
            title: pick.title,
            author: pick.author,
            coverImageUrl: pick.coverImageUrl,
          );
        }
      }

      final finalItems = await repo.getListItems(listId);
      final finalByBookId = {for (final i in finalItems) i.bookId: i.id};
      final orderedIds = _picked
          .map((p) => finalByBookId[p.bookId])
          .whereType<String>()
          .toList();
      await repo.reorderListItems(listId: listId, orderedItemIds: orderedIds);

      _invalidateAll();
      if (!mounted) return;
      AppFeedback.showSuccessSnackBar(
        context,
        initial == null ? l10n.uxListCreatedSuccess : l10n.uxListUpdatedSuccess,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) AppFeedback.showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _invalidateAll() {
    ref.invalidate(listsFeedProvider);
    ref.invalidate(popularListsProvider);
    ref.invalidate(topListsProvider);
    ref.invalidate(userListsProvider);
    ref.invalidate(savedListsProvider);
  }
}
