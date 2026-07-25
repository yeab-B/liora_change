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
  }) async {
    requests.add(<String, Object?>{
      'message': message,
      'session_id': sessionId,
      'challenge_id': challengeId,
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
  Future<List<ChatSession>> getSessions() async => <ChatSession>[];

  @override
  Future<List<ChatMessage>> getMessages(int sessionId) async => <ChatMessage>[];
}
