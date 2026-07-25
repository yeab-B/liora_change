/// `Progress` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.11 — the
/// lifetime numbers behind the profile screen.
class Progress {
  const Progress({
    this.xpTotal = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.successRate = 0,
    this.completedCheckins = 0,
    this.skippedCheckins = 0,
    this.activeChallenges = 0,
    this.completedChallenges = 0,
  });

  final int xpTotal;
  final int level;
  final int currentStreak;
  final int longestStreak;

  /// Completed share of all logged days, 0–100 with up to two decimals.
  final double successRate;
  final int completedCheckins;
  final int skippedCheckins;
  final int activeChallenges;
  final int completedChallenges;

  int get totalChallenges => activeChallenges + completedChallenges;

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      xpTotal: json['xp_total'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0,
      completedCheckins: json['completed_checkins'] as int? ?? 0,
      skippedCheckins: json['skipped_checkins'] as int? ?? 0,
      activeChallenges: json['active_challenges'] as int? ?? 0,
      completedChallenges: json['completed_challenges'] as int? ?? 0,
    );
  }
}
