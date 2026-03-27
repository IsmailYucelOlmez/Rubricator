import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Supabase session as a stream — use for sign-in / sign-out / persistence.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateStream;
});
