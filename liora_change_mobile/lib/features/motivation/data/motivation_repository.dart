import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../models/enums.dart';
import '../../../models/motivation.dart';

/// `POST /ai/motivation` from `docs/mvp/05-api-contract.md` §7.1.
///
/// The backend answers 200 with a template message when OpenAI is unavailable,
/// so a "failure" here means the network, not the AI.
class MotivationRepository {
  const MotivationRepository(this._dio);

  final Dio _dio;

  Future<Motivation> getMotivation({
    required int challengeId,
    MotivationContext? context,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.aiMotivation,
        data: <String, dynamic>{
          'challenge_id': challengeId,
          'context': ?context?.wire,
        },
      );
      final dynamic body = response.data;
      if (body is Map && body['data'] is Map) {
        return Motivation.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
      throw const ApiException(
        message: 'The server returned an unexpected response.',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final Provider<MotivationRepository> motivationRepositoryProvider =
    Provider<MotivationRepository>(
      (Ref ref) => MotivationRepository(ref.watch(apiClientProvider)),
    );
