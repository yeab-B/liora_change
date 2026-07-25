import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../models/challenge.dart';
import '../../../models/challenge_category.dart';
import '../../../models/challenge_template.dart';
import '../../../models/check_in.dart';
import '../../../models/check_in_result.dart';
import '../../../models/enums.dart';

/// The challenge endpoints from `docs/mvp/05-api-contract.md` §2 and §8.
class ChallengeRepository {
  const ChallengeRepository(this._dio);

  final Dio _dio;

  Future<List<Challenge>> getMyChallenges({ChallengeStatus? status}) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.challenges,
        queryParameters: <String, dynamic>{'status': ?status?.wire},
      );
      return _list(response.data).map(Challenge.fromJson).toList();
    });
  }

  Future<Challenge> getChallenge(int id) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.challenge(id),
      );
      return Challenge.fromJson(_data(response.data));
    });
  }

  /// Starts the clock: the API sets `start_date`/`end_date` and moves the
  /// challenge to `active`.
  Future<Challenge> activateChallenge(int id) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.activateChallenge(id),
      );
      return Challenge.fromJson(_data(response.data));
    });
  }

  Future<List<CheckIn>> getCheckIns(int challengeId) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.checkIns(challengeId),
      );
      return _list(response.data).map(CheckIn.fromJson).toList();
    });
  }

  /// `CreateCheckInRequest`: status, note?, mood?, energy?, check_in_date?.
  /// The API allows one check-in per challenge per calendar day.
  Future<CheckInResult> submitCheckIn({
    required int challengeId,
    required CheckInStatus status,
    String? note,
    int? mood,
    int? energy,
  }) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.checkIns(challengeId),
        data: <String, dynamic>{
          'status': status.wire,
          'note': ?note,
          'mood': ?mood,
          'energy': ?energy,
        },
      );
      return CheckInResult.fromJson(_data(response.data));
    });
  }

  Future<List<ChallengeCategory>> getCategories() {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.challengeCategories,
      );
      return _list(response.data).map(ChallengeCategory.fromJson).toList();
    });
  }

  Future<List<ChallengeTemplate>> getTemplates({int? categoryId}) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.challengeTemplates,
        queryParameters: <String, dynamic>{'category_id': ?categoryId},
      );
      final List<ChallengeTemplate> templates = _list(response.data)
          .map(ChallengeTemplate.fromJson)
          .toList();

      // Filter defensively: a backend that ignores the query parameter would
      // otherwise show every category's templates under one category.
      if (categoryId == null) return templates;
      return templates
          .where(
            (ChallengeTemplate t) =>
                t.categoryId == null || t.categoryId == categoryId,
          )
          .toList();
    });
  }

  /// `CreateChallengeRequest`: title, description?, difficulty?, visibility?,
  /// duration_days?, category_id?. There is deliberately no `template_id` —
  /// a template is copied into these fields by the caller.
  Future<Challenge> createChallenge({
    required String title,
    String? description,
    ChallengeDifficulty? difficulty,
    ChallengeVisibility? visibility,
    int? durationDays,
    int? categoryId,
  }) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.challenges,
        data: <String, dynamic>{
          'title': title,
          'description': ?description,
          'difficulty': ?difficulty?.wire,
          'visibility': ?visibility?.wire,
          'duration_days': ?durationDays,
          'category_id': ?categoryId,
        },
      );
      return Challenge.fromJson(_data(response.data));
    });
  }

  List<Map<String, dynamic>> _list(dynamic body) {
    if (body is Map && body['data'] is List) {
      return (body['data'] as List<dynamic>)
          .whereType<Map<dynamic, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList();
    }
    throw const ApiException(
      message: 'The server returned an unexpected response.',
    );
  }

  Map<String, dynamic> _data(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw const ApiException(
      message: 'The server returned an unexpected response.',
    );
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final Provider<ChallengeRepository> challengeRepositoryProvider =
    Provider<ChallengeRepository>(
      (Ref ref) => ChallengeRepository(ref.watch(apiClientProvider)),
    );
