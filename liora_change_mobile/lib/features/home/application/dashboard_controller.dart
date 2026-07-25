import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/dashboard.dart';
import '../data/dashboard_repository.dart';

/// Loads the dashboard on build and reloads on demand.
///
/// [refresh] keeps the current data on screen while re-fetching, so
/// pull-to-refresh does not flash the skeletons; the first load is the only
/// time Home has nothing to show.
class DashboardController extends AsyncNotifier<Dashboard> {
  @override
  Future<Dashboard> build() {
    return ref.watch(dashboardRepositoryProvider).getDashboard();
  }

  Future<void> refresh() async {
    final AsyncValue<Dashboard> next = await AsyncValue.guard<Dashboard>(
      () => ref.read(dashboardRepositoryProvider).getDashboard(),
    );
    // A failed refresh should not wipe data the user is already looking at.
    if (next.hasError && state.hasValue) return;
    state = next;
  }
}

final AsyncNotifierProvider<DashboardController, Dashboard>
dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, Dashboard>(
      DashboardController.new,
      // Home shows an explicit "Try again"; Riverpod's background retry would
      // fire a second request behind the user's back and race that button.
      retry: (int retryCount, Object error) => null,
    );
