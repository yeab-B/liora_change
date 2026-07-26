import 'chat_source.dart';
import 'enums.dart';

/// Local-only delivery state. The API knows nothing about this; it exists so a
/// message can appear the instant it is written and still show what happened.
enum MessageDelivery { sending, sent, failed }

/// `ChatMessage` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.16.
///
/// [sources] and [delivery] are added locally: the contract attaches sources to
/// the reply envelope rather than the message, and the UI wants them on the
/// bubble they belong to.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.createdAt,
    this.sources = const <ChatSource>[],
    this.delivery = MessageDelivery.sent,
  });

  /// Negative while the message only exists on this device.
  final int id;
  final int? sessionId;
  final ChatRole role;
  final String content;
  final DateTime? createdAt;
  final List<ChatSource> sources;
  final MessageDelivery delivery;

  bool get isFromUser => role == ChatRole.user;

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    List<ChatSource> sources = const <ChatSource>[],
  }) {
    return ChatMessage(
      id: json['id'] as int? ?? 0,
      sessionId: json['session_id'] as int?,
      role: ChatRole.fromWire(json['role']),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      sources: sources,
    );
  }

  ChatMessage copyWith({
    MessageDelivery? delivery,
    int? sessionId,
    String? content,
  }) {
    return ChatMessage(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      sources: sources,
      delivery: delivery ?? this.delivery,
    );
  }
}
