import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../books/presentation/book_detail_page.dart';
import 'favorites_provider.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Favorites', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (!signedIn)
              const Expanded(
                child: Center(
                  child: Text('Sign in from Profile to see your favorites.'),
                ),
              )
            else
              Expanded(
                child: favoritesAsync.when(
                  data: (favorites) {
                    if (favorites.isEmpty) {
                      return const Center(child: Text('No favorites yet'));
                    }
                    return ListView.separated(
                      itemCount: favorites.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final book = favorites[index];
                        return ListTile(
                          title: Text(book.title),
                          subtitle: Text(book.author),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookDetailPage(book: book),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text('Could not load favorites: $error'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
