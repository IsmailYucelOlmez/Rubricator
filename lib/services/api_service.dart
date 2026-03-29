import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';

class ApiService {
  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.openLibraryBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          validateStatus: (code) => code != null && code < 500,
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint(o.toString()),
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
      final data = response.data;
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception(
          'Open Library returned ${response.statusCode} for $path',
        );
      }
      return data ?? <String, dynamic>{};
    } on DioException catch (e) {
      final type = e.type.name;
      throw Exception(
        e.message != null && e.message!.isNotEmpty
            ? 'Network error ($type): ${e.message}'
            : 'Network error ($type)',
      );
    }
  }
}
