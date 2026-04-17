import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// All Supabase Auth calls live here — UI uses [authStateProvider] / this via Riverpod.
class AuthService {
  AuthService();
  static const String _profilePhotosBucket = 'profile-photos';

  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<User?> get authStateStream =>
      _client.auth.onAuthStateChange.map((data) => data.session?.user);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
    String? avatarUrl,
    DateTime? privacyPolicyAcceptedAt,
    String? privacyPolicyVersion,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{
        if (displayName != null && displayName.trim().isNotEmpty)
          'username': displayName.trim(),
        if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
          'avatar_url': avatarUrl.trim(),
        if (privacyPolicyAcceptedAt != null)
          'privacy_policy_accepted_at': privacyPolicyAcceptedAt.toIso8601String(),
        if (privacyPolicyVersion != null && privacyPolicyVersion.trim().isNotEmpty)
          'privacy_policy_version': privacyPolicyVersion.trim(),
      },
    );
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

  Future<void> updateProfile({
    required String displayName,
    String? avatarUrl,
  }) async {
    final name = displayName.trim();
    final avatar = avatarUrl?.trim();
    if (name.isEmpty) {
      throw ArgumentError('Display name cannot be empty.');
    }

    final existing = currentUser?.userMetadata ?? const <String, dynamic>{};
    final mergedMetadata = <String, dynamic>{
      ...existing,
      'username': name,
      if (avatar != null && avatar.isNotEmpty) 'avatar_url': avatar else 'avatar_url': null,
    };

    await _client.auth.updateUser(
      UserAttributes(
        data: mergedMetadata,
      ),
    );

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('lists')
        .update(<String, dynamic>{'user_name': name})
        .eq('user_id', userId);
    await _client
        .from('list_comments')
        .update(<String, dynamic>{'user_name': name})
        .eq('user_id', userId);
  }

  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = _fileExtension(fileName);
    final path = '$userId/avatar.$ext';
    final options = FileOptions(
      cacheControl: '3600',
      upsert: true,
      contentType: _contentTypeFromExt(ext),
    );
    await _client.storage.from(_profilePhotosBucket).uploadBinary(path, bytes, fileOptions: options);
    return _client.storage.from(_profilePhotosBucket).getPublicUrl(path);
  }

  String _fileExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return 'jpg';
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
