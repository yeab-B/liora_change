import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../models/badge_unlocked.dart';
import '../../../models/progress.dart';

/// `GET /progress` (§6.1) and `GET /badges/unlocked` (§6.2) from
/// `docs/mvp/05-api-contract.md`.
///
/// The member's name and email already live in the auth session, so the
/// profile screen reads those from `authControllerProvider` rather than
/// spending a request on `/me`.
class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<Progress> getProgress() {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.progress,
      );
      return Progress.fromJson(_data(response));
    });
  }

  Future<List<BadgeUnlocked>> getUnlockedBadges() {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.unlockedBadges,
      );
      final dynamic body = response.data;
      if (body is Map && body['data'] is List) {
        return (body['data'] as List<dynamic>)
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (Map<dynamic, dynamic> item) =>
                  BadgeUnlocked.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      throw const ApiException(
        message: 'The server returned an unexpected response.',
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic> _data(Response<dynamic> response) {
    final dynamic body = response.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw const ApiException(
      message: 'The server returned an unexpected response.',
    );
  }
}

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (Ref ref) => ProfileRepository(ref.watch(apiClientProvider)),
    );
