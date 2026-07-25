import 'package:dio/dio.dart';

/// A failed API call, already translated into something a screen can show.
///
/// Parses the error envelope from `docs/mvp/05-api-contract.md` §0.3:
/// `{ "message": ..., "code": ..., "errors": { "field": ["..."] } }`.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors = const <String, List<String>>{},
  });

  final String message;

  /// Machine-readable code such as `VALIDATION_ERROR`, when the API sends one.
  final String? code;
  final int? statusCode;

  /// Per-field messages from a `422`, keyed by the request field name.
  final Map<String, List<String>> fieldErrors;

  bool get isValidation => statusCode == 422;

  bool get isUnauthorized => statusCode == 401;

  /// First message for [field], for rendering under the matching input.
  String? errorFor(String field) {
    final List<String>? messages = fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  factory ApiException.fromDio(DioException error) {
    final Response<dynamic>? response = error.response;
    final int? status = response?.statusCode;
    final dynamic body = response?.data;

    if (body is Map) {
      final Object? rawMessage = body['message'];
      final Object? rawCode = body['code'];
      return ApiException(
        message: rawMessage is String && rawMessage.isNotEmpty
            ? rawMessage
            : _fallbackMessage(error, status),
        code: rawCode is String ? rawCode : null,
        statusCode: status,
        fieldErrors: _parseFieldErrors(body['errors']),
      );
    }

    return ApiException(
      message: _fallbackMessage(error, status),
      statusCode: status,
    );
  }

  static Map<String, List<String>> _parseFieldErrors(Object? raw) {
    if (raw is! Map) return const <String, List<String>>{};

    final Map<String, List<String>> parsed = <String, List<String>>{};
    raw.forEach((Object? key, Object? value) {
      if (key is! String) return;
      if (value is List) {
        parsed[key] = value
            .whereType<Object>()
            .map((Object v) => '$v')
            .toList();
      } else if (value is String) {
        parsed[key] = <String>[value];
      }
    });
    return parsed;
  }

  static const Set<DioExceptionType> _timeouts = <DioExceptionType>{
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  };

  static String _fallbackMessage(DioException error, int? status) {
    if (_timeouts.contains(error.type)) {
      return 'The server is taking too long to respond. Please try again.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the server. Check your connection and try again.';
    }
    if (error.type == DioExceptionType.cancel) {
      return 'Request cancelled.';
    }

    if (status == 401) return 'Your session has expired. Please log in again.';
    if (status == 403) return 'You do not have access to this.';
    if (status == 404) return 'We could not find what you were looking for.';
    if (status != null && status >= 500) {
      return 'Something went wrong on our side. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  String toString() => message;
}
