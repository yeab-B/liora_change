import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../models/chat_message.dart';
import '../../../models/chat_reply.dart';
import '../../../models/enums.dart';
import '../data/chat_repository.dart';

/// The conversation as the screen needs it: the messages in order, whether the
/// coach is still writing, and the session the API assigned.
class ChatState {
  const ChatState({
    this.sessionId,
    this.messages = const <ChatMessage>[],
    this.isWaitingForReply = false,
  });

  final int? sessionId;
  final List<ChatMessage> messages;
  final bool isWaitingForReply;

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({
    int? sessionId,
    List<ChatMessage>? messages,
    bool? isWaitingForReply,
  }) {
    return ChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isWaitingForReply: isWaitingForReply ?? this.isWaitingForReply,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  /// Ids for messages that exist only on this device. Negative so they can
  /// never collide with the API's.
  int _nextLocalId = -1;

  @override
  ChatState build() {
    ref.keepAlive();
    return const ChatState();
  }

  Future<void> send(String text) async {
    final String message = text.trim();
    if (message.isEmpty || state.isWaitingForReply) return;

    final ChatMessage pending = ChatMessage(
      id: _nextLocalId--,
      sessionId: state.sessionId,
      role: ChatRole.user,
      content: message,
      createdAt: DateTime.now(),
      delivery: MessageDelivery.sending,
    );

    // The question appears the moment it is asked; the network catches up.
    state = state.copyWith(
      messages: <ChatMessage>[...state.messages, pending],
      isWaitingForReply: true,
    );

    await _deliver(pending);
  }

  /// Re-sends a message that never made it. The bubble stays where it is in
  /// the conversation rather than jumping to the end.
  Future<void> retry(int messageId) async {
    if (state.isWaitingForReply) return;

    final ChatMessage? failed = state.messages
        .where(
          (ChatMessage m) =>
              m.id == messageId && m.delivery == MessageDelivery.failed,
        )
        .firstOrNull;
    if (failed == null) return;

    _replace(failed.copyWith(delivery: MessageDelivery.sending));
    state = state.copyWith(isWaitingForReply: true);

    await _deliver(failed);
  }

  Future<void> _deliver(ChatMessage pending) async {
    try {
      final ChatReply reply = await ref
          .read(chatRepositoryProvider)
          .send(message: pending.content, sessionId: state.sessionId);

      _replace(
        pending.copyWith(
          delivery: MessageDelivery.sent,
          sessionId: reply.sessionId,
        ),
      );
      state = state.copyWith(
        sessionId: reply.sessionId,
        messages: <ChatMessage>[...state.messages, reply.message],
        isWaitingForReply: false,
      );
    } on ApiException {
      _replace(pending.copyWith(delivery: MessageDelivery.failed));
      state = state.copyWith(isWaitingForReply: false);
    }
  }

  void _replace(ChatMessage message) {
    state = state.copyWith(
      messages: state.messages
          .map((ChatMessage m) => m.id == message.id ? message : m)
          .toList(),
    );
  }
}

final NotifierProvider<ChatController, ChatState> chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);
