import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/api/api_client.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/storage/token_storage.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/error_retry_view.dart';
import 'package:liora_change_mobile/core/widgets/loading_skeleton.dart';
import 'package:liora_change_mobile/core/widgets/secondary_button.dart';
import 'package:liora_change_mobile/features/profile/data/profile_repository.dart';
import 'package:liora_change_mobile/features/profile/presentation/profile_screen.dart';
import 'package:liora_change_mobile/features/profile/presentation/widgets/badge_tile.dart';
import 'package:liora_change_mobile/models/badge_unlocked.dart';
import 'package:liora_change_mobile/models/progress.dart';

import '../../support/fake_api.dart';
import '../../support/fake_profile_repository.dart';

const Progress _progress = Progress(
  xpTotal: 120,
  level: 2,
  currentStreak: 4,
  longestStreak: 6,
  successRate: 80,
  completedCheckins: 8,
  skippedCheckins: 2,
  activeChallenges: 2,
  completedChallenges: 1,
);

Map<String, dynamic> _meBody() => <String, dynamic>{
  'data': <String, dynamic>{
    'id': 1,
    'name': 'Alex Demo',
    'email': 'alex@example.com',
    'timezone': 'Africa/Addis_Ababa',
    'xp_total': 120,
    'level': 2,
    'current_streak': 4,
    'longest_streak': 6,
  },
};

/// Boots the profile behind a router that also owns `/login`, so a logout can
/// be followed all the way to where it lands.
Future<FakeApi> _pumpProfile(
  WidgetTester tester, {
  required FakeProfileRepository profile,
  ThemeData? theme,
  Size? surface,
  double textScale = 1,

  /// False to stop before the request resolves, so the skeleton is visible.
  bool settle = true,
}) async {
  if (surface != null) {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  FlutterSecureStorage.setMockInitialValues(<String, String>{
    TokenStorage.authTokenKey: 'test-token',
  });

  final FakeApi api = FakeApi();
  api.stub('GET', '/me', FakeResponse(200, _meBody()));
  api.stub('POST', '/auth/logout', FakeResponse(200, <String, dynamic>{
    'data': <String, dynamic>{'message': 'Logged out'},
  }));

  final GoRouter router = GoRouter(
    initialLocation: '/profile',
    routes: <RouteBase>[
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('login screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        profileRepositoryProvider.overrideWithValue(profile),
        apiClientProvider.overrideWith((Ref ref) {
          final Dio dio = createApiClient(
            tokenStorage: ref.watch(tokenStorageProvider),
            onUnauthorized: () =>
                ref.read(authExpiredProvider.notifier).markExpired(),
            baseUrl: 'http://localhost/api/v1',
          );
          dio.httpClientAdapter = api;
          return dio;
        }),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig: router,
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );

  if (settle) await tester.pumpAndSettle();
  return api;
}

/// The logout button sits below the badge grid, so it has to be scrolled to
/// on a short test surface.
Future<void> _tapLogout(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(SecondaryButton));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SecondaryButton));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the profile shows who you are and what you have done', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      profile: FakeProfileRepository(
        progress: _progress,
        badges: <BadgeUnlocked>[earnedBadge('first_checkin', name: 'First step')],
      ),
    );

    expect(find.text('Alex Demo'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('Level 2 · 120 XP'), findsOneWidget);

    // Three challenges: two active plus one completed.
    expect(find.text('Challenges'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('every badge is on show, earned ones apart from the rest', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      profile: FakeProfileRepository(
        progress: _progress,
        badges: <BadgeUnlocked>[earnedBadge('first_checkin', name: 'First step')],
      ),
    );

    expect(find.byType(BadgeTile), findsNWidgets(BadgeCatalogue.all.length));
    expect(find.text('1 of ${BadgeCatalogue.all.length}'), findsOneWidget);

    // Locked badges carry a lock, not just a lighter shade.
    expect(
      find.byIcon(Icons.lock_rounded),
      findsNWidgets(BadgeCatalogue.all.length - 1),
    );
    expect(find.byType(Opacity), findsWidgets);

    final Semantics earned = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(BadgeTile),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(earned.properties.label, 'First step, earned');
  });

  testWidgets('a member with no badges is told how to earn one', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      profile: FakeProfileRepository(progress: const Progress()),
    );

    expect(find.text(ProfileScreen.badgesEmptyMessage), findsOneWidget);
    expect(find.text('0 of ${BadgeCatalogue.all.length}'), findsOneWidget);
    expect(
      find.byIcon(Icons.lock_rounded),
      findsNWidgets(BadgeCatalogue.all.length),
    );
  });

  testWidgets('the first load shows skeletons rather than a bare spinner', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      profile: FakeProfileRepository(
        progress: _progress,
        badges: <BadgeUnlocked>[],
      )..delay = const Duration(milliseconds: 200),
      settle: false,
    );
    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(BadgeTile), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(LoadingSkeleton), findsNothing);
    expect(find.byType(BadgeTile), findsWidgets);
  });

  testWidgets('a failed load explains itself and retries', (
    WidgetTester tester,
  ) async {
    final FakeProfileRepository profile = FakeProfileRepository(
      progress: _progress,
    )..progressError = const ApiException(message: 'Progress is unavailable.');

    await _pumpProfile(tester, profile: profile);

    expect(find.byType(ErrorRetryView), findsOneWidget);
    expect(find.text('Progress is unavailable.'), findsOneWidget);

    profile.progressError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(profile.progressCalls, 2);
    expect(find.byType(ErrorRetryView), findsNothing);
    expect(find.text('Level 2 · 120 XP'), findsOneWidget);
  });

  testWidgets('a missing badges endpoint does not take the profile down', (
    WidgetTester tester,
  ) async {
    await _pumpProfile(
      tester,
      profile: FakeProfileRepository(progress: _progress)
        ..badgesError = const ApiException(message: 'Not found'),
    );

    expect(find.byType(ErrorRetryView), findsNothing);
    expect(find.text('Level 2 · 120 XP'), findsOneWidget);
    expect(find.text(ProfileScreen.badgesEmptyMessage), findsOneWidget);
  });

  group('logging out', () {
    testWidgets('asks first, and cancelling changes nothing', (
      WidgetTester tester,
    ) async {
      final FakeApi api = await _pumpProfile(
        tester,
        profile: FakeProfileRepository(progress: _progress),
      );

      await _tapLogout(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(api.callsTo('POST', '/auth/logout'), 0);
      expect(find.text('login screen'), findsNothing);
      expect(find.text('Alex Demo'), findsOneWidget);
    });

    testWidgets('confirming ends the session and lands on login', (
      WidgetTester tester,
    ) async {
      final FakeApi api = await _pumpProfile(
        tester,
        profile: FakeProfileRepository(progress: _progress),
      );

      await _tapLogout(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(api.callsTo('POST', '/auth/logout'), 1);
      expect(find.text('login screen'), findsOneWidget);

      const TokenStorage storage = TokenStorage(FlutterSecureStorage());
      expect(await storage.read(), isNull);
    });
  });

  group('responsiveness', () {
    for (final (String name, Size size) in <(String, Size)>[
      ('a small phone', Size(320, 640)),
      ('a large phone', Size(430, 932)),
      ('a tablet', Size(834, 1112)),
    ]) {
      testWidgets('the profile lays out on $name', (WidgetTester tester) async {
        await _pumpProfile(
          tester,
          profile: FakeProfileRepository(
            progress: _progress,
            badges: <BadgeUnlocked>[earnedBadge('comeback')],
          ),
          surface: size,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(BadgeTile), findsNWidgets(BadgeCatalogue.all.length));
      });
    }

    testWidgets('130% text scale does not break the layout', (
      WidgetTester tester,
    ) async {
      await _pumpProfile(
        tester,
        profile: FakeProfileRepository(progress: _progress),
        surface: const Size(360, 800),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode renders the profile without exceptions', (
      WidgetTester tester,
    ) async {
      await _pumpProfile(
        tester,
        profile: FakeProfileRepository(
          progress: _progress,
          badges: <BadgeUnlocked>[earnedBadge('streak_3')],
        ),
        theme: AppTheme.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Alex Demo'), findsOneWidget);
    });
  });
}
