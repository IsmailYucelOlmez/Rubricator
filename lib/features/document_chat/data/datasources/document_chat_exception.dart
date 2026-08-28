import 'package:dio/dio.dart';

class DocumentChatException implements Exception {
  const DocumentChatException({
    required this.statusCode,
    required this.message,
    this.detail,
  });

  final int? statusCode;
  final String message;
  final String? detail;

  factory DocumentChatException.fromResponse(Response<dynamic> response) {
    final detail = _extractDetail(response.data);
    final code = response.statusCode;
    return DocumentChatException(
      statusCode: code,
      message: _messageForStatus(code, detail),
      detail: detail,
    );
  }

  factory DocumentChatException.fromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      return DocumentChatException.fromResponse(response);
    }
    return DocumentChatException(
      statusCode: null,
      message: _messageForDioType(error),
    );
  }

  bool get isNetworkError => statusCode == null;

  static String _messageForDioType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Is the document API reachable?';
      case DioExceptionType.connectionError:
        return 'Cannot reach the document API via the rubricatorApi edge function.';
      default:
        return error.message ?? 'Network error';
    }
  }

  bool get isStillProcessing => statusCode == 409;
  bool get isSessionExpired => statusCode == 404;
  bool get isFileTooLarge => statusCode == 413;
  bool get isUnsupportedFormat => statusCode == 415;
  bool get isQuestionLimit => statusCode == 429;
  bool get isProcessingFailed => statusCode == 422;

  static String? _extractDetail(dynamic data) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
        return first.toString();
      }
      if (data['errorMessage'] != null) {
        return data['errorMessage'].toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  static String _messageForStatus(int? code, String? detail) {
    if (detail != null && detail.trim().isNotEmpty) return detail.trim();
    switch (code) {
      case 400:
        return 'No file provided';
      case 401:
        return 'Invalid or missing API key';
      case 404:
        return 'Session not found or expired';
      case 409:
        return 'Session is still processing';
      case 413:
        return 'File exceeds size limit';
      case 415:
        return 'Unsupported format; use PDF or EPUB';
      case 422:
        return 'Could not process this document';
      case 429:
        return 'Question or session limit reached';
      case 503:
        return 'Service temporarily unavailable';
      default:
        return 'Document chat request failed';
    }
  }

  @override
  String toString() => 'DocumentChatException($statusCode): $message';
}
