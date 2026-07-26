import 'dart:typed_data';

import 'package:liora_change_mobile/core/ai/demo_coach_service.dart';
import 'package:liora_change_mobile/features/coach/data/chat_repository.dart';
import 'package:liora_change_mobile/models/chat_message.dart';
import 'package:liora_change_mobile/models/chat_reply.dart';
import 'package:liora_change_mobile/models/chat_session.dart';
import 'package:liora_change_mobile/models/chat_source.dart';
import 'package:liora_change_mobile/models/enums.dart';

/// In-memory stand-in for `POST /ai/chat` and the session history calls.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    this.answers = const <String>['Start smaller than feels impressive.'],
    this.sources = const <ChatSource>[],
  });

  @override
  DemoCoachService? get demoCoach => null;

  /// Handed out in order, one per successful send.
  List<String> answers;
  List<ChatSource> sources;
  Object? error;
  Duration? delay;

  int sessionId = 7;
  int calls = 0;
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];

  @override
  Future<ChatReply> send({
    required String message,
    int? sessionId,
    int? challengeId,
    List<ChatMessage> history = const <ChatMessage>[],
  }) async {
    requests.add(<String, Object?>{
      'message': message,
      'session_id': sessionId,
      'challenge_id': challengeId,
      'history_length': history.length,
    });
    final int index = calls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;

    return ChatReply(
      sessionId: sessionId ?? this.sessionId,
      message: ChatMessage(
        id: 100 + index,
        sessionId: sessionId ?? this.sessionId,
        role: ChatRole.assistant,
        content: answers[index % answers.length],
        sources: sources,
      ),
    );
  }

  @override
  Future<({ChatReply reply, String? transcript, bool speakAloud})> sendAudio(
    Uint8List wavBytes, {
    int? sessionId,
  }) async {
    calls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;
    return (
      transcript: 'Voice note',
      speakAloud: false,
      reply: ChatReply(
        sessionId: sessionId ?? this.sessionId,
        message: ChatMessage(
          id: 200 + calls,
          sessionId: sessionId ?? this.sessionId,
          role: ChatRole.assistant,
          content: answers.first,
          sources: sources,
        ),
      ),
    );
  }

  @override
  Future<List<ChatSession>> getSessions() async => <ChatSession>[];

  @override
  Future<List<ChatMessage>> getMessages(int sessionId) async => <ChatMessage>[];
}
