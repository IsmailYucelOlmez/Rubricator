import 'package:dio/dio.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/supabase_service.dart';

/// Thrown by [SupportContactService.send]; [code] is the `contact` edge
/// function's error (`rate_limited`, `too_short`, `too_long`, `failed`, …).
class SupportContactException implements Exception {
  const SupportContactException(this.code);

  final String code;

  @override
  String toString() => 'SupportContactException($code)';
}

/// Sends a message to support through the `contact` edge function (the same
/// one the website's contact form uses). The function takes the sender
/// address from the user's session, so only the message is sent from here.
class SupportContactService {
  SupportContactService({Dio? dio})
    : _dio =
          dio ??
                Dio(
                  BaseOptions(
                    baseUrl: '${SupabaseService.url}/functions/v1/contact',
                    connectTimeout: const Duration(seconds: 20),
                    receiveTimeout: const Duration(seconds: 30),
                    validateStatus: (_) => true,
                  ),
                )
            ..interceptors.add(SupabaseService.edgeFunctionAuthInterceptor());

  static const int messageMinLength = 10;
  static const int messageMaxLength = 5000;

  final Dio _dio;

  Future<void> send({
    required String message,
    required String name,
    required String lang,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '',
      data: <String, dynamic>{
        'name': name.trim(),
        'message': message.trim(),
        'lang': lang == 'tr' ? 'tr' : 'en',
      },
    );
    if (response.statusCode == 200) return;

    final data = response.data;
    final fields = data?['fields'];
    final code = fields is Map && fields['message'] is String
        ? fields['message'] as String
        : data?['error'] as String? ?? 'failed';
    AppLogger.warning(
      'contact',
      'Support message failed',
      data: {'status': response.statusCode, 'error': code},
    );
    throw SupportContactException(code);
  }
}
