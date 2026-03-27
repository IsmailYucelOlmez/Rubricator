import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// All Supabase Auth calls live here — UI uses [authStateProvider] / this via Riverpod.
class AuthService {
  AuthService();

  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<User?> get authStateStream =>
      _client.auth.onAuthStateChange.map((data) => data.session?.user);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email.trim(), password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
