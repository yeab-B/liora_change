import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_reply.dart';
import '../../../models/chat_session.dart';

/// The coach endpoints from `docs/mvp/05-api-contract.md` §7.2.
///
/// There is no "create session" call in the contract: the first `POST
/// /ai/chat` opens one and returns its id, which every later message carries.
class ChatRepository {
  const ChatRepository(this._dio);

  final Dio _dio;

  Future<ChatReply> send({
    required String message,
    int? sessionId,
    int? challengeId,
  }) {
    return _guard(() async {
      final Response<dynamic> response = await _dio.post<dynamic>(
        Endpoints.aiChat,
        data: <String, dynamic>{
          'message': message,
          'session_id': ?sessionId,
          'challenge_id': ?challengeId,
        },
      );
      return ChatReply.fromJson(_data(response.data));
    });
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
      (Ref ref) => ChatRepository(ref.watch(apiClientProvider)),
    );
