/// `User` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.1.
///
/// Wire keys stay snake_case; only Dart-side names are camelCase.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.timezone,
    this.xpTotal = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  final int id;
  final String name;
  final String email;

  /// IANA identifier, e.g. `Africa/Addis_Ababa`.
  final String? timezone;
  final int xpTotal;
  final int level;
  final int currentStreak;
  final int longestStreak;

  /// The auth endpoints return the user without gamification fields, so those
  /// fall back to the contract's documented defaults.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      timezone: json['timezone'] as String?,
      xpTotal: json['xp_total'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'timezone': timezone,
    'xp_total': xpTotal,
    'level': level,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
  };
}
