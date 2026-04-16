import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Supabase session as a stream — use for sign-in / sign-out / persistence.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateStream;
});

String userDisplayName(User? user) {
  if (user == null) return 'user';
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final candidates = <String?>[
    metadata['username'] as String?,
    metadata['user_name'] as String?,
    metadata['full_name'] as String?,
    metadata['name'] as String?,
  ];
  for (final raw in candidates) {
    final value = raw?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  final email = user.email?.trim() ?? '';
  if (email.isNotEmpty && email.contains('@')) {
    return email.split('@').first;
  }
  return 'user';
}

String? userAvatarUrl(User? user) {
  if (user == null) return null;
  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final candidates = <String?>[
    metadata['avatar_url'] as String?,
    metadata['picture'] as String?,
    metadata['photo_url'] as String?,
  ];
  for (final raw in candidates) {
    final value = raw?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

final currentUserDisplayNameProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return userDisplayName(user);
});

final currentUserAvatarUrlProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return userAvatarUrl(user);
});
