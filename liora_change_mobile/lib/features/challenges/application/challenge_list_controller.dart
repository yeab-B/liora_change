import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` — the type of a `.family` provider — lives here.
import 'package:flutter_riverpod/misc.dart';

import '../../../models/challenge.dart';
import '../../../models/challenge_category.dart';
import '../../../models/challenge_template.dart';
import '../data/challenge_repository.dart';

/// The member's own challenges, newest activity first.
class ChallengeListController extends AsyncNotifier<List<Challenge>> {
  @override
  Future<List<Challenge>> build() {
    return ref.watch(challengeRepositoryProvider).getMyChallenges();
  }

  Future<void> refresh() async {
    final AsyncValue<List<Challenge>> next =
        await AsyncValue.guard<List<Challenge>>(
          () => ref.read(challengeRepositoryProvider).getMyChallenges(),
        );
    if (next.hasError && state.hasValue) return;
    state = next;
  }
}

final AsyncNotifierProvider<ChallengeListController, List<Challenge>>
challengeListControllerProvider =
    AsyncNotifierProvider<ChallengeListController, List<Challenge>>(
      ChallengeListController.new,
      // The list screen offers an explicit retry; see the dashboard provider.
      retry: (int retryCount, Object error) => null,
    );

final FutureProvider<List<ChallengeCategory>> categoriesProvider =
    FutureProvider<List<ChallengeCategory>>(
      (Ref ref) => ref.watch(challengeRepositoryProvider).getCategories(),
      retry: (int retryCount, Object error) => null,
    );

final FutureProviderFamily<List<ChallengeTemplate>, int> templatesProvider =
    FutureProvider.family<List<ChallengeTemplate>, int>(
      (Ref ref, int categoryId) => ref
          .watch(challengeRepositoryProvider)
          .getTemplates(categoryId: categoryId),
      retry: (int retryCount, Object error) => null,
    );
