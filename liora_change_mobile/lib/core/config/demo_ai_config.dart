/// Demo-day AI keys for when the Laravel backend cannot serve `/ai/*`.
///
/// Override without rebuilding secrets into a release binary:
/// ```
/// flutter run --dart-define=USE_MOCK_API=true \
///   --dart-define=GEMINI_API_KEY=... \
///   --dart-define=ADDIS_AI_API_KEY=...
/// ```
///
/// The chat key the team supplied is a Google AI Studio (`AIza…`) key — that
/// is Gemini, not xAI Grok. Addis AI is the Ethiopian-language voice path.
abstract final class DemoAiConfig {
  /// Google Gemini (AI Studio) key used for English coach text replies.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue:
        'AIzaSyDLz_x1ZC64kLmDq0aGxuxtUKrSZuLI7Uc',
  );

  /// Addis AI key — TTS and Amharic / Ethiopian audio understanding.
  static const String addisApiKey = String.fromEnvironment(
    'ADDIS_AI_API_KEY',
    defaultValue:
        'sk_94ba77c8-e4b7-457a-9f83-0751e8b3d5da_6ce13fddfaa9cf996d3b08f26f2d9ac74537eab37917fcd17507a6c5850bce39',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  /// Direct coach calls are on whenever a demo key is present.
  static bool get directCoachEnabled =>
      geminiApiKey.isNotEmpty || addisApiKey.isNotEmpty;

  static bool get geminiEnabled => geminiApiKey.isNotEmpty;

  static bool get addisEnabled => addisApiKey.isNotEmpty;

  /// Ge'ez / Ethiopic script — route these turns to Addis AI.
  static bool looksEthiopian(String text) =>
      RegExp(r'[\u1200-\u137F]').hasMatch(text);
}
