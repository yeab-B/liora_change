/// `ChatSession` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.15.
///
/// Sessions are created by the first `POST /ai/chat`, never explicitly.
class ChatSession {
  const ChatSession({
    required this.id,
    this.title,
    this.challengeId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String? title;
  final int? challengeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String?,
      challengeId: json['challenge_id'] as int?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}
