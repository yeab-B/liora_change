import 'enums.dart';

/// `CheckIn` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.4 — one recorded
/// day of a challenge.
class CheckIn {
  const CheckIn({
    required this.id,
    required this.challengeId,
    required this.checkInDate,
    required this.status,
    this.note,
    this.mood,
    this.energy,
    this.xpEarned = 0,
    this.streakAfter = 0,
    this.createdAt,
  });

  final int id;
  final int challengeId;

  /// `YYYY-MM-DD` in the member's timezone.
  final String checkInDate;
  final CheckInStatus status;
  final String? note;

  /// 1–5, both optional.
  final int? mood;
  final int? energy;
  final int xpEarned;

  /// The challenge streak immediately after this day was recorded.
  final int streakAfter;
  final DateTime? createdAt;

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as int,
      challengeId: json['challenge_id'] as int,
      checkInDate: json['check_in_date'] as String? ?? '',
      status: CheckInStatus.fromWire(json['status']),
      note: json['note'] as String?,
      mood: json['mood'] as int?,
      energy: json['energy'] as int?,
      xpEarned: json['xp_earned'] as int? ?? 0,
      streakAfter: json['streak_after'] as int? ?? 0,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
