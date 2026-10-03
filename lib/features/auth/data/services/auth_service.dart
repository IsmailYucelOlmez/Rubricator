import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../habit/data/datasources/habit_pending_logs_local_datasource.dart';

/// Thrown by [AuthService.deleteAccount]; [code] is the edge function's
/// `error` field (`invalid_code`, `unauthorized`, `delete_failed`, …).
class AccountDeletionException implements Exception {
  const AccountDeletionException(this.code);

  final String code;

  bool get isInvalidCode => code == 'invalid_code';

  @override
  String toString() => 'AccountDeletionException($code)';
}

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
  }) async {
    AppLogger.info('auth', 'Sign up attempt');
    try {
      final response = await _client.auth.signUp(
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
      AppLogger.info(
        'auth',
        'Sign up success',
        data: {'userId': response.user?.id},
      );
      return response;
    } catch (error, stackTrace) {
      await AppLogger.error('auth', 'Sign up failed', error, stackTrace);
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    AppLogger.info('auth', 'Sign in attempt');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info(
        'auth',
        'Sign in success',
        data: {'userId': response.user?.id},
      );
      return response;
    } catch (error, stackTrace) {
      await AppLogger.error('auth', 'Sign in failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    AppLogger.info('auth', 'Sign out');
    try {
      await _client.auth.signOut();
      AppLogger.info('auth', 'Sign out success');
    } catch (error, stackTrace) {
      await AppLogger.error('auth', 'Sign out failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> sendPasswordResetOtp(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String otpToken,
    required String newPassword,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email.trim(),
      token: otpToken.trim(),
      type: OtpType.recovery,
    );
    if (response.session == null) {
      throw StateError('Password recovery verification failed.');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Emails the signed-in user a one-time code that [deleteAccount] requires.
  /// Uses the "Magic Link" template, which must show `{{ .Token }}`.
  Future<void> sendAccountDeletionOtp() async {
    final email = currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      throw StateError('No signed-in user with an email.');
    }
    await _client.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  /// Permanently deletes the signed-in user's account and all their data via
  /// the `delete-account` edge function (which verifies [otpCode] itself),
  /// then clears the local session and this user's queued offline logs.
  Future<void> deleteAccount(String otpCode) async {
    final userId = currentUser?.id;
    if (userId == null) throw StateError('No signed-in user found.');
    AppLogger.info('auth', 'Delete account attempt');

    final dio = Dio(
      BaseOptions(
        baseUrl: '${SupabaseService.url}/functions/v1/delete-account',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        validateStatus: (_) => true,
      ),
    )..interceptors.add(SupabaseService.edgeFunctionAuthInterceptor());

    final response = await dio.post<Map<String, dynamic>>(
      '',
      data: <String, dynamic>{'code': otpCode.trim()},
    );
    if (response.statusCode != 200) {
      final code = response.data?['error'] as String? ?? 'delete_failed';
      AppLogger.warning(
        'auth',
        'Delete account failed',
        data: {'status': response.statusCode, 'error': code},
      );
      throw AccountDeletionException(code);
    }

    AppLogger.info('auth', 'Delete account success', data: {'userId': userId});
    await HabitPendingLogsLocalDataSource().removeForUser(userId);
    // The user no longer exists server-side; only drop the local session.
    await _client.auth.signOut(scope: SignOutScope.local);
  }

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
