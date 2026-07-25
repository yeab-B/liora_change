import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../models/auth_session.dart';
import '../../../models/user.dart';

/// Auth calls from `docs/mvp/05-api-contract.md` §1.
///
/// Every failure surfaces as an [ApiException] so the UI can render a message
/// without knowing about Dio.
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? timezone,
  }) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.register,
        data: <String, dynamic>{
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'timezone': ?timezone,
        },
      );
      return AuthSession.fromJson(_data(response));
    });
  }

  Future<AuthSession> login({required String email, required String password}) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.login,
        data: <String, dynamic>{
          'email': email,
          'password': password,
          'device_name': _deviceName,
        },
      );
      return AuthSession.fromJson(_data(response));
    });
  }

  Future<void> logout() {
    return _guard(() async {
      await _dio.post<dynamic>(Endpoints.logout);
    });
  }

  /// The contract puts the current user at `/me`, not `/auth/me`.
  Future<User> me() {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(Endpoints.me);
      return User.fromJson(_data(response));
    });
  }

  Future<User> updateMe({String? name, String? timezone}) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        Endpoints.me,
        data: <String, dynamic>{'name': ?name, 'timezone': ?timezone},
      );
      return User.fromJson(_data(response));
    });
  }

  static String get _deviceName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'flutter_android';
      case TargetPlatform.iOS:
        return 'flutter_ios';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return 'flutter_${defaultTargetPlatform.name}';
    }
  }

  /// Unwraps the `{ "data": ... }` success envelope.
  static Map<String, dynamic> _data(Response<dynamic> response) {
    final dynamic body = response.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw const ApiException(
      message: 'The server returned an unexpected response.',
    );
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (Ref ref) => AuthRepository(ref.watch(apiClientProvider)),
    );
