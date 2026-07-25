/// API paths from `docs/mvp/05-api-contract.md` §9, relative to `/api/v1`.
///
/// These names are frozen by `docs/mvp/teams/SHARED-DATA-CONTRACT.md` — where
/// an issue file disagrees with the contract, the contract wins (for example
/// the current user lives at `/me`, not `/auth/me`).
abstract final class Endpoints {
  // Auth — MVP-MUST
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/me';

  // Challenges — MVP-MUST
  static const String challenges = '/challenges';

  static String challenge(int id) => '/challenges/$id';

  static String activateChallenge(int id) => '/challenges/$id/activate';

  static String checkIns(int challengeId) =>
      '/challenges/$challengeId/check-ins';

  // Dashboard, progress and recovery — MVP-MUST (progress is MVP-NICE)
  static const String dashboard = '/dashboard';
  static const String progress = '/progress';
  static const String currentRecovery = '/recovery/current';

  // AI — MVP-MUST
  static const String aiMotivation = '/ai/motivation';
  static const String aiChat = '/ai/chat';

  // AI history — MVP-NICE
  static const String aiChatSessions = '/ai/chat/sessions';

  static String aiChatSessionMessages(int sessionId) =>
      '/ai/chat/sessions/$sessionId/messages';

  // Catalogue and gamification — MVP-NICE
  static const String challengeCategories = '/challenge-categories';
  static const String challengeTemplates = '/challenge-templates';
  static const String xpHistory = '/xp/history';
  static const String unlockedBadges = '/badges/unlocked';
}
