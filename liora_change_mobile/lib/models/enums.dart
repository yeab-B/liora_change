/// Enums from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §2, declared exactly as
/// `docs/mvp/teams/MOBILE-TEAM-GUIDE.md` §4.1 specifies.
///
/// Wire values are the contract's strings. Parsing is lenient: an unrecognised
/// value falls back to the documented default rather than throwing, so one
/// unexpected string from the API cannot take a screen down.
library;

enum ChallengeStatus {
  draft,
  ready,
  active,
  paused,
  completed,
  cancelled,
  archived;

  static ChallengeStatus fromWire(Object? value) {
    for (final ChallengeStatus status in ChallengeStatus.values) {
      if (status.name == value) return status;
    }
    return ChallengeStatus.draft;
  }

  String get wire => name;

  bool get isActive => this == ChallengeStatus.active;
}

enum ChallengeDifficulty {
  beginner,
  easy,
  medium,
  hard,
  expert;

  static ChallengeDifficulty fromWire(Object? value) {
    for (final ChallengeDifficulty difficulty in ChallengeDifficulty.values) {
      if (difficulty.name == value) return difficulty;
    }
    return ChallengeDifficulty.beginner;
  }

  String get wire => name;
}

/// Trailing underscores avoid the `private` keyword clash called out in the
/// mobile guide; [wire] carries the real contract value.
enum ChallengeVisibility {
  private_('private'),
  public_('public');

  const ChallengeVisibility(this.wire);

  final String wire;

  static ChallengeVisibility fromWire(Object? value) {
    return value == 'public'
        ? ChallengeVisibility.public_
        : ChallengeVisibility.private_;
  }
}

enum CheckInStatus {
  completed,
  skipped,
  missed;

  static CheckInStatus fromWire(Object? value) {
    for (final CheckInStatus status in CheckInStatus.values) {
      if (status.name == value) return status;
    }
    return CheckInStatus.missed;
  }

  String get wire => name;
}

enum RecoveryReason {
  skipped,
  missed;

  static RecoveryReason fromWire(Object? value) {
    return value == 'missed' ? RecoveryReason.missed : RecoveryReason.skipped;
  }

  String get wire => name;
}

enum ChatRole {
  user,
  assistant;

  static ChatRole fromWire(Object? value) =>
      value == 'user' ? ChatRole.user : ChatRole.assistant;

  String get wire => name;
}

enum MotivationTone {
  encouraging,
  calm,
  direct,
  celebratory;

  static MotivationTone fromWire(Object? value) {
    for (final MotivationTone tone in MotivationTone.values) {
      if (tone.name == value) return tone;
    }
    return MotivationTone.encouraging;
  }

  String get wire => name;
}

/// Where the message came from. The UI renders both identically — this is for
/// the backend's analytics, not a quality signal to the member.
enum MotivationSource {
  openai,
  template;

  static MotivationSource fromWire(Object? value) =>
      value == 'openai' ? MotivationSource.openai : MotivationSource.template;

  String get wire => name;
}

enum MotivationContext {
  morning,
  recovery,
  general;

  String get wire => name;
}

enum SuggestedActionType {
  checkIn('check_in');

  const SuggestedActionType(this.wire);

  final String wire;

  static SuggestedActionType fromWire(Object? value) =>
      SuggestedActionType.checkIn;
}
