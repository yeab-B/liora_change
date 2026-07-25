import 'package:flutter_riverpod/flutter_riverpod.dart';
// `NotifierProviderFamily` lives here in Riverpod 3.
import 'package:flutter_riverpod/misc.dart';

import '../../../models/check_in_result.dart';
import '../../../models/enums.dart';
import '../../challenges/application/challenge_detail_controller.dart';
import '../../challenges/application/challenge_list_controller.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../home/application/dashboard_controller.dart';
import '../../recovery/application/recovery_controller.dart';

/// Submits today's check-in for one challenge.
///
/// The state starts as `data(null)` — nothing submitted yet — so the sheet can
/// tell "idle" apart from "in flight" without a second flag.
class CheckInController extends AsyncNotifier<CheckInResult?> {
  CheckInController(this.challengeId);

  final int challengeId;

  @override
  Future<CheckInResult?> build() async => null;

  Future<void> submit({required CheckInStatus status, String? note}) async {
    if (state.isLoading) return; // Double-tap guard.

    state = const AsyncValue<CheckInResult?>.loading();

    final String? trimmed = note?.trim();
    final AsyncValue<CheckInResult?> result =
        await AsyncValue.guard<CheckInResult?>(
          () => ref
              .read(challengeRepositoryProvider)
              .submitCheckIn(
                challengeId: challengeId,
                status: status,
                note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
              ),
        );

    state = result;
    if (result.hasError) return;

    // Everything that shows a streak, a progress bar or a history is now
    // stale; invalidating here means the screens behind the sheet are correct
    // by the time it closes.
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(challengeDetailControllerProvider(challengeId));
    ref.invalidate(checkInHistoryProvider(challengeId));
    ref.invalidate(challengeListControllerProvider);
    // A completed day clears recovery; a skip opens one.
    ref.invalidate(recoveryControllerProvider);
  }
}

final AsyncNotifierProviderFamily<CheckInController, CheckInResult?, int>
checkInControllerProvider =
    AsyncNotifierProvider.family<CheckInController, CheckInResult?, int>(
      CheckInController.new,
      retry: (int retryCount, Object error) => null,
    );
