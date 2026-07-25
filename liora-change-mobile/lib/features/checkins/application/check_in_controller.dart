import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/check_in_models.dart';
import '../../challenges/data/challenge_repository.dart';
import '../../challenges/application/challenge_detail_controller.dart';
import '../../home/application/dashboard_controller.dart';

enum CheckInPhase { idle, submitting, completed, skipped, error }

class CheckInState {
  const CheckInState({
    this.phase = CheckInPhase.idle,
    this.result,
    this.errorMessage,
  });

  final CheckInPhase phase;
  final CheckInResult? result;
  final String? errorMessage;

  CheckInState copyWith({
    CheckInPhase? phase,
    CheckInResult? result,
    String? errorMessage,
  }) {
    return CheckInState(
      phase: phase ?? this.phase,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

class CheckInController extends AutoDisposeFamilyNotifier<CheckInState, int> {
  @override
  CheckInState build(int challengeId) => const CheckInState();

  ChallengeRepository get _repository => ref.read(challengeRepositoryProvider);

  Future<void> submit({required String status, String? note}) async {
    if (state.phase == CheckInPhase.submitting) return;

    state = state.copyWith(phase: CheckInPhase.submitting, errorMessage: null);

    try {
      final result = await _repository.submitCheckIn(
        challengeId: arg,
        status: status,
        note: note,
      );

      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(challengeDetailControllerProvider(arg));
      ref.invalidate(checkInHistoryProvider(arg));

      state = state.copyWith(
        phase: status == 'completed'
            ? CheckInPhase.completed
            : CheckInPhase.skipped,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        phase: CheckInPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const CheckInState();
  }
}

final checkInControllerProvider =
    AutoDisposeNotifierProviderFamily<CheckInController, CheckInState, int>(
  CheckInController.new,
);

final checkInHistoryProvider =
    FutureProvider.autoDispose.family<List<CheckIn>, int>((ref, id) async {
  return ref.watch(challengeRepositoryProvider).getCheckIns(id);
});
