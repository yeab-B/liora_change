import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/theme/app_colors.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';
import 'package:liora_change_mobile/core/widgets/secondary_button.dart';
import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/features/checkins/presentation/check_in_sheet.dart';
import 'package:liora_change_mobile/models/check_in.dart';
import 'package:liora_change_mobile/models/check_in_result.dart';
import 'package:liora_change_mobile/models/enums.dart';

import '../../support/fake_challenge_repository.dart';

CheckInResult _result({
  CheckInStatus status = CheckInStatus.completed,
  int currentStreak = 3,
  int xpEarned = 10,
}) {
  return CheckInResult(
    checkIn: CheckIn(
      id: 1,
      challengeId: 1,
      checkInDate: '2026-07-26',
      status: status,
    ),
    summary: CheckInSummary(
      currentStreak: currentStreak,
      longestStreak: 3,
      xpTotal: 40,
      xpEarned: xpEarned,
      challengeProgressPercent: 42.86,
      recoveryAvailable: status != CheckInStatus.completed,
    ),
  );
}

/// Opens the sheet the way the app does, from a button on a real route.
Future<void> _openSheet(
  WidgetTester tester,
  FakeChallengeRepository repository, {
  ThemeData? theme,
  Size? surface,
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
              onPressed: () => showCheckInSheet(
                context,
                challengeId: 1,
                challengeTitle: 'Morning Walk',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/recovery',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('recovery screen')),
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
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the sheet asks the question and offers two equal answers', (
    WidgetTester tester,
  ) async {
    await _openSheet(tester, FakeChallengeRepository());

    expect(find.text('Morning Walk'), findsOneWidget);
    expect(find.text('How did today go?'), findsOneWidget);
    expect(find.text('I did it!'), findsOneWidget);
    expect(find.text('Skip today'), findsOneWidget);

    // Neither answer is visually demoted: both occupy the same width.
    final Size did = tester.getSize(find.byType(FilledButton));
    final Size skip = tester.getSize(find.byType(SecondaryButton));
    expect(did.width, closeTo(skip.width, 1));
  });

  testWidgets('"I did it!" submits a completed check-in', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository();
    await _openSheet(tester, repository);

    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();

    expect(repository.checkInCalls, 1);
    expect(repository.lastCheckInRequest, <String, Object?>{
      'challenge_id': 1,
      'status': 'completed',
      'note': null,
    });
  });

  testWidgets('a typed note travels with the check-in', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository();
    await _openSheet(tester, repository);

    await tester.tap(find.text('Add a note (optional)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Rained the whole way  ');
    await tester.pumpAndSettle();

    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();

    expect(repository.lastCheckInRequest!['note'], 'Rained the whole way');
  });

  testWidgets('"Skip today" submits a skipped check-in', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..checkInResult = _result(status: CheckInStatus.skipped);
    await _openSheet(tester, repository);

    await tester.tap(find.text('Skip today'));
    await tester.pumpAndSettle();

    expect(repository.lastCheckInRequest!['status'], 'skipped');
  });

  testWidgets('both answers are disabled while one is in flight', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..checkInDelay = const Duration(milliseconds: 300);
    await _openSheet(tester, repository);

    await tester.tap(find.text('I did it!'));
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<SecondaryButton>(find.byType(SecondaryButton)).onPressed,
      isNull,
    );

    // A second tap while in flight must not send a second request.
    await tester.tap(find.byType(SecondaryButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repository.checkInCalls, 1);
  });

  testWidgets('completing celebrates with the streak and XP from the API', (
    WidgetTester tester,
  ) async {
    await _openSheet(
      tester,
      FakeChallengeRepository()
        ..checkInResult = _result(currentStreak: 4, xpEarned: 15),
    );

    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();

    expect(find.text('That is today done.'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    expect(find.text('XP earned'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'Nice!'), findsOneWidget);

    await tester.tap(find.text('Nice!'));
    await tester.pumpAndSettle();

    expect(find.text('That is today done.'), findsNothing);
  });

  testWidgets('skipping is acknowledged kindly and hands off to recovery', (
    WidgetTester tester,
  ) async {
    await _openSheet(
      tester,
      FakeChallengeRepository()
        ..checkInResult = _result(status: CheckInStatus.skipped),
    );

    await tester.tap(find.text('Skip today'));
    await tester.pumpAndSettle();

    expect(
      find.text('No worries — tomorrow is a fresh start.'),
      findsOneWidget,
    );

    // Nothing in this flow blames the member.
    for (final String word in <String>[
      'failed',
      'Failed',
      'broke',
      'lost',
      'streak lost',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: 'no "$word"');
    }

    await tester.tap(find.text('Help me come back'));
    await tester.pumpAndSettle();

    expect(find.text('recovery screen'), findsOneWidget);
  });

  testWidgets('a failure explains itself inline and lets the member retry', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..checkInError = const ApiException(
        message: 'You already checked in today.',
        statusCode: 422,
      );
    await _openSheet(tester, repository);

    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();

    expect(find.text('You already checked in today.'), findsOneWidget);
    expect(find.text('I did it!'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    repository.checkInError = null;
    await tester.tap(find.text('I did it!'));
    await tester.pumpAndSettle();

    expect(repository.checkInCalls, 2);
    expect(find.text('That is today done.'), findsOneWidget);
  });

  testWidgets('the sheet lays out on the narrowest phone', (
    WidgetTester tester,
  ) async {
    await _openSheet(
      tester,
      FakeChallengeRepository(),
      surface: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('I did it!'), findsOneWidget);
    expect(find.text('Skip today'), findsOneWidget);

    await tester.tap(find.text('Add a note (optional)'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode keeps the success colour, not a raw green', (
    WidgetTester tester,
  ) async {
    await _openSheet(tester, FakeChallengeRepository(), theme: AppTheme.dark);

    final AppSemanticColors semantic = AppTheme.dark
        .extension<AppSemanticColors>()!;
    final FilledButton did = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    final Color? background = did.style?.backgroundColor?.resolve(
      <WidgetState>{},
    );

    expect(background, semantic.success);
    expect(tester.takeException(), isNull);
  });
}
