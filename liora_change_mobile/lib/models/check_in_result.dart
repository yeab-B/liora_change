import 'check_in.dart';

/// `CheckInResult` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.5 — the
/// `data` of a create check-in call: the recorded day plus what it changed.
class CheckInResult {
  const CheckInResult({required this.checkIn, required this.summary});

  final CheckIn checkIn;
  final CheckInSummary summary;

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    final Object? summary = json['summary'];
    return CheckInResult(
      checkIn: CheckIn.fromJson(json['check_in'] as Map<String, dynamic>),
      summary: CheckInSummary.fromJson(
        summary is Map<String, dynamic> ? summary : const <String, dynamic>{},
      ),
    );
  }
}

/// `CheckInSummary` from the contract's §3.6.
class CheckInSummary {
  const CheckInSummary({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.xpTotal = 0,
    this.xpEarned = 0,
    this.challengeProgressPercent = 0,
    this.recoveryAvailable = false,
  });

  final int currentStreak;
  final int longestStreak;

  /// The member's total after this action, not just this challenge's.
  final int xpTotal;
  final int xpEarned;
  final double challengeProgressPercent;

  /// True after a skip or a miss — the hand-off into the recovery flow.
  final bool recoveryAvailable;

  factory CheckInSummary.fromJson(Map<String, dynamic> json) {
    return CheckInSummary(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      xpTotal: json['xp_total'] as int? ?? 0,
      xpEarned: json['xp_earned'] as int? ?? 0,
      challengeProgressPercent:
          (json['challenge_progress_percent'] as num?)?.toDouble() ?? 0,
      recoveryAvailable: json['recovery_available'] as bool? ?? false,
    );
  }
}
