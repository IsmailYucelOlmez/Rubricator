import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.openLibraryBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
      ),
    );
  }

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception('API request failed: ${e.message}');
    }
  }
}
