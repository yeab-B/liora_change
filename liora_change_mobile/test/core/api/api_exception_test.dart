import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';

DioException _withResponse(int statusCode, Object? body) {
  final RequestOptions options = RequestOptions(path: '/auth/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
  );
}

void main() {
  test('parses the documented error envelope', () {
    final ApiException exception = ApiException.fromDio(
      _withResponse(422, <String, dynamic>{
        'message': 'The given data was invalid.',
        'code': 'VALIDATION_ERROR',
        'errors': <String, dynamic>{
          'email': <String>['The email has already been taken.'],
        },
      }),
    );

    expect(exception.message, 'The given data was invalid.');
    expect(exception.code, 'VALIDATION_ERROR');
    expect(exception.statusCode, 422);
    expect(exception.isValidation, isTrue);
    expect(exception.errorFor('email'), 'The email has already been taken.');
    expect(exception.errorFor('password'), isNull);
  });

  test('falls back to a friendly message when the body is not JSON', () {
    final ApiException exception = ApiException.fromDio(
      _withResponse(500, '<html>Server Error</html>'),
    );

    expect(exception.message, isNot(contains('html')));
    expect(exception.statusCode, 500);
  });

  test('explains a connection failure without technical detail', () {
    final ApiException exception = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/me'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(exception.message, contains('Cannot reach the server'));
  });

  test('flags an expired session', () {
    final ApiException exception = ApiException.fromDio(
      _withResponse(401, <String, dynamic>{
        'message': 'Unauthenticated.',
        'code': 'UNAUTHORIZED',
      }),
    );

    expect(exception.isUnauthorized, isTrue);
  });
}
