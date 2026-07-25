import 'package:liora_change_mobile/features/profile/data/profile_repository.dart';
import 'package:liora_change_mobile/models/badge_unlocked.dart';
import 'package:liora_change_mobile/models/progress.dart';

/// In-memory stand-in for `GET /progress` and `GET /badges/unlocked`.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.progress = const Progress(),
    List<BadgeUnlocked>? badges,
  }) : badges = badges ?? <BadgeUnlocked>[];

  Progress progress;
  List<BadgeUnlocked> badges;

  Object? progressError;
  Object? badgesError;

  /// Holds the responses open so tests can observe the skeleton.
  Duration? delay;

  int progressCalls = 0;
  int badgeCalls = 0;

  @override
  Future<Progress> getProgress() async {
    progressCalls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (progressError != null) throw progressError!;
    return progress;
  }

  @override
  Future<List<BadgeUnlocked>> getUnlockedBadges() async {
    badgeCalls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (badgesError != null) throw badgesError!;
    return badges;
  }
}

/// A badge as the API reports it once earned.
BadgeUnlocked earnedBadge(String code, {String? name}) {
  return BadgeUnlocked(
    id: code.hashCode,
    code: code,
    name: name ?? code,
    description: 'Earned in the demo.',
    unlockedAt: DateTime(2026, 7, 20),
  );
}
