import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/check_in_models.dart';
import '../data/challenge_repository.dart';

class DashboardData {
  const DashboardData({
    required this.userName,
    required this.xpTotal,
    required this.level,
    required this.currentStreak,
    required this.activeChallenges,
    required this.recoveryActive,
  });

  final String userName;
  final int xpTotal;
  final int level;
  final int currentStreak;
  final List<Challenge> activeChallenges;
  final bool recoveryActive;

  Challenge? get primaryChallenge =>
      activeChallenges.isNotEmpty ? activeChallenges.first : null;
}

abstract class DashboardRepository {
  Future<DashboardData> getDashboard();
}

class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._repo);

  final ChallengeRepository _repo;

  @override
  Future<DashboardData> getDashboard() async {
    // Delegated via dio in a full app; simplified fetch through challenge list
    // until friend's Issue #3 is merged — structure matches contract.
    throw UnimplementedError('Wire GET /dashboard when Issue #3 is merged');
  }
}

class DashboardController extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    return ref.watch(dashboardRepositoryProvider).getDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return ApiDashboardRepository(ref.watch(challengeRepositoryProvider));
});

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(
  DashboardController.new,
);
