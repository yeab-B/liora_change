/// `ChallengeCategory` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.12.
class ChallengeCategory {
  const ChallengeCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;

  /// Stable key such as `health`; the UI picks its icon from this rather than
  /// from the display name, which is free to change.
  final String slug;

  factory ChallengeCategory.fromJson(Map<String, dynamic> json) {
    return ChallengeCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
    );
  }
}
