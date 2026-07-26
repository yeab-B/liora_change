import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/demo_coach_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/config/demo_ai_config.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_reply.dart';
import '../../../models/chat_session.dart';

/// The coach endpoints from `docs/mvp/05-api-contract.md` §7.2.
///
/// On demo builds with AI keys, text and voice are answered on-device so the
/// phone never waits for Laravel `/ai/chat`.
class ChatRepository {
  const ChatRepository(this._dio, {this.demoCoach});

  final Dio _dio;
  final DemoCoachService? demoCoach;

  Future<ChatReply> send({
    required String message,
    int? sessionId,
    int? challengeId,
    List<ChatMessage> history = const <ChatMessage>[],
  }) {
    final DemoCoachService? coach = demoCoach;
    if (DemoAiConfig.directCoachEnabled && coach != null) {
      return coach.sendText(
        message: message,
        sessionId: sessionId,
        history: history,
      );
    }

    return _guard(() async {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.aiChat,
        data: <String, dynamic>{
          'message': message,
          'session_id': sessionId,
          'challenge_id': challengeId,
        },
      );
      return ChatReply.fromJson(_data(response.data));
    });
  }

  /// Microphone turn: Addis AI hears Ethiopian speech and replies in kind.
  Future<({ChatReply reply, String? transcript, bool speakAloud})> sendAudio(
    Uint8List wavBytes, {
    int? sessionId,
  }) {
    final DemoCoachService? coach = demoCoach;
    if (coach == null || !DemoAiConfig.addisEnabled) {
      return Future<({ChatReply reply, String? transcript, bool speakAloud})>.error(
        const ApiException(
          message: 'Voice coaching needs the Addis AI key on this build.',
        ),
      );
    }
    return coach.sendAudio(wavBytes, sessionId: sessionId);
  }

  Future<List<ChatSession>> getSessions() {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.aiChatSessions,
      );
      return _list(response.data).map(ChatSession.fromJson).toList();
    });
  }

  Future<List<ChatMessage>> getMessages(int sessionId) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(
        Endpoints.aiChatSessionMessages(sessionId),
      );
      return _list(response.data)
          .map((Map<String, dynamic> json) => ChatMessage.fromJson(json))
          .toList();
    });
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Map<String, dynamic> _data(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw const ApiException(
      message: 'The server returned an unexpected response.',
    );
  }

  List<Map<String, dynamic>> _list(dynamic body) {
    if (body is Map && body['data'] is List) {
      return (body['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    throw const ApiException(
      message: 'The server returned an unexpected response.',
    );
  }
}

final Provider<ChatRepository> chatRepositoryProvider =
    Provider<ChatRepository>(
      (Ref ref) => ChatRepository(
        ref.watch(apiClientProvider),
        demoCoach: ref.watch(demoCoachServiceProvider),
      ),
    );
