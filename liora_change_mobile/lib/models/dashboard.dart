import 'challenge.dart';
import 'recovery.dart';

/// `Dashboard` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.7 — everything
/// Home renders, in one payload.
class Dashboard {
  const Dashboard({
    required this.user,
    required this.today,
    required this.activeChallenges,
    this.recovery = Recovery.inactive,
    this.motivationPreview,
  });

  final DashboardUser user;
  final TodaySummary today;
  final List<Challenge> activeChallenges;
  final Recovery recovery;

  /// Short motivation line; Issue #8 replaces this with a generated card.
  final String? motivationPreview;

  /// The challenge Home leads with for motivation — usually the newest active.
  Challenge? get primaryChallenge =>
      activeChallenges.isEmpty ? null : activeChallenges.first;

  bool get hasActiveChallenge => activeChallenges.isNotEmpty;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final Object? challenges = json['active_challenges'];
    final Object? recovery = json['recovery'];

    return Dashboard(
      user: DashboardUser.fromJson(json['user'] as Map<String, dynamic>),
      today: TodaySummary.fromJson(json['today'] as Map<String, dynamic>),
      activeChallenges: challenges is List
          ? challenges
                .whereType<Map<String, dynamic>>()
                .map(Challenge.fromJson)
                .toList()
          : const <Challenge>[],
      recovery: Recovery.fromJson(
        recovery is Map<String, dynamic> ? recovery : null,
      ),
      motivationPreview: json['motivation_preview'] as String?,
    );
  }
}

/// The contract permits the dashboard's `user` to be a subset of `User`
/// (§3.7), and the API example omits `id` and `email` — so this holds only the
/// fields Home can rely on. Extra keys from a fuller payload are ignored.
class DashboardUser {
  const DashboardUser({
    required this.name,
    this.xpTotal = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  final String name;
  final int xpTotal;
  final int level;
  final int currentStreak;
  final int longestStreak;

  /// XP earned inside the current level, and how much the level needs.
  static const int xpPerLevel = 100;

  int get xpIntoLevel => xpTotal % xpPerLevel;

  double get levelProgressPercent => xpIntoLevel / xpPerLevel * 100;

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      name: json['name'] as String? ?? 'there',
      xpTotal: json['xp_total'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
    );
  }
}

/// `TodaySummary` from the contract's §3.8.
class TodaySummary {
  const TodaySummary({
    required this.date,
    this.activeChallengesCount = 0,
    this.completedCheckinsCount = 0,
    this.pendingCheckinsCount = 0,
  });

  /// `YYYY-MM-DD` in the user's timezone.
  final String date;
  final int activeChallengesCount;
  final int completedCheckinsCount;
  final int pendingCheckinsCount;

  bool get allDone => activeChallengesCount > 0 && pendingCheckinsCount == 0;

  factory TodaySummary.fromJson(Map<String, dynamic> json) {
    return TodaySummary(
      date: json['date'] as String? ?? '',
      activeChallengesCount: json['active_challenges_count'] as int? ?? 0,
      completedCheckinsCount: json['completed_checkins_count'] as int? ?? 0,
      pendingCheckinsCount: json['pending_checkins_count'] as int? ?? 0,
    );
  }
}
