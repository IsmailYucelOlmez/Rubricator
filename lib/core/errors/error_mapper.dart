import 'dart:io';

import 'package:dio/dio.dart';

import 'app_error.dart';

/// Maps any thrown value to a non-technical [AppError] code for UI copy.
class ErrorMapper {
  const ErrorMapper._();

  static AppError map(Object error) {
    if (error is DioException) {
      final type = error.type;
      if (type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.receiveTimeout) {
        return const AppError(AppErrorCodes.timeout);
      }
      if (type == DioExceptionType.connectionError) {
        return const AppError(AppErrorCodes.network);
      }
      if (type == DioExceptionType.badResponse) {
        final code = error.response?.statusCode;
        if (code == null ||
            code == 0 ||
            (code >= HttpStatus.internalServerError && code < 600)) {
          return const AppError(AppErrorCodes.unknown);
        }
      }
    }
    if (error is SocketException) {
      return const AppError(AppErrorCodes.network);
    }
    final text = error.toString().toLowerCase();
    if (text.contains('socketexception') ||
        text.contains('network is unreachable') ||
        text.contains('failed host lookup') ||
        text.contains('no address associated') ||
        text.contains('nodename nor servname') ||
        text.contains('network_error') ||
        text.contains('offline')) {
      return const AppError(AppErrorCodes.network);
    }
    if (text.contains('timeout') || text.contains('timed out')) {
      return const AppError(AppErrorCodes.timeout);
    }
    return const AppError(AppErrorCodes.unknown);
  }
}
