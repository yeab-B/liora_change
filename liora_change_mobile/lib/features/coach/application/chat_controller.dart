import 'dart:typed_data';

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
    this.autoSpeakText,
  });

  final int? sessionId;
  final List<ChatMessage> messages;
  final bool isWaitingForReply;

  /// When set, the coach screen should speak this line with Addis TTS (voice
  /// turns reply in voice for the demo).
  final String? autoSpeakText;

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({
    int? sessionId,
    List<ChatMessage>? messages,
    bool? isWaitingForReply,
    String? autoSpeakText,
    bool clearAutoSpeak = false,
  }) {
    return ChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isWaitingForReply: isWaitingForReply ?? this.isWaitingForReply,
      autoSpeakText: clearAutoSpeak
          ? null
          : (autoSpeakText ?? this.autoSpeakText),
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

    state = state.copyWith(
      messages: <ChatMessage>[...state.messages, pending],
      isWaitingForReply: true,
      clearAutoSpeak: true,
    );

    await _deliver(pending);
  }

  /// Mic turn: Addis listens, the demo script answers when it can, and the
  /// reply is flagged to be spoken aloud.
  Future<void> sendAudio(Uint8List wavBytes) async {
    if (state.isWaitingForReply || wavBytes.isEmpty) return;

    final ChatMessage pending = ChatMessage(
      id: _nextLocalId--,
      sessionId: state.sessionId,
      role: ChatRole.user,
      content: '🎤 እየሰማሁ ነው…',
      createdAt: DateTime.now(),
      delivery: MessageDelivery.sending,
    );

    state = state.copyWith(
      messages: <ChatMessage>[...state.messages, pending],
      isWaitingForReply: true,
      clearAutoSpeak: true,
    );

    try {
      final ({ChatReply reply, String? transcript, bool speakAloud}) result =
          await ref
              .read(chatRepositoryProvider)
              .sendAudio(wavBytes, sessionId: state.sessionId);

      final String? heard = result.transcript?.trim();
      final String shown =
          (heard == null || heard.isEmpty) ? '🎤 የድምጽ መልዕክት' : heard;

      _replace(
        pending.copyWith(
          delivery: MessageDelivery.sent,
          sessionId: result.reply.sessionId,
          content: shown,
        ),
      );
      state = state.copyWith(
        sessionId: result.reply.sessionId,
        messages: <ChatMessage>[...state.messages, result.reply.message],
        isWaitingForReply: false,
        autoSpeakText: result.speakAloud ? result.reply.message.content : null,
      );
    } on ApiException {
      _replace(pending.copyWith(delivery: MessageDelivery.failed));
      state = state.copyWith(isWaitingForReply: false, clearAutoSpeak: true);
    }
  }

  void clearAutoSpeak() {
    if (state.autoSpeakText == null) return;
    state = state.copyWith(clearAutoSpeak: true);
  }

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
    state = state.copyWith(isWaitingForReply: true, clearAutoSpeak: true);

    await _deliver(failed);
  }

  Future<void> _deliver(ChatMessage pending) async {
    try {
      final List<ChatMessage> history = state.messages
          .where(
            (ChatMessage m) =>
                m.id != pending.id && m.delivery == MessageDelivery.sent,
          )
          .toList();

      final ChatReply reply = await ref
          .read(chatRepositoryProvider)
          .send(
            message: pending.content,
            sessionId: state.sessionId,
            history: history,
          );

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
        clearAutoSpeak: true,
      );
    } on ApiException {
      _replace(pending.copyWith(delivery: MessageDelivery.failed));
      state = state.copyWith(isWaitingForReply: false, clearAutoSpeak: true);
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
