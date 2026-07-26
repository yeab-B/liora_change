import 'dart:convert';
import 'dart:typed_data';

import 'package:addis_ai_sdk/addis_ai_sdk.dart';

import '../api/api_exception.dart';
import '../config/demo_ai_config.dart';

/// Addis AI — Ethiopian-language chat, TTS, and audio understanding.
///
/// Used for Amharic text turns and for microphone input (the model hears the
/// recording and returns both a transcription and a coach reply).
class AddisCoachClient {
  AddisCoachClient({AddisAI? client, String? apiKey})
    : _addis = client ?? AddisAI(apiKey: apiKey ?? DemoAiConfig.addisApiKey);

  final AddisAI _addis;

  static const String coachSystemHint =
      'You are Liora Change\'s warm habit coach. Keep answers short and kind. '
      'Never shame a missed day. Prefer a tiny next step.';

  Future<String> replyText({
    required String message,
    List<({String role, String content})> history =
        const <({String role, String content})>[],
  }) async {
    try {
      final ChatResponse response = await _addis.generateChat(
        ChatRequest(
          prompt: '$coachSystemHint\n\nMember: $message',
          targetLanguage: Language.am,
          conversationHistory: history
              .map(
                (({String role, String content}) turn) => ChatMessage(
                  role: turn.role,
                  content: turn.content,
                ),
              )
              .toList(),
          generationConfig: const GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 512,
          ),
        ),
      );
      final String text = response.responseText.trim();
      if (text.isEmpty) {
        throw const ApiException(
          message: 'Addis AI returned an empty answer. Please try again.',
        );
      }
      return text;
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      throw ApiException(message: 'Addis AI chat failed: $error');
    }
  }

  /// Sends a short WAV/PCM recording. Returns the spoken transcript (when the
  /// API provides one) and the coach's spoken-language reply.
  Future<({String? transcript, String reply})> replyToAudio(
    Uint8List wavBytes,
  ) async {
    try {
      final ChatResponse response = await _addis.generateChatWithAttachments(
        ChatRequest(
          prompt: coachSystemHint,
          targetLanguage: Language.am,
          attachmentFieldNames: const <String>['chat_audio_input'],
          generationConfig: const GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 512,
          ),
        ),
        files: <String, List<int>>{'chat_audio_input': wavBytes},
        fileNames: const <String, String>{'chat_audio_input': 'voice.wav'},
      );

      final String reply = response.responseText.trim();
      if (reply.isEmpty) {
        throw const ApiException(
          message: 'Addis AI could not understand that recording.',
        );
      }
      return (
        transcript: response.transcriptionClean ?? response.transcriptionRaw,
        reply: reply,
      );
    } on ApiException {
      rethrow;
    } on Object catch (error) {
      throw ApiException(message: 'Addis AI voice failed: $error');
    }
  }

  Future<Uint8List> synthesize(String text) async {
    try {
      final bool ethiopian = DemoAiConfig.looksEthiopian(text);
      final TtsResponse response = await _addis.textToSpeech(
        TtsRequest(
          text: text,
          language: ethiopian ? Language.am : Language.en,
        ),
      );
      String payload = response.audioBase64;
      final int comma = payload.indexOf(',');
      if (payload.startsWith('data:') && comma != -1) {
        payload = payload.substring(comma + 1);
      }
      return base64Decode(payload);
    } on Object catch (error) {
      throw ApiException(message: 'Addis AI speech failed: $error');
    }
  }

  void close() => _addis.close();
}
