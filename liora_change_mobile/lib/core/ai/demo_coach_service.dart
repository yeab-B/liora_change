import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_message.dart';
import '../../models/chat_reply.dart';
import '../../models/chat_source.dart';
import '../../models/enums.dart';
import '../config/demo_ai_config.dart';
import 'addis_coach_client.dart';
import 'demo_amharic_script.dart';
import 'gemini_coach_client.dart';

/// Mobile-side coach for demo day: scripted Amharic demo beats, Addis AI for
/// Ethiopian voice, Gemini for open English questions.
class DemoCoachService {
  DemoCoachService({GeminiCoachClient? gemini, AddisCoachClient? addis})
    : _gemini = gemini ?? GeminiCoachClient(),
      _addis = addis ?? AddisCoachClient();

  final GeminiCoachClient _gemini;
  final AddisCoachClient _addis;

  int _nextSessionId = 1;
  int _nextMessageId = 1;

  Future<ChatReply> sendText({
    required String message,
    int? sessionId,
    List<ChatMessage> history = const <ChatMessage>[],
  }) async {
    final int sid = sessionId ?? _nextSessionId++;

    final String? scripted = DemoAmharicScript.match(message);
    if (scripted != null) {
      return _asReply(sessionId: sid, content: scripted);
    }

    final List<({String role, String content})> turns = history
        .where((ChatMessage m) => m.delivery != MessageDelivery.failed)
        .map(
          (ChatMessage m) => (
            role: m.role == ChatRole.assistant ? 'assistant' : 'user',
            content: m.content,
          ),
        )
        .toList();

    final String answer;
    if (DemoAiConfig.looksEthiopian(message) && DemoAiConfig.addisEnabled) {
      answer = await _addis.replyText(message: message, history: turns);
    } else if (DemoAiConfig.geminiEnabled) {
      answer = await _gemini.reply(message: message, history: turns);
    } else if (DemoAiConfig.addisEnabled) {
      answer = await _addis.replyText(message: message, history: turns);
    } else {
      answer = DemoAmharicScript.whatIsApp;
    }

    return _asReply(sessionId: sid, content: answer);
  }

  /// Mic turn: Addis hears Ethiopian speech, we prefer the demo script, then
  /// speak the answer aloud.
  Future<({ChatReply reply, String? transcript, bool speakAloud})> sendAudio(
    Uint8List wavBytes, {
    int? sessionId,
  }) async {
    final int sid = sessionId ?? _nextSessionId++;
    final ({String? transcript, String reply}) result = await _addis
        .replyToAudio(wavBytes);

    final String heard = (result.transcript ?? '').trim();
    final String answer =
        DemoAmharicScript.match(heard) ??
        DemoAmharicScript.match(result.reply) ??
        result.reply;

    return (
      reply: _asReply(sessionId: sid, content: answer),
      transcript: heard.isEmpty ? null : heard,
      speakAloud: true,
    );
  }

  ChatReply _asReply({required int sessionId, required String content}) {
    return ChatReply(
      sessionId: sessionId,
      message: ChatMessage(
        id: _nextMessageId++,
        sessionId: sessionId,
        role: ChatRole.assistant,
        content: content,
        createdAt: DateTime.now(),
        sources: const <ChatSource>[
          ChatSource(
            title: 'Liora demo coach (Amharic)',
            snippet: 'Demo-day Amharic script answered on the phone via Addis AI.',
          ),
        ],
      ),
    );
  }
}

final Provider<DemoCoachService> demoCoachServiceProvider =
    Provider<DemoCoachService>((Ref ref) => DemoCoachService());
