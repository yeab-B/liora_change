enum ChallengeStatus {
  draft,
  ready,
  active,
  paused,
  completed,
  cancelled,
  archived;

  static ChallengeStatus fromJson(String value) =>
      ChallengeStatus.values.byName(value);
}

enum CheckInStatus {
  completed,
  skipped,
  missed;

  static CheckInStatus fromJson(String value) =>
      CheckInStatus.values.byName(value);

  String toJson() => name;
}

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.difficulty,
    required this.visibility,
    this.categoryId,
    this.startDate,
    this.endDate,
    required this.durationDays,
    required this.progressPercent,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedCheckins,
    required this.missedCheckins,
    required this.checkedInToday,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final ChallengeStatus status;
  final String difficulty;
  final String visibility;
  final int? categoryId;
  final String? startDate;
  final String? endDate;
  final int durationDays;
  final double progressPercent;
  final int currentStreak;
  final int longestStreak;
  final int completedCheckins;
  final int missedCheckins;
  final bool checkedInToday;
  final String createdAt;
  final String updatedAt;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: ChallengeStatus.fromJson(json['status'] as String),
      difficulty: json['difficulty'] as String,
      visibility: json['visibility'] as String,
      categoryId: json['category_id'] as int?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      durationDays: json['duration_days'] as int,
      progressPercent: (json['progress_percent'] as num).toDouble(),
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      completedCheckins: json['completed_checkins'] as int,
      missedCheckins: json['missed_checkins'] as int,
      checkedInToday: json['checked_in_today'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.challengeId,
    required this.checkInDate,
    required this.status,
    this.note,
    this.mood,
    this.energy,
    required this.xpEarned,
    required this.streakAfter,
    required this.createdAt,
  });

  final int id;
  final int challengeId;
  final String checkInDate;
  final CheckInStatus status;
  final String? note;
  final int? mood;
  final int? energy;
  final int xpEarned;
  final int streakAfter;
  final String createdAt;

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as int,
      challengeId: json['challenge_id'] as int,
      checkInDate: json['check_in_date'] as String,
      status: CheckInStatus.fromJson(json['status'] as String),
      note: json['note'] as String?,
      mood: json['mood'] as int?,
      energy: json['energy'] as int?,
      xpEarned: json['xp_earned'] as int,
      streakAfter: json['streak_after'] as int,
      createdAt: json['created_at'] as String,
    );
  }
}

class CheckInSummary {
  const CheckInSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.xpTotal,
    required this.xpEarned,
    required this.challengeProgressPercent,
    required this.recoveryAvailable,
  });

  final int currentStreak;
  final int longestStreak;
  final int xpTotal;
  final int xpEarned;
  final double challengeProgressPercent;
  final bool recoveryAvailable;

  factory CheckInSummary.fromJson(Map<String, dynamic> json) {
    return CheckInSummary(
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      xpTotal: json['xp_total'] as int,
      xpEarned: json['xp_earned'] as int,
      challengeProgressPercent:
          (json['challenge_progress_percent'] as num).toDouble(),
      recoveryAvailable: json['recovery_available'] as bool,
    );
  }
}

class CheckInResult {
  const CheckInResult({
    required this.checkIn,
    required this.summary,
  });

  final CheckIn checkIn;
  final CheckInSummary summary;

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      checkIn: CheckIn.fromJson(json['check_in'] as Map<String, dynamic>),
      summary: CheckInSummary.fromJson(json['summary'] as Map<String, dynamic>),
    );
  }
}
