import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/check_in_models.dart';
import '../data/challenge_repository.dart';

class ChallengeDetailController
    extends AutoDisposeFamilyAsyncNotifier<Challenge, int> {
  @override
  Future<Challenge> build(int id) {
    return ref.read(challengeRepositoryProvider).getChallenge(id);
  }

  Future<void> activate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(challengeRepositoryProvider).activateChallenge(arg),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(challengeRepositoryProvider).getChallenge(arg),
    );
  }
}

final challengeDetailControllerProvider = AutoDisposeAsyncNotifierProviderFamily<
    ChallengeDetailController, Challenge, int>(
  ChallengeDetailController.new,
);
