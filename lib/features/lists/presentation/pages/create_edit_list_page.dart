import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../books/domain/entities/book.dart';
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
    this.coverId,
    this.itemId,
  });

  final String bookId;
  final String title;
  final String author;
  final int? coverId;
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
      appBar: AppBar(title: Text(isEdit ? l10n.editList : l10n.createList)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: l10n.title)),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: l10n.description),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            SwitchListTile(
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              title: Text(l10n.public),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.bookSelector, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: l10n.searchViaOpenLibrary,
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(onPressed: _searchBooks, child: Text(l10n.search)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_searchResults.isNotEmpty)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (_, index) {
                    final book = _searchResults[index];
                    final alreadyAdded = _picked.any((b) => b.bookId == book.id);
                    return ListTile(
                      dense: true,
                      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: Icon(alreadyAdded ? Icons.check : Icons.add),
                        onPressed: alreadyAdded ? null : () => _addBook(book),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Text(l10n.selectedBooks, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (_loadingItems)
              const Center(child: CircularProgressIndicator())
            else if (_picked.isEmpty)
              Text(l10n.noBooksSelectedYet)
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _picked.length,
                onReorder: _reorder,
                itemBuilder: (context, index) {
                  final item = _picked[index];
                  return ListTile(
                    key: ValueKey(item.bookId),
                    title: Text(item.title),
                    subtitle: Text(item.author),
                    leading: const Icon(Icons.drag_handle),
                    trailing: IconButton(
                      onPressed: () => setState(() => _picked.removeAt(index)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadInitialItems(String listId) async {
    setState(() => _loadingItems = true);
    try {
      final items = await ref.read(listsRepositoryProvider).getListItems(listId);
      if (!mounted) return;
      setState(() {
        _picked = items
            .map(
              (i) => _PickedBook(
                bookId: i.bookId,
                title: i.bookTitle,
                author: i.bookAuthor,
                coverId: i.coverId,
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
    final result = await ref.read(bookRepositoryProvider).searchBooks(query: query, page: 1);
    if (!mounted) return;
    setState(() => _searchResults = result.books.take(20).toList());
  }

  void _addBook(Book book) {
    setState(() {
      _picked.add(
        _PickedBook(
          bookId: book.id,
          title: book.title,
          author: book.author,
          coverId: book.coverId,
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
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    if (_titleCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);
    final repo = ref.read(listsRepositoryProvider);
    try {
      final email = user.email ?? 'user';
      final initial = widget.initialList;
      late final String listId;
      if (initial == null) {
        final created = await repo.createList(
          userId: user.id,
          userName: email.split('@').first,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          isPublic: _isPublic,
        );
        listId = created.id;
      } else {
        listId = initial.id;
        await repo.updateList(
          listId: listId,
          title: _titleCtrl.text.trim(),
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
            coverId: pick.coverId,
          );
        }
      }

      final finalItems = await repo.getListItems(listId);
      final finalByBookId = {for (final i in finalItems) i.bookId: i.id};
      final orderedIds = _picked.map((p) => finalByBookId[p.bookId]).whereType<String>().toList();
      await repo.reorderListItems(listId: listId, orderedItemIds: orderedIds);

      _invalidateAll();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotSaveList(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _invalidateAll() {
    ref.invalidate(listsFeedProvider);
    ref.invalidate(popularListsProvider);
    ref.invalidate(followingListsProvider);
    ref.invalidate(userListsProvider);
    ref.invalidate(savedListsProvider);
  }
}
