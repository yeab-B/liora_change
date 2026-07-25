import 'enums.dart';

/// `ChallengeTemplate` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.13.
///
/// A template is only a prefilled `CreateChallengeRequest`: the API has no
/// `template_id` field, so picking one copies its values into the create call.
class ChallengeTemplate {
  const ChallengeTemplate({
    required this.id,
    required this.title,
    this.description,
    this.difficulty = ChallengeDifficulty.beginner,
    this.durationDays = 7,
    this.categoryId,
  });

  final int id;
  final String title;
  final String? description;
  final ChallengeDifficulty difficulty;
  final int durationDays;
  final int? categoryId;

  factory ChallengeTemplate.fromJson(Map<String, dynamic> json) {
    return ChallengeTemplate(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      difficulty: ChallengeDifficulty.fromWire(json['difficulty']),
      durationDays: json['duration_days'] as int? ?? 7,
      categoryId: json['category_id'] as int?,
    );
  }
}
