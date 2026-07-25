import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/theme/app_spacing.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/app_card.dart';
import 'package:liora_change_mobile/core/widgets/empty_state.dart';
import 'package:liora_change_mobile/core/widgets/error_retry_view.dart';
import 'package:liora_change_mobile/core/widgets/loading_skeleton.dart';
import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/features/challenges/presentation/challenge_list_screen.dart';
import 'package:liora_change_mobile/features/challenges/presentation/create_challenge_screen.dart';
import 'package:liora_change_mobile/features/challenges/presentation/widgets/challenge_badges.dart';
import 'package:liora_change_mobile/models/challenge.dart';
import 'package:liora_change_mobile/models/enums.dart';

import '../../support/fake_challenge_repository.dart';

Challenge _challenge({
  int id = 1,
  String title = 'Morning Walk',
  ChallengeStatus status = ChallengeStatus.active,
  int? categoryId = 1,
}) {
  return Challenge(
    id: id,
    title: title,
    status: status,
    categoryId: categoryId,
    progressPercent: 40,
    completedCheckins: 2,
  );
}

Future<void> _pumpList(
  WidgetTester tester,
  FakeChallengeRepository repository, {
  Size? surface,
  ThemeData? theme,
}) async {
  if (surface != null) {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final GoRouter router = GoRouter(
    initialLocation: '/challenges',
    routes: <RouteBase>[
      GoRoute(
        path: '/challenges',
        builder: (BuildContext context, GoRouterState state) =>
            const ChallengeListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'create',
            builder: (BuildContext context, GoRouterState state) =>
                const CreateChallengeScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (BuildContext context, GoRouterState state) =>
                Scaffold(body: Text('detail ${state.pathParameters['id']}')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        challengeRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  testWidgets('the list renders a card per challenge with its status', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..challenges = <Challenge>[
        _challenge(),
        _challenge(
          id: 2,
          title: 'No Sugar Week',
          status: ChallengeStatus.completed,
        ),
        _challenge(id: 3, title: 'Reading', status: ChallengeStatus.paused),
      ];

    await _pumpList(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byType(AppCard), findsNWidgets(3));
    expect(find.text('Morning Walk'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.byType(ChallengeStatusBadge), findsNWidgets(3));
    expect(find.text('Health'), findsNWidgets(3));
  });

  testWidgets('tapping a challenge opens its detail', (
    WidgetTester tester,
  ) async {
    await _pumpList(
      tester,
      FakeChallengeRepository()..challenges = <Challenge>[_challenge(id: 7)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Walk'));
    await tester.pumpAndSettle();

    expect(find.text('detail 7'), findsOneWidget);
  });

  testWidgets('an empty list invites the member to start one', (
    WidgetTester tester,
  ) async {
    await _pumpList(tester, FakeChallengeRepository());
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No challenges yet'), findsOneWidget);

    await tester.tap(find.text('Start a challenge'));
    await tester.pumpAndSettle();

    expect(find.text('New challenge'), findsWidgets);
  });

  testWidgets('the "+" action opens the create flow', (
    WidgetTester tester,
  ) async {
    await _pumpList(
      tester,
      FakeChallengeRepository()..challenges = <Challenge>[_challenge()],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 2 · Choose an area'), findsOneWidget);
  });

  testWidgets('the first load shows skeleton cards', (
    WidgetTester tester,
  ) async {
    await _pumpList(
      tester,
      FakeChallengeRepository()
        ..listDelay = const Duration(milliseconds: 200)
        ..challenges = <Challenge>[_challenge()],
    );
    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(LoadingSkeleton), findsNothing);
    expect(find.text('Morning Walk'), findsOneWidget);
  });

  testWidgets('a failure offers a retry that refetches', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..listError = const ApiException(message: 'Cannot reach the server.');

    await _pumpList(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorRetryView), findsOneWidget);
    expect(find.text('Cannot reach the server.'), findsOneWidget);
    expect(repository.listCalls, 1);

    repository
      ..listError = null
      ..challenges = <Challenge>[_challenge()];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
    expect(find.text('Morning Walk'), findsOneWidget);
  });

  group('responsiveness', () {
    const Map<String, Size> surfaces = <String, Size>{
      'small phone': Size(320, 640),
      'large phone': Size(430, 932),
      'tablet': Size(1024, 1366),
    };

    for (final MapEntry<String, Size> surface in surfaces.entries) {
      testWidgets('the list lays out on a ${surface.key}', (
        WidgetTester tester,
      ) async {
        await _pumpList(
          tester,
          FakeChallengeRepository()
            ..challenges = <Challenge>[
              _challenge(),
              _challenge(id: 2, title: 'A rather long challenge title here'),
            ],
          surface: surface.value,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AppCard), findsNWidgets(2));
      });
    }

    testWidgets('cards stay capped and centred on a tablet', (
      WidgetTester tester,
    ) async {
      await _pumpList(
        tester,
        FakeChallengeRepository()..challenges = <Challenge>[_challenge()],
        surface: const Size(1024, 1366),
      );
      await tester.pumpAndSettle();

      final Rect card = tester.getRect(find.byType(AppCard).first);
      expect(card.width, AppLayout.maxContentWidth);
      expect(card.center.dx, closeTo(1024 / 2, 0.5));
    });

    testWidgets('dark mode renders the list without exceptions', (
      WidgetTester tester,
    ) async {
      await _pumpList(
        tester,
        FakeChallengeRepository()..challenges = <Challenge>[_challenge()],
        theme: AppTheme.dark,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
