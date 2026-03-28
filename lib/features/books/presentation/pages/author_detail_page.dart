import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/books_providers.dart';

class AuthorDetailPage extends ConsumerWidget {
  const AuthorDetailPage({super.key, required this.authorId});

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAuthor = ref.watch(authorDetailProvider(authorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Author')),
      body: asyncAuthor.when(
        data: (author) {
          final photoUrl = AppConstants.authorPhotoUrl(author.photoId);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (photoUrl != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photoUrl,
                      height: 160,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 96),
                    ),
                  ),
                )
              else
                const Center(child: Icon(Icons.person, size: 96)),
              const SizedBox(height: 16),
              Text(
                author.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (author.birthDate != null || author.deathDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (author.birthDate != null) author.birthDate,
                    if (author.deathDate != null) '– ${author.deathDate}',
                  ].join(' '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                author.bio.isEmpty ? 'No biography available.' : author.bio,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load author. ${e.toString().replaceFirst('Exception: ', '')}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
