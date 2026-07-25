import 'chat_message.dart';
import 'chat_source.dart';

/// `ChatReply` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.18 — the `data`
/// of `POST /ai/chat`. The session id comes back here on the first message.
class ChatReply {
  const ChatReply({
    required this.sessionId,
    required this.message,
    this.usedChallengeId,
  });

  final int sessionId;

  /// The assistant's answer, already carrying its citations.
  final ChatMessage message;
  final int? usedChallengeId;

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    final Object? rawSources = json['sources'];
    final List<ChatSource> sources = rawSources is List
        ? rawSources
              .whereType<Map<String, dynamic>>()
              .map(ChatSource.fromJson)
              .toList()
        : const <ChatSource>[];

    return ChatReply(
      sessionId: json['session_id'] as int? ?? 0,
      message: ChatMessage.fromJson(
        json['message'] as Map<String, dynamic>,
        sources: sources,
      ),
      usedChallengeId: json['used_challenge_id'] as int?,
    );
  }
}
