import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/theme/app_colors.dart';
import 'package:liora_change_mobile/core/theme/app_spacing.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/app_card.dart';
import 'package:liora_change_mobile/core/widgets/empty_state.dart';
import 'package:liora_change_mobile/core/widgets/error_retry_view.dart';
import 'package:liora_change_mobile/core/widgets/loading_skeleton.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';
import 'package:liora_change_mobile/core/widgets/progress_bar.dart';
import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/features/challenges/presentation/challenge_detail_screen.dart';
import 'package:liora_change_mobile/features/challenges/presentation/widgets/challenge_badges.dart';
import 'package:liora_change_mobile/features/challenges/presentation/widgets/check_in_history.dart';
import 'package:liora_change_mobile/models/challenge.dart';
import 'package:liora_change_mobile/models/check_in.dart';
import 'package:liora_change_mobile/models/enums.dart';

import '../../support/fake_challenge_repository.dart';

Challenge _challenge({
  ChallengeStatus status = ChallengeStatus.draft,
  bool checkedInToday = false,
}) {
  return Challenge(
    id: 1,
    title: 'Morning Walk',
    description: 'Walk 10 minutes after waking up.',
    status: status,
    categoryId: 1,
    durationDays: 7,
    progressPercent: 28.57,
    currentStreak: 2,
    longestStreak: 3,
    completedCheckins: 2,
    missedCheckins: 1,
    checkedInToday: checkedInToday,
  );
}

CheckIn _checkIn(int id, CheckInStatus status, String date) {
  return CheckIn(id: id, challengeId: 1, checkInDate: date, status: status);
}

Future<void> _pumpDetail(
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
    initialLocation: '/challenges/1',
    routes: <RouteBase>[
      GoRoute(
        path: '/challenges',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('list')),
        routes: <RouteBase>[
          GoRoute(
            path: ':id',
            builder: (BuildContext context, GoRouterState state) =>
                ChallengeDetailScreen(
                  challengeId: int.parse(state.pathParameters['id']!),
                ),
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
  testWidgets('a draft challenge offers activation, not a check-in', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeChallengeRepository()..challenges = <Challenge>[_challenge()],
    );
    await tester.pumpAndSettle();

    expect(find.text('Morning Walk'), findsWidgets);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.byType(ProgressBar), findsOneWidget);
    expect(
      find.widgetWithText(PrimaryButton, 'Activate challenge'),
      findsOneWidget,
    );
    expect(find.text('Check in today'), findsNothing);
  });

  testWidgets('activating flips the badge and the call to action', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..challenges = <Challenge>[_challenge()];

    await _pumpDetail(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate challenge'));
    await tester.pumpAndSettle();

    expect(repository.activateCalls, 1);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
    expect(find.text('Activate challenge'), findsNothing);
    expect(
      find.widgetWithText(PrimaryButton, 'Check in today'),
      findsOneWidget,
    );
    expect(find.text('Day one starts now. Good luck.'), findsOneWidget);
  });

  testWidgets('a failed activation keeps the draft state and explains why', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..challenges = <Challenge>[_challenge()]
      ..activateError = const ApiException(
        message: 'Only a draft or ready challenge can be activated.',
        statusCode: 422,
      );

    await _pumpDetail(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate challenge'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Only a draft or ready challenge can be activated.'),
      findsOneWidget,
    );
    expect(find.text('Draft'), findsOneWidget);
  });

  testWidgets('an active challenge not yet checked in shows the check-in CTA', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeChallengeRepository()
        ..challenges = <Challenge>[_challenge(status: ChallengeStatus.active)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Active'), findsOneWidget);
    expect(
      find.widgetWithText(PrimaryButton, 'Check in today'),
      findsOneWidget,
    );
    expect(find.text('Checked in today'), findsNothing);
  });

  testWidgets('the check-in CTA opens the sheet and the detail then reloads', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..challenges = <Challenge>[_challenge(status: ChallengeStatus.active)];
    await _pumpDetail(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check in today'));
    await tester.pumpAndSettle();

    expect(find.text('How did today go?'), findsOneWidget);

    // The API now reports the day as logged; the detail must pick that up on
    // its own once the sheet closes.
    repository.challenges = <Challenge>[
      _challenge(status: ChallengeStatus.active, checkedInToday: true),
    ];
    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();

    expect(repository.checkInCalls, 1);
    expect(repository.detailCalls, 2);
    expect(find.text('Checked in today'), findsOneWidget);
  });

  testWidgets('once checked in the CTA becomes a done state', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeChallengeRepository()
        ..challenges = <Challenge>[
          _challenge(status: ChallengeStatus.active, checkedInToday: true),
        ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Checked in today'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);
  });

  testWidgets('a completed challenge offers no call to action', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeChallengeRepository()
        ..challenges = <Challenge>[
          _challenge(status: ChallengeStatus.completed),
        ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);
    expect(
      find.text('Finished. Every day of this one is behind you.'),
      findsOneWidget,
    );
  });

  testWidgets('history distinguishes completed, skipped and missed days', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeChallengeRepository()
        ..challenges = <Challenge>[_challenge(status: ChallengeStatus.active)]
        ..checkIns = <CheckIn>[
          _checkIn(1, CheckInStatus.completed, '2026-07-24'),
          _checkIn(2, CheckInStatus.skipped, '2026-07-25'),
          _checkIn(3, CheckInStatus.missed, '2026-07-26'),
        ],
    );
    await tester.pumpAndSettle();

    final Iterable<CheckInIndicator> indicators = tester
        .widgetList<CheckInIndicator>(find.byType(CheckInIndicator));

    expect(indicators.length, 3);
    expect(
      indicators.map((CheckInIndicator i) => i.status).toList(),
      <CheckInStatus>[
        CheckInStatus.completed,
        CheckInStatus.skipped,
        CheckInStatus.missed,
      ],
    );
    expect(indicators.map((CheckInIndicator i) => i.label).toList(), <String>[
      '24/7',
      '25/7',
      '26/7',
    ]);

    // Completed reads as success, a skipped day as recovery amber — never red.
    final AppSemanticColors semantic = AppTheme.light
        .extension<AppSemanticColors>()!;
    expect(semantic.recovery, isNot(semantic.success));

    final Icon completedIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byWidget(indicators.first),
        matching: find.byType(Icon),
      ),
    );
    expect(completedIcon.color, semantic.success);

    final Icon skippedIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byWidget(indicators.elementAt(1)),
        matching: find.byType(Icon),
      ),
    );
    expect(skippedIcon.color, semantic.recovery);
  });

  testWidgets('an empty history invites the first day', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      FakeChallengeRepository()
        ..challenges = <Challenge>[_challenge(status: ChallengeStatus.active)],
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Your journey starts today'), findsOneWidget);
    expect(find.byType(CheckInIndicator), findsNothing);
  });

  testWidgets('the first load shows skeletons', (WidgetTester tester) async {
    await _pumpDetail(
      tester,
      FakeChallengeRepository()
        ..challenges = <Challenge>[_challenge()]
        ..detailDelay = const Duration(milliseconds: 200),
    );
    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);
  });

  testWidgets('a failure offers a retry that refetches', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..challenges = <Challenge>[_challenge()]
      ..detailError = const ApiException(message: 'Cannot reach the server.');

    await _pumpDetail(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byType(ErrorRetryView), findsOneWidget);
    expect(find.text('Cannot reach the server.'), findsOneWidget);

    repository.detailError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorRetryView), findsNothing);
    expect(find.text('Draft'), findsOneWidget);
  });

  group('responsiveness', () {
    const Map<String, Size> surfaces = <String, Size>{
      'small phone': Size(320, 640),
      'large phone': Size(430, 932),
      'tablet': Size(1024, 1366),
    };

    for (final MapEntry<String, Size> surface in surfaces.entries) {
      testWidgets('the detail lays out on a ${surface.key}', (
        WidgetTester tester,
      ) async {
        await _pumpDetail(
          tester,
          FakeChallengeRepository()
            ..challenges = <Challenge>[
              Challenge(
                id: 1,
                title:
                    'A deliberately long challenge title that has to wrap '
                    'rather than overflow its card',
                description:
                    'And a description long enough to push the layout at the '
                    'narrowest width the design system supports.',
                status: ChallengeStatus.active,
                categoryId: 1,
              ),
            ]
            ..checkIns = <CheckIn>[
              for (int i = 1; i <= 8; i++)
                _checkIn(i, CheckInStatus.completed, '2026-07-0$i'),
            ],
          surface: surface.value,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CheckInIndicator), findsNWidgets(8));
      });
    }

    testWidgets('content stays capped and centred on a tablet', (
      WidgetTester tester,
    ) async {
      await _pumpDetail(
        tester,
        FakeChallengeRepository()..challenges = <Challenge>[_challenge()],
        surface: const Size(1024, 1366),
      );
      await tester.pumpAndSettle();

      final Rect card = tester.getRect(find.byType(AppCard).first);
      expect(card.width, AppLayout.maxContentWidth);
      expect(card.center.dx, closeTo(1024 / 2, 0.5));
    });

    testWidgets('dark mode renders the detail without exceptions', (
      WidgetTester tester,
    ) async {
      await _pumpDetail(
        tester,
        FakeChallengeRepository()
          ..challenges = <Challenge>[_challenge(status: ChallengeStatus.active)]
          ..checkIns = <CheckIn>[
            _checkIn(1, CheckInStatus.completed, '2026-07-24'),
            _checkIn(2, CheckInStatus.skipped, '2026-07-25'),
          ],
        theme: AppTheme.dark,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChallengeStatusBadge), findsOneWidget);
      expect(find.byType(CheckInIndicator), findsNWidgets(2));
    });
  });
}
