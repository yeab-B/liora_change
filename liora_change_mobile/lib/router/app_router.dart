import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/challenges/presentation/challenge_detail_screen.dart';
import '../features/challenges/presentation/challenge_list_screen.dart';
import '../features/challenges/presentation/create_challenge_screen.dart';
import '../features/coach/presentation/coach_chat_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/recovery/presentation/recovery_screen.dart';
import '../models/user.dart';
import 'not_found_screen.dart';

/// Entry point while the stored session is being verified.
const String splashPath = '/';

/// Every screen in the app, from `docs/mvp/teams/MOBILE-TEAM-GUIDE.md` §5.1.
///
/// Routes are registered up front — screens arrive issue by issue — so
/// navigation never hits a 404 mid-development.
enum AppRoute {
  login('/login', 'Login'),
  register('/register', 'Register'),
  home('/home', 'Home'),
  challenges('/challenges', 'Challenges'),
  createChallenge('/challenges/create', 'New challenge'),
  challengeDetail('/challenges/:id', 'Challenge'),
  recovery('/recovery', 'Your comeback'),
  coach('/coach', 'Coach'),
  profile('/profile', 'Profile');

  const AppRoute(this.path, this.title);

  final String path;
  final String title;

  /// False for templated paths such as `/challenges/:id`, which need an id.
  bool get isNavigable => !path.contains(':');

  /// Reachable without a session.
  bool get isPublic => this == AppRoute.login || this == AppRoute.register;
}

/// Sends the user to the splash, the auth screens, or the app.
/// Returning `null` means "stay put".
///
/// [sessionChecked] is false only during the cold-start session restore; a
/// sign-in already in flight counts as checked, so the form stays visible.
String? authGuard({
  required bool sessionChecked,
  required User? user,
  required String location,
}) {
  if (!sessionChecked) {
    return location == splashPath ? null : splashPath;
  }

  final bool isPublic =
      location == AppRoute.login.path || location == AppRoute.register.path;

  if (user == null) {
    return isPublic ? null : AppRoute.login.path;
  }
  return (isPublic || location == splashPath) ? AppRoute.home.path : null;
}

GoRouter createRouter(Ref ref) {
  // GoRouter needs a Listenable; bump a counter whenever auth changes.
  final ValueNotifier<int> authRevision = ValueNotifier<int>(0);
  ref.listen<AsyncValue<User?>>(
    authControllerProvider,
    (AsyncValue<User?>? previous, AsyncValue<User?> next) =>
        authRevision.value++,
  );

  final GoRouter router = GoRouter(
    initialLocation: splashPath,
    refreshListenable: authRevision,
    redirect: (BuildContext context, GoRouterState state) => authGuard(
      sessionChecked: ref.read(authControllerProvider.notifier).sessionChecked,
      user: ref.read(authControllerProvider).value,
      location: state.matchedLocation,
    ),
    routes: <RouteBase>[
      GoRoute(
        path: splashPath,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      _fade(AppRoute.login, const LoginScreen()),
      _fade(AppRoute.register, const RegisterScreen()),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.challenges.path,
        name: AppRoute.challenges.name,
        builder: (BuildContext context, GoRouterState state) =>
            const ChallengeListScreen(),
        routes: <RouteBase>[
          // Declared before `:id` so "create" is not parsed as an id.
          GoRoute(
            path: 'create',
            name: AppRoute.createChallenge.name,
            builder: (BuildContext context, GoRouterState state) =>
                const CreateChallengeScreen(),
          ),
          GoRoute(
            path: ':id',
            name: AppRoute.challengeDetail.name,
            builder: (BuildContext context, GoRouterState state) {
              final int? id = int.tryParse(state.pathParameters['id'] ?? '');
              // Only reachable from a hand-typed deep link, but it still gets
              // a way back rather than an empty screen.
              if (id == null) return const NotFoundScreen();
              return ChallengeDetailScreen(challengeId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.recovery.path,
        name: AppRoute.recovery.name,
        builder: (BuildContext context, GoRouterState state) =>
            const RecoveryScreen(),
      ),
      GoRoute(
        path: AppRoute.coach.path,
        name: AppRoute.coach.name,
        builder: (BuildContext context, GoRouterState state) =>
            const CoachChatScreen(),
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: AppRoute.profile.name,
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authRevision.dispose();
  });
  return router;
}

/// Cross-fade so moving between login and register never cuts hard.
GoRoute _fade(AppRoute route, Widget child) {
  return GoRoute(
    path: route.path,
    name: route.name,
    pageBuilder: (BuildContext context, GoRouterState state) {
      return CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        child: child,
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (Ref ref) => createRouter(ref),
);
