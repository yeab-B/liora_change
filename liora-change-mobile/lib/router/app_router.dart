import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/challenges/presentation/challenge_detail_screen.dart';
import '../features/challenges/presentation/challenge_list_screen.dart';
import '../features/home/presentation/home_screen.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Register — Issue #2')),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/coach',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Coach — Issue #9')),
          ),
        ),
        GoRoute(
          path: '/challenges',
          builder: (_, __) => const ChallengeListScreen(),
        ),
        GoRoute(
          path: '/challenges/create',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Create challenge — Issue #4')),
          ),
        ),
        GoRoute(
          path: '/challenges/:id',
          builder: (_, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ChallengeDetailScreen(challengeId: id);
          },
        ),
        GoRoute(
          path: '/challenges/:id/checkin',
          builder: (_, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ChallengeDetailScreen(challengeId: id);
          },
        ),
        GoRoute(
          path: '/recovery',
          builder: (_, __) => const RecoveryPlaceholderScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Profile — Issue #10')),
          ),
        ),
      ],
    );
  }
}
