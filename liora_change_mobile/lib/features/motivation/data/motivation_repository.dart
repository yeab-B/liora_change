import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/gemini_coach_client.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/config/demo_ai_config.dart';
import '../../../models/enums.dart';
import '../../../models/motivation.dart';

/// `POST /ai/motivation` from `docs/mvp/05-api-contract.md` §7.1.
///
/// On demo builds the phone calls Gemini directly so the nudge still works
/// while Laravel AI is offline.
class MotivationRepository {
  const MotivationRepository(this._dio, {this.gemini});

  final Dio _dio;
  final GeminiCoachClient? gemini;

  Future<Motivation> getMotivation({
    required int challengeId,
    MotivationContext? context,
    String? challengeTitle,
  }) async {
    final GeminiCoachClient? client = gemini;
    if (DemoAiConfig.directCoachEnabled &&
        DemoAiConfig.geminiEnabled &&
        client != null) {
      final String title = challengeTitle ?? 'your challenge';
      final String message = await client.reply(
        message:
            'Write one short encouraging daily nudge (max 2 sentences) for '
            'someone working on "$title". No shame, no quotes around the '
            'message, speak to them directly.',
      );
      return Motivation(
        message: message,
        tone: MotivationTone.encouraging,
        source: MotivationSource.openai,
        challengeId: challengeId,
        challengeTitle: challengeTitle,
      );
    }

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.aiMotivation,
        data: <String, dynamic>{
          'challenge_id': challengeId,
          'context': context?.wire,
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
      (Ref ref) => MotivationRepository(
        ref.watch(apiClientProvider),
        gemini: GeminiCoachClient(),
      ),
    );
