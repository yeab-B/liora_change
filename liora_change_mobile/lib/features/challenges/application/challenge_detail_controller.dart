import 'package:flutter_riverpod/flutter_riverpod.dart';
// `AsyncNotifierProviderFamily` and `FutureProviderFamily` live here.
import 'package:flutter_riverpod/misc.dart';

import '../../../models/challenge.dart';
import '../../../models/check_in.dart';
import '../data/challenge_repository.dart';
import 'challenge_list_controller.dart';

/// One challenge, keyed by id.
///
/// Riverpod 3 fuses family notifiers with plain ones: the id arrives through
/// the constructor rather than `build`.
class ChallengeDetailController extends AsyncNotifier<Challenge> {
  ChallengeDetailController(this.challengeId);

  final int challengeId;

  @override
  Future<Challenge> build() {
    return ref.watch(challengeRepositoryProvider).getChallenge(challengeId);
  }

  /// Returns true when the challenge is now active. The activated challenge
  /// comes back in the response, so the screen updates without a re-fetch.
  ///
  /// State is left alone while the call is in flight — the button carries the
  /// loading state, so the screen never flickers back to a skeleton over
  /// content the member is already reading.
  Future<bool> activate() async {
    final AsyncValue<Challenge> result = await AsyncValue.guard<Challenge>(
      () =>
          ref.read(challengeRepositoryProvider).activateChallenge(challengeId),
    );

    if (result.hasError) {
      _lastError = result.error;
      return false;
    }

    state = result;
    ref.invalidate(challengeListControllerProvider);
    return true;
  }

  Object? _lastError;

  /// The error from the most recent failed [activate], if any.
  Object? get lastError => _lastError;
}

final AsyncNotifierProviderFamily<ChallengeDetailController, Challenge, int>
challengeDetailControllerProvider =
    AsyncNotifierProvider.family<ChallengeDetailController, Challenge, int>(
      ChallengeDetailController.new,
      retry: (int retryCount, Object error) => null,
    );

final FutureProviderFamily<List<CheckIn>, int> checkInHistoryProvider =
    FutureProvider.family<List<CheckIn>, int>(
      (Ref ref, int challengeId) =>
          ref.watch(challengeRepositoryProvider).getCheckIns(challengeId),
      retry: (int retryCount, Object error) => null,
    );
