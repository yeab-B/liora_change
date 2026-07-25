import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/badge_unlocked.dart';
import '../../../models/progress.dart';
import '../data/profile_repository.dart';

/// Everything the profile screen draws, in one fetch.
class ProfileData {
  const ProfileData({required this.progress, required this.badges});

  final Progress progress;
  final List<BadgeUnlocked> badges;

  bool hasEarned(String code) =>
      badges.any((BadgeUnlocked badge) => badge.code == code);

  BadgeUnlocked? earned(String code) {
    for (final BadgeUnlocked badge in badges) {
      if (badge.code == code) return badge;
    }
    return null;
  }
}

class ProfileController extends AsyncNotifier<ProfileData> {
  @override
  Future<ProfileData> build() => _load();

  Future<void> refresh() async {
    state = await AsyncValue.guard<ProfileData>(_load);
  }

  Future<ProfileData> _load() async {
    final ProfileRepository repository = ref.read(profileRepositoryProvider);
    // Badges are an MVP-NICE endpoint: if it is missing the screen still has a
    // story to tell, so a badge failure degrades to "nothing unlocked yet"
    // rather than taking the whole profile down with it.
    final Future<List<BadgeUnlocked>> badges = repository
        .getUnlockedBadges()
        .onError(
          (Object error, StackTrace stack) => const <BadgeUnlocked>[],
        );
    final Progress progress = await repository.getProgress();

    return ProfileData(progress: progress, badges: await badges);
  }
}

final AsyncNotifierProvider<ProfileController, ProfileData>
profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileData>(
      ProfileController.new,
      // The screen offers an explicit retry; a silent background retry would
      // only make the error state flicker.
      retry: (int retryCount, Object error) => null,
    );
