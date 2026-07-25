import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/theme/app_colors.dart';
import 'package:liora_change_mobile/core/theme/app_spacing.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/empty_state.dart';
import 'package:liora_change_mobile/core/widgets/error_retry_view.dart';
import 'package:liora_change_mobile/core/widgets/loading_skeleton.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';
import 'package:liora_change_mobile/core/widgets/progress_bar.dart';
import 'package:liora_change_mobile/core/widgets/recovery_banner.dart';
import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/features/home/data/dashboard_repository.dart';
import 'package:liora_change_mobile/features/home/presentation/home_screen.dart';
import 'package:liora_change_mobile/features/home/presentation/widgets/greeting_header.dart';
import 'package:liora_change_mobile/features/home/presentation/widgets/home_slots.dart';
import 'package:liora_change_mobile/features/motivation/presentation/motivation_card.dart';
import 'package:liora_change_mobile/models/dashboard.dart';

import '../../support/fake_challenge_repository.dart';

class _FakeDashboardRepository implements DashboardRepository {
  _FakeDashboardRepository(this.respond);

  Future<Dashboard> Function() respond;
  int calls = 0;

  @override
  Future<Dashboard> getDashboard() {
    calls++;
    return respond();
  }
}

/// Built from the `GET /dashboard` example in `docs/mvp/05-api-contract.md`
/// §4.1, including its deliberately slim challenge objects.
Dashboard _dashboard({
  bool withChallenge = true,
  bool checkedInToday = false,
  bool recoveryActive = false,
  int currentStreak = 2,
}) {
  return Dashboard.fromJson(<String, dynamic>{
    'user': <String, dynamic>{
      'name': 'Alex Demo',
      'xp_total': 40,
      'level': 1,
      'current_streak': currentStreak,
      'longest_streak': 3,
    },
    'today': <String, dynamic>{
      'date': '2026-07-26',
      'active_challenges_count': withChallenge ? 1 : 0,
      'completed_checkins_count': checkedInToday ? 1 : 0,
      'pending_checkins_count': withChallenge && !checkedInToday ? 1 : 0,
    },
    'active_challenges': <Map<String, dynamic>>[
      if (withChallenge)
        <String, dynamic>{
          'id': 1,
          'title': 'Morning Walk',
          'status': 'active',
          'progress_percent': 28.57,
          'current_streak': currentStreak,
          'checked_in_today': checkedInToday,
        },
    ],
    'recovery': recoveryActive
        ? <String, dynamic>{
            'active': true,
            'challenge_id': 1,
            'title': 'Missed day — restart small',
            'message': 'One missed walk does not erase your progress.',
          }
        : <String, dynamic>{'active': false},
    'motivation_preview': null,
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  _FakeDashboardRepository repository, {
  ThemeData? theme,
  Size? surface,
  FakeChallengeRepository? challenges,
}) async {
  if (surface != null) {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeScreen(),
      ),
      GoRoute(
        path: '/challenges/create',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('create')),
      ),
      GoRoute(
        path: '/challenges/:id',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('detail')),
      ),
      GoRoute(
        path: '/recovery',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('recovery screen')),
      ),
      GoRoute(
        path: '/coach',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('coach screen')),
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('profile screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        dashboardRepositoryProvider.overrideWithValue(repository),
        challengeRepositoryProvider.overrideWithValue(
          challenges ?? FakeChallengeRepository(),
        ),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  test('the greeting follows the time of day', () {
    expect(
      GreetingHeader.greetingFor(DateTime(2026, 7, 26, 7)),
      'Good morning',
    );
    expect(
      GreetingHeader.greetingFor(DateTime(2026, 7, 26, 13)),
      'Good afternoon',
    );
    expect(
      GreetingHeader.greetingFor(DateTime(2026, 7, 26, 21)),
      'Good evening',
    );
  });

  testWidgets('the first load shows skeleton cards, not a bare spinner', (
    WidgetTester tester,
  ) async {
    final Completer<Dashboard> completer = Completer<Dashboard>();
    final _FakeDashboardRepository repository = _FakeDashboardRepository(
      () => completer.future,
    );

    await _pumpHome(tester, repository);
    // The skeleton pulses forever, so settle would never return here.
    await tester.pump();

    expect(find.byType(HomeSkeleton), findsOneWidget);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    completer.complete(_dashboard());
    await tester.pumpAndSettle();

    expect(find.byType(HomeSkeleton), findsNothing);
  });

  testWidgets('an active challenge shows progress and the check-in action', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, _FakeDashboardRepository(() async => _dashboard()));
    await tester.pumpAndSettle();

    final String greeting = GreetingHeader.greetingFor(DateTime.now());
    expect(find.text('$greeting, Alex'), findsOneWidget);
    expect(find.text('Morning Walk'), findsOneWidget);
    expect(find.text('29%'), findsOneWidget);
    expect(find.byType(ProgressBar), findsOneWidget);
    expect(find.text('Check in today'), findsOneWidget);
    expect(find.text('Checked in today'), findsNothing);
  });

  testWidgets('checking in swaps the button for a done state', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      _FakeDashboardRepository(() async => _dashboard(checkedInToday: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Checked in today'), findsOneWidget);
    expect(find.text('Check in today'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.text('Check in today'),
      ),
      findsNothing,
    );
  });

  testWidgets('checking in from Home refreshes it without a manual pull', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    final _FakeDashboardRepository dashboard = _FakeDashboardRepository(
      () async {
        calls++;
        // The second read is the one the check-in triggered.
        return calls == 1
            ? _dashboard(currentStreak: 2)
            : _dashboard(currentStreak: 3, checkedInToday: true);
      },
    );
    final FakeChallengeRepository challenges = FakeChallengeRepository();

    await _pumpHome(tester, dashboard, challenges: challenges);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check in today'));
    await tester.pumpAndSettle();
    expect(find.text('How did today go?'), findsOneWidget);

    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();
    expect(challenges.lastCheckInRequest!['status'], 'completed');

    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();

    expect(dashboard.calls, 2);
    expect(find.text('Checked in today'), findsOneWidget);
    expect(find.text('Check in today'), findsNothing);
  });

  testWidgets('with no active challenge the empty state invites a first one', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      _FakeDashboardRepository(() async => _dashboard(withChallenge: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Start your first challenge'), findsOneWidget);
    expect(find.text('Morning Walk'), findsNothing);

    await tester.tap(find.text('Create a challenge'));
    await tester.pumpAndSettle();

    expect(find.text('create'), findsOneWidget);
  });

  testWidgets('a recovery payload surfaces its banner above the challenge', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      _FakeDashboardRepository(() async => _dashboard(recoveryActive: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RecoveryBanner), findsOneWidget);
    expect(find.text('Missed day — restart small'), findsOneWidget);

    // The comeback is amber, never the error red.
    final Material card = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(RecoveryBanner),
            matching: find.byType(Material),
          )
          .first,
    );
    final AppSemanticColors semantic = AppTheme.light
        .extension<AppSemanticColors>()!;
    expect(card.color, semantic.recovery.withValues(alpha: 0.14));
    expect(card.color, isNot(AppTheme.light.colorScheme.error));
  });

  testWidgets('recovery stays hidden when it is not active', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, _FakeDashboardRepository(() async => _dashboard()));
    await tester.pumpAndSettle();

    expect(find.byType(RecoveryBanner), findsNothing);
  });

  testWidgets('the banner opens the comeback screen', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      _FakeDashboardRepository(() async => _dashboard(recoveryActive: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Come back in'));
    await tester.pumpAndSettle();

    expect(find.text('recovery screen'), findsOneWidget);
  });

  testWidgets('the header opens the coach and the profile', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, _FakeDashboardRepository(() async => _dashboard()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    expect(find.text('profile screen'), findsOneWidget);
  });

  testWidgets('a failure shows the retry view and retrying refetches', (
    WidgetTester tester,
  ) async {
    bool shouldFail = true;
    final _FakeDashboardRepository repository = _FakeDashboardRepository(
      () async {
        if (shouldFail) {
          throw const ApiException(message: 'Cannot reach the server.');
        }
        return _dashboard();
      },
    );

    await _pumpHome(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorRetryView), findsOneWidget);
    expect(find.text('Cannot reach the server.'), findsOneWidget);
    expect(repository.calls, 1);

    shouldFail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.byType(ErrorRetryView), findsNothing);
    expect(find.text('Morning Walk'), findsOneWidget);
  });

  group('responsiveness', () {
    // Smallest phone the design system targets, a tall modern phone, and a
    // tablet — an overflow anywhere surfaces as a caught exception.
    const Map<String, Size> surfaces = <String, Size>{
      'small phone': Size(320, 640),
      'large phone': Size(430, 932),
      'tablet': Size(1024, 1366),
    };

    for (final MapEntry<String, Size> surface in surfaces.entries) {
      testWidgets('the dashboard lays out on a ${surface.key}', (
        WidgetTester tester,
      ) async {
        await _pumpHome(
          tester,
          _FakeDashboardRepository(
            () async => _dashboard(recoveryActive: true),
          ),
          surface: surface.value,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Morning Walk'), findsOneWidget);
        expect(find.text('Check in today'), findsOneWidget);
      });

      testWidgets('the empty state lays out on a ${surface.key}', (
        WidgetTester tester,
      ) async {
        await _pumpHome(
          tester,
          _FakeDashboardRepository(
            () async => _dashboard(withChallenge: false),
          ),
          surface: surface.value,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(EmptyState), findsOneWidget);
      });
    }

    testWidgets('content is capped and centred on a tablet', (
      WidgetTester tester,
    ) async {
      await _pumpHome(
        tester,
        _FakeDashboardRepository(() async => _dashboard()),
        surface: const Size(1024, 1366),
      );
      await tester.pumpAndSettle();

      final Rect card = tester.getRect(find.byType(MotivationCard));
      expect(card.width, AppLayout.maxContentWidth);
      expect(card.center.dx, closeTo(1024 / 2, 0.5));
    });

    testWidgets('the dashboard starts at the top, not centred vertically', (
      WidgetTester tester,
    ) async {
      await _pumpHome(
        tester,
        _FakeDashboardRepository(() async => _dashboard(withChallenge: false)),
        surface: const Size(430, 932),
      );
      await tester.pumpAndSettle();

      final double greetingTop = tester
          .getRect(find.byType(GreetingHeader))
          .top;
      expect(greetingTop, lessThan(AppSpacing.xxl));
    });

    testWidgets('dark mode renders every surface without a hard-coded colour', (
      WidgetTester tester,
    ) async {
      await _pumpHome(
        tester,
        _FakeDashboardRepository(() async => _dashboard(recoveryActive: true)),
        theme: AppTheme.dark,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RecoveryBanner), findsOneWidget);
      expect(find.text('Check in today'), findsOneWidget);

      final Material card = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(MotivationCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(card.color, isNot(Colors.white));
    });
  });

  testWidgets('a failed refresh keeps the data already on screen', (
    WidgetTester tester,
  ) async {
    bool shouldFail = false;
    final _FakeDashboardRepository repository = _FakeDashboardRepository(
      () async {
        if (shouldFail) {
          throw const ApiException(message: 'Cannot reach the server.');
        }
        return _dashboard();
      },
    );

    await _pumpHome(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('Morning Walk'), findsOneWidget);

    shouldFail = true;
    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, 350),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Morning Walk'), findsOneWidget);
    expect(find.byType(ErrorRetryView), findsNothing);
  });
}
