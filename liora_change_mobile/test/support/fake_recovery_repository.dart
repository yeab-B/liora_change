import 'package:liora_change_mobile/features/recovery/data/recovery_repository.dart';
import 'package:liora_change_mobile/models/enums.dart';
import 'package:liora_change_mobile/models/recovery.dart';

/// In-memory stand-in for `GET /recovery/current`.
class FakeRecoveryRepository implements RecoveryRepository {
  FakeRecoveryRepository({this.recovery = Recovery.inactive});

  Recovery recovery;
  Object? error;
  Duration? delay;
  int calls = 0;

  @override
  Future<Recovery> getCurrent() async {
    calls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;
    return recovery;
  }
}

/// The active suggestion from `docs/mvp/05-api-contract.md` §5.1.
Recovery activeRecovery({
  String title = 'Let us restart gently',
  String message = 'You paused yesterday. Today, do the smallest version.',
}) {
  return Recovery(
    active: true,
    challengeId: 1,
    challengeTitle: 'Morning Walk',
    reason: RecoveryReason.skipped,
    title: title,
    message: message,
    suggestedAction: const SuggestedAction(
      type: SuggestedActionType.checkIn,
      challengeId: 1,
      label: 'Check in now',
    ),
  );
}
