import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/theme/app_colors.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';
import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/features/recovery/data/recovery_repository.dart';
import 'package:liora_change_mobile/features/recovery/presentation/recovery_screen.dart';
import 'package:liora_change_mobile/models/challenge.dart';
import 'package:liora_change_mobile/models/check_in.dart';
import 'package:liora_change_mobile/models/check_in_result.dart';
import 'package:liora_change_mobile/models/enums.dart';
import 'package:liora_change_mobile/models/recovery.dart';

import '../../support/fake_challenge_repository.dart';
import '../../support/fake_recovery_repository.dart';

/// Words this feature must never say, whatever the state.
const List<String> _forbidden = <String>[
  'failed',
  'Failed',
  'failure',
  'broke',
  'broken',
  'you missed',
  'lost your streak',
];

Future<GoRouter> _pumpRecovery(
  WidgetTester tester, {
  required FakeRecoveryRepository recovery,
  FakeChallengeRepository? challenges,
  ThemeData? theme,
  Size? surface,

  /// False to stop before the suggestion resolves, so the first frame of the
  /// screen can be inspected.
  bool settle = true,
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
        builder: (BuildContext context, GoRouterState state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => context.push('/recovery'),
              child: const Text('open recovery'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/recovery',
        builder: (BuildContext context, GoRouterState state) =>
            const RecoveryScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        recoveryRepositoryProvider.overrideWithValue(recovery),
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
  await tester.pumpAndSettle();
  await tester.tap(find.text('open recovery'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Just enough to finish the push transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }
  return router;
}

void main() {
  testWidgets('a slow suggestion still lands on warm words immediately', (
    WidgetTester tester,
  ) async {
    final FakeRecoveryRepository repository = FakeRecoveryRepository(
      recovery: activeRecovery(),
    )..delay = const Duration(seconds: 2);

    await _pumpRecovery(tester, recovery: repository, settle: false);

    // No spinner, no blank screen: the fallback is on screen from frame one.
    expect(find.text(RecoveryScreen.fallbackTitle), findsOneWidget);
    expect(find.text(RecoveryScreen.fallbackMessage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Let us restart gently'), findsOneWidget);
    expect(find.text(RecoveryScreen.fallbackTitle), findsNothing);
  });

  testWidgets('a failed suggestion keeps the fallback rather than an error', (
    WidgetTester tester,
  ) async {
    final FakeRecoveryRepository repository = FakeRecoveryRepository()
      ..error = const ApiException(message: 'Cannot reach the server.');

    await _pumpRecovery(tester, recovery: repository);

    expect(find.text(RecoveryScreen.fallbackTitle), findsOneWidget);
    expect(find.text('Cannot reach the server.'), findsNothing);
    expect(find.widgetWithText(PrimaryButton, 'Check in now'), findsOneWidget);
  });

  testWidgets('the API message and its suggested action are used when they '
      'arrive', (WidgetTester tester) async {
    await _pumpRecovery(
      tester,
      recovery: FakeRecoveryRepository(recovery: activeRecovery()),
    );

    expect(find.text('Let us restart gently'), findsOneWidget);
    expect(
      find.text('You paused yesterday. Today, do the smallest version.'),
      findsOneWidget,
    );
    expect(find.text('Restart today'), findsOneWidget);
    expect(find.text('Make it smaller'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'Check in now'), findsOneWidget);
  });

  testWidgets('accepting the suggestion checks in and returns home warmly', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository challenges = FakeChallengeRepository()
      ..challenges = <Challenge>[
        const Challenge(id: 1, title: 'Morning Walk', durationDays: 7),
      ];
    final FakeRecoveryRepository recovery = FakeRecoveryRepository(
      recovery: activeRecovery(),
    );

    await _pumpRecovery(tester, recovery: recovery, challenges: challenges);

    await tester.tap(find.text('Check in now'));
    await tester.pumpAndSettle();
    expect(find.text('How did today go?'), findsOneWidget);

    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();

    expect(challenges.lastCheckInRequest, <String, Object?>{
      'challenge_id': 1,
      'status': 'completed',
      'note': null,
    });
    // Back on Home, with a warm confirmation and no comeback screen left.
    expect(find.text('open recovery'), findsOneWidget);
    expect(
      find.text('That is the comeback. Well done for starting again.'),
      findsOneWidget,
    );
  });

  testWidgets('checking in refetches the suggestion so the banner can clear', (
    WidgetTester tester,
  ) async {
    final FakeRecoveryRepository recovery = FakeRecoveryRepository(
      recovery: activeRecovery(),
    );
    final FakeChallengeRepository challenges = FakeChallengeRepository();

    await _pumpRecovery(tester, recovery: recovery, challenges: challenges);
    expect(recovery.calls, 1);

    recovery.recovery = Recovery.inactive;
    await tester.tap(find.text('Check in now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();

    // The check-in invalidated the controller, so the screen behind the sheet
    // already knows recovery is over.
    expect(recovery.calls, 2);
  });

  testWidgets('"Maybe later" leaves without submitting anything', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository challenges = FakeChallengeRepository();
    await _pumpRecovery(
      tester,
      recovery: FakeRecoveryRepository(recovery: activeRecovery()),
      challenges: challenges,
    );

    await tester.ensureVisible(find.text('Maybe later'));
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();

    expect(find.text('open recovery'), findsOneWidget);
    expect(challenges.checkInCalls, 0);
  });

  testWidgets('skipping again from here does not stack another comeback', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository challenges = FakeChallengeRepository()
      ..checkInResult = CheckInResult(
        checkIn: const CheckIn(
          id: 2,
          challengeId: 1,
          checkInDate: '2026-07-26',
          status: CheckInStatus.skipped,
        ),
        summary: const CheckInSummary(recoveryAvailable: true),
      );

    await _pumpRecovery(
      tester,
      recovery: FakeRecoveryRepository(recovery: activeRecovery()),
      challenges: challenges,
    );

    await tester.tap(find.text('Check in now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip today'));
    await tester.pumpAndSettle();

    expect(find.text('Help me come back'), findsNothing);
    await tester.tap(find.text('Okay'));
    await tester.pumpAndSettle();

    // Still on the comeback screen, not a second copy of it.
    expect(find.byType(RecoveryScreen), findsOneWidget);
  });

  testWidgets('with nothing pending it congratulates instead of dead-ending', (
    WidgetTester tester,
  ) async {
    await _pumpRecovery(tester, recovery: FakeRecoveryRepository());

    expect(find.text('Nothing to pick up right now.'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'Back to today'), findsOneWidget);

    await tester.tap(find.text('Back to today'));
    await tester.pumpAndSettle();

    expect(find.text('open recovery'), findsOneWidget);
  });

  testWidgets('nothing in the flow blames the member', (
    WidgetTester tester,
  ) async {
    await _pumpRecovery(
      tester,
      recovery: FakeRecoveryRepository(recovery: activeRecovery()),
    );

    for (final String word in _forbidden) {
      expect(find.textContaining(word), findsNothing, reason: 'no "$word"');
    }
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets(
    'the emphasis colour is the recovery token, never the error red',
    (WidgetTester tester) async {
      await _pumpRecovery(
        tester,
        recovery: FakeRecoveryRepository(recovery: activeRecovery()),
      );

      final AppSemanticColors semantic = AppTheme.light
          .extension<AppSemanticColors>()!;
      final Iterable<Icon> icons = tester
          .widgetList<Icon>(find.byType(Icon))
          .where((Icon icon) => icon.color != null);

      expect(icons, isNotEmpty);
      for (final Icon icon in icons) {
        expect(icon.color, isNot(AppTheme.light.colorScheme.error));
      }
      expect(
        icons.any((Icon icon) => icon.color == semantic.recovery),
        isTrue,
        reason: 'the recovery amber carries the emphasis',
      );
    },
  );

  group('responsiveness', () {
    for (final (String name, Size size) in <(String, Size)>[
      ('a small phone', Size(320, 640)),
      ('a large phone', Size(430, 932)),
      ('a tablet', Size(834, 1112)),
    ]) {
      testWidgets('the comeback screen lays out on $name', (
        WidgetTester tester,
      ) async {
        await _pumpRecovery(
          tester,
          recovery: FakeRecoveryRepository(recovery: activeRecovery()),
          surface: size,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Let us restart gently'), findsOneWidget);
      });
    }

    testWidgets('dark mode renders the comeback screen', (
      WidgetTester tester,
    ) async {
      await _pumpRecovery(
        tester,
        recovery: FakeRecoveryRepository(recovery: activeRecovery()),
        theme: AppTheme.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Let us restart gently'), findsOneWidget);
    });
  });
}
