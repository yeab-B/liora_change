import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../models/motivation.dart';
import '../data/motivation_repository.dart';

/// One challenge's motivation message, generated on demand.
///
/// Starts idle (`data(null)`) because this is a tap-to-generate delight, not
/// something to spend an AI call on every time Home paints. The message is
/// kept for the session so navigating away and back does not silently burn
/// another call.
class MotivationController extends AsyncNotifier<Motivation?> {
  MotivationController(this.challengeId);

  final int challengeId;

  @override
  Future<Motivation?> build() async {
    ref.keepAlive();
    return null;
  }

  Future<void> generate() async {
    // One request at a time: the card disables its buttons too, but this
    // makes a double tap harmless whatever the UI does.
    if (state.isLoading) return;

    state = const AsyncValue<Motivation?>.loading();
    state = await AsyncValue.guard<Motivation?>(
      () => ref
          .read(motivationRepositoryProvider)
          .getMotivation(challengeId: challengeId),
    );
  }
}

final AsyncNotifierProviderFamily<MotivationController, Motivation?, int>
motivationControllerProvider =
    AsyncNotifierProvider.family<MotivationController, Motivation?, int>(
      MotivationController.new,
      retry: (int retryCount, Object error) => null,
    );
