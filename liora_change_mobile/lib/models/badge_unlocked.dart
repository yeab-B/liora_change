/// `BadgeUnlocked` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.21.
class BadgeUnlocked {
  const BadgeUnlocked({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.unlockedAt,
  });

  final int id;

  /// Matches a [BadgeCatalogue] entry, e.g. `first_checkin`.
  final String code;
  final String name;
  final String? description;
  final DateTime? unlockedAt;

  factory BadgeUnlocked.fromJson(Map<String, dynamic> json) {
    return BadgeUnlocked(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Badge',
      description: json['description'] as String?,
      unlockedAt: DateTime.tryParse(json['unlocked_at'] as String? ?? ''),
    );
  }
}

/// The badges the MVP can award, from `docs/mvp/05-api-contract.md` §6.2.
///
/// The API only reports what a member has already earned, so the full set
/// lives here — a locked badge is a goal worth showing, not a secret.
class BadgeDefinition {
  const BadgeDefinition({
    required this.code,
    required this.name,
    required this.description,
  });

  final String code;
  final String name;
  final String description;
}

abstract final class BadgeCatalogue {
  static const List<BadgeDefinition> all = <BadgeDefinition>[
    BadgeDefinition(
      code: 'first_checkin',
      name: 'First step',
      description: 'Log your first check-in.',
    ),
    BadgeDefinition(
      code: 'streak_3',
      name: 'Three in a row',
      description: 'Check in three days running.',
    ),
    BadgeDefinition(
      code: 'streak_7',
      name: 'A full week',
      description: 'Check in seven days running.',
    ),
    BadgeDefinition(
      code: 'comeback',
      name: 'Comeback',
      description: 'Come back the day after a skip.',
    ),
  ];
}
