import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/recovery.dart';
import '../data/recovery_repository.dart';

/// Holds the current recovery suggestion.
///
/// The screen never waits on this: it paints a warm fallback message while the
/// call is in flight or if it fails, so a slow network can't turn the most
/// supportive moment in the app into a spinner.
class RecoveryController extends AsyncNotifier<Recovery> {
  @override
  Future<Recovery> build() {
    return ref.watch(recoveryRepositoryProvider).getCurrent();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard<Recovery>(
      () => ref.read(recoveryRepositoryProvider).getCurrent(),
    );
  }
}

final AsyncNotifierProvider<RecoveryController, Recovery>
recoveryControllerProvider =
    AsyncNotifierProvider<RecoveryController, Recovery>(
      RecoveryController.new,
      retry: (int retryCount, Object error) => null,
    );
