import 'enums.dart';

/// `Challenge` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.3.
///
/// The contract allows `active_challenges` on the dashboard to carry a slim
/// version of this object (see the `GET /dashboard` example in
/// `docs/mvp/05-api-contract.md` §4.1), so every field the slim payload omits
/// parses to its documented default and the timestamps are nullable.
class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    this.description,
    this.status = ChallengeStatus.draft,
    this.difficulty = ChallengeDifficulty.beginner,
    this.visibility = ChallengeVisibility.private_,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.durationDays = 7,
    this.progressPercent = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completedCheckins = 0,
    this.missedCheckins = 0,
    this.checkedInToday = false,
    this.todayCheckInStatus,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final ChallengeStatus status;
  final ChallengeDifficulty difficulty;
  final ChallengeVisibility visibility;
  final int? categoryId;

  /// `YYYY-MM-DD`; set when the challenge is activated.
  final String? startDate;
  final String? endDate;
  final int durationDays;

  /// 0–100, already a percentage — not a 0–1 fraction.
  final double progressPercent;
  final int currentStreak;
  final int longestStreak;
  final int completedCheckins;

  /// Skipped and missed days combined, per the contract's note.
  final int missedCheckins;
  final bool checkedInToday;

  /// Today's log when [checkedInToday] is true — `completed` or `skipped`.
  final CheckInStatus? todayCheckInStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get skippedToday => todayCheckInStatus == CheckInStatus.skipped;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final Object? todayStatus = json['today_check_in_status'];
    return Challenge(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: ChallengeStatus.fromWire(json['status']),
      difficulty: ChallengeDifficulty.fromWire(json['difficulty']),
      visibility: ChallengeVisibility.fromWire(json['visibility']),
      categoryId: json['category_id'] as int?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      durationDays: json['duration_days'] as int? ?? 7,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      completedCheckins: json['completed_checkins'] as int? ?? 0,
      missedCheckins: json['missed_checkins'] as int? ?? 0,
      checkedInToday: json['checked_in_today'] as bool? ?? false,
      todayCheckInStatus: todayStatus == null
          ? null
          : CheckInStatus.fromWire(todayStatus),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime? _parseDateTime(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
