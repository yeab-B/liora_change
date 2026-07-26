import 'package:dio/dio.dart';

import '../api/api_exception.dart';
import '../config/demo_ai_config.dart';

/// Direct Google Gemini calls for the coach when the Laravel `/ai/chat` path
/// is unavailable.
///
/// The supplied key is an AI Studio (`AIza…`) key — Gemini REST, not xAI.
class GeminiCoachClient {
  GeminiCoachClient({Dio? dio, String? apiKey, String? model})
    : _dio = dio ?? Dio(),
      _apiKey = apiKey ?? DemoAiConfig.geminiApiKey,
      _model = model ?? DemoAiConfig.geminiModel;

  final Dio _dio;
  final String _apiKey;
  final String _model;

  static const String systemPrompt =
      'You are Liora Change\'s supportive habit coach. Be warm, practical, and '
      'brief (2–5 short sentences). Never shame a missed day — treat skips as '
      'information. Prefer tiny next steps. Ground answers in these facts when '
      'relevant:\n'
      '- Start absurdly small; consistency beats intensity.\n'
      '- After a miss, restart with a tiny action instead of quitting.\n'
      '- Streaks motivate; a broken streak does not erase progress.\n'
      '- One check-in per challenge per calendar day (completed or skipped).\n'
      '- Good challenges are specific, small, and tied to a clear trigger.\n'
      'If the member writes in Amharic or another Ethiopian language, reply in '
      'the same language.';

  Future<String> reply({
    required String message,
    List<({String role, String content})> history = const <({String role, String content})>[],
  }) async {
    if (_apiKey.isEmpty) {
      throw const ApiException(message: 'Gemini API key is not configured.');
    }

    final List<Map<String, dynamic>> contents = <Map<String, dynamic>>[
      for (final ({String role, String content}) turn in history)
        <String, dynamic>{
          'role': turn.role == 'assistant' ? 'model' : 'user',
          'parts': <Map<String, String>>[
            <String, String>{'text': turn.content},
          ],
        },
      <String, dynamic>{
        'role': 'user',
        'parts': <Map<String, String>>[
          <String, String>{'text': message},
        ],
      },
    ];

    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$_model:generateContent',
        queryParameters: <String, String>{'key': _apiKey},
        data: <String, dynamic>{
          'system_instruction': <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': systemPrompt},
            ],
          },
          'contents': contents,
          'generationConfig': <String, dynamic>{
            'temperature': 0.7,
            'maxOutputTokens': 512,
          },
        },
        options: Options(
          headers: <String, String>{'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

      final String? text = _extractText(response.data);
      if (text == null || text.trim().isEmpty) {
        throw const ApiException(
          message: 'The coach returned an empty answer. Please try again.',
        );
      }
      return text.trim();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  String? _extractText(dynamic body) {
    if (body is! Map) return null;
    final dynamic candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final dynamic first = candidates.first;
    if (first is! Map) return null;
    final dynamic content = first['content'];
    if (content is! Map) return null;
    final dynamic parts = content['parts'];
    if (parts is! List) return null;
    final StringBuffer buffer = StringBuffer();
    for (final dynamic part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    return buffer.toString();
  }
}
