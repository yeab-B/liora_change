import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/models/challenge.dart';
import 'package:liora_change_mobile/models/challenge_category.dart';
import 'package:liora_change_mobile/models/challenge_template.dart';
import 'package:liora_change_mobile/models/check_in.dart';
import 'package:liora_change_mobile/models/check_in_result.dart';
import 'package:liora_change_mobile/models/enums.dart';

/// In-memory stand-in for [ChallengeRepository] that records what the UI sent.
class FakeChallengeRepository implements ChallengeRepository {
  List<Challenge> challenges = <Challenge>[];
  List<ChallengeCategory> categories = defaultCategories;
  List<ChallengeTemplate> templates = defaultTemplates;

  List<CheckIn> checkIns = <CheckIn>[];

  Object? listError;
  Object? categoriesError;
  Object? createError;
  Object? detailError;
  Object? activateError;
  Object? checkInsError;
  Object? checkInError;

  /// Overrides what a submitted check-in returns.
  CheckInResult? checkInResult;
  Duration? checkInDelay;

  int checkInCalls = 0;
  Map<String, Object?>? lastCheckInRequest;

  /// Holds the detail call open so a test can observe the loading state.
  Duration? detailDelay;

  int detailCalls = 0;
  int activateCalls = 0;

  /// Holds the list call open so a test can observe the loading state.
  Duration? listDelay;

  int listCalls = 0;
  int createCalls = 0;
  Map<String, Object?>? lastCreateRequest;

  static const List<ChallengeCategory> defaultCategories = <ChallengeCategory>[
    ChallengeCategory(id: 1, name: 'Health', slug: 'health'),
    ChallengeCategory(id: 2, name: 'Focus', slug: 'focus'),
  ];

  static const List<ChallengeTemplate> defaultTemplates = <ChallengeTemplate>[
    ChallengeTemplate(
      id: 1,
      title: '7-Day Morning Walk',
      description: 'Walk 10 minutes after waking up.',
      categoryId: 1,
    ),
    ChallengeTemplate(
      id: 2,
      title: 'No Sugar Week',
      description: 'Skip added sugar for seven days.',
      difficulty: ChallengeDifficulty.medium,
      categoryId: 1,
    ),
  ];

  @override
  Future<List<Challenge>> getMyChallenges({ChallengeStatus? status}) async {
    listCalls++;
    if (listDelay != null) await Future<void>.delayed(listDelay!);
    if (listError != null) throw listError!;
    return challenges;
  }

  @override
  Future<Challenge> getChallenge(int id) async {
    detailCalls++;
    if (detailDelay != null) await Future<void>.delayed(detailDelay!);
    if (detailError != null) throw detailError!;
    return challenges.firstWhere(
      (Challenge c) => c.id == id,
      orElse: () => throw StateError('No challenge $id'),
    );
  }

  @override
  Future<Challenge> activateChallenge(int id) async {
    activateCalls++;
    if (activateError != null) throw activateError!;

    final Challenge current = await getChallenge(id);
    final Challenge activated = Challenge(
      id: current.id,
      title: current.title,
      description: current.description,
      status: ChallengeStatus.active,
      difficulty: current.difficulty,
      categoryId: current.categoryId,
      durationDays: current.durationDays,
      startDate: '2026-07-26',
    );
    challenges = <Challenge>[
      for (final Challenge c in challenges)
        if (c.id == id) activated else c,
    ];
    return activated;
  }

  @override
  Future<List<CheckIn>> getCheckIns(int challengeId) async {
    if (checkInsError != null) throw checkInsError!;
    return checkIns;
  }

  @override
  Future<CheckInResult> submitCheckIn({
    required int challengeId,
    required CheckInStatus status,
    String? note,
    int? mood,
    int? energy,
  }) async {
    checkInCalls++;
    lastCheckInRequest = <String, Object?>{
      'challenge_id': challengeId,
      'status': status.wire,
      'note': note,
    };
    if (checkInDelay != null) await Future<void>.delayed(checkInDelay!);
    if (checkInError != null) throw checkInError!;

    return checkInResult ??
        CheckInResult(
          checkIn: CheckIn(
            id: 1,
            challengeId: challengeId,
            checkInDate: '2026-07-26',
            status: status,
          ),
          summary: const CheckInSummary(),
        );
  }

  @override
  Future<List<ChallengeCategory>> getCategories() async {
    if (categoriesError != null) throw categoriesError!;
    return categories;
  }

  @override
  Future<List<ChallengeTemplate>> getTemplates({int? categoryId}) async {
    return templates
        .where(
          (ChallengeTemplate t) =>
              categoryId == null || t.categoryId == categoryId,
        )
        .toList();
  }

  @override
  Future<Challenge> createChallenge({
    required String title,
    String? description,
    ChallengeDifficulty? difficulty,
    ChallengeVisibility? visibility,
    int? durationDays,
    int? categoryId,
  }) async {
    createCalls++;
    lastCreateRequest = <String, Object?>{
      'title': title,
      'description': description,
      'difficulty': difficulty?.wire,
      'visibility': visibility?.wire,
      'duration_days': durationDays,
      'category_id': categoryId,
    };
    if (createError != null) throw createError!;

    final Challenge created = Challenge(
      id: 42,
      title: title,
      description: description,
      categoryId: categoryId,
    );
    challenges = <Challenge>[...challenges, created];
    return created;
  }
}
