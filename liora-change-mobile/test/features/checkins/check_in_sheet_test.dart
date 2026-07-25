import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/features/checkins/application/check_in_controller.dart';
import 'package:liora_change_mobile/features/checkins/presentation/check_in_sheet.dart';
import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/models/check_in_models.dart';

class FakeChallengeRepository implements ChallengeRepository {
  FakeChallengeRepository({
    this.onSubmit,
    this.result,
    this.shouldFail = false,
  });

  final Future<CheckInResult> Function(String status, String? note)? onSubmit;
  CheckInResult? result;
  bool shouldFail;

  @override
  Future<Challenge> activateChallenge(int id) async => _sampleChallenge();

  @override
  Future<Challenge> getChallenge(int id) async => _sampleChallenge();

  @override
  Future<List<CheckIn>> getCheckIns(int id) async => [];

  @override
  Future<CheckInResult> submitCheckIn({
    required int challengeId,
    required String status,
    String? note,
  }) async {
    if (onSubmit != null) {
      return onSubmit!(status, note);
    }
    if (shouldFail) {
      throw Exception('Network error');
    }
    return result ?? _sampleResult(status);
  }

  Challenge _sampleChallenge() {
    return Challenge(
      id: 1,
      title: 'Morning Walk',
      status: ChallengeStatus.active,
      difficulty: 'beginner',
      visibility: 'private',
      durationDays: 7,
      progressPercent: 14,
      currentStreak: 1,
      longestStreak: 1,
      completedCheckins: 1,
      missedCheckins: 0,
      checkedInToday: false,
      createdAt: '2026-07-25T10:00:00Z',
      updatedAt: '2026-07-25T10:00:00Z',
    );
  }

  CheckInResult _sampleResult(String status) {
    return CheckInResult(
      checkIn: CheckIn(
        id: 1,
        challengeId: 1,
        checkInDate: '2026-07-26',
        status: CheckInStatus.fromJson(status),
        xpEarned: status == 'completed' ? 10 : 0,
        streakAfter: status == 'completed' ? 2 : 0,
        createdAt: '2026-07-26T10:00:00Z',
      ),
      summary: CheckInSummary(
        currentStreak: status == 'completed' ? 2 : 0,
        longestStreak: 2,
        xpTotal: 50,
        xpEarned: status == 'completed' ? 10 : 0,
        challengeProgressPercent: 28.57,
        recoveryAvailable: status == 'skipped',
      ),
    );
  }
}

void main() {
  group('CheckInController', () {
    test('submit completed calls repository with correct status', () async {
      String? capturedStatus;
      late FakeChallengeRepository fake;
      fake = FakeChallengeRepository(
        onSubmit: (status, note) async {
          capturedStatus = status;
          return CheckInResult(
            checkIn: CheckIn(
              id: 1,
              challengeId: 1,
              checkInDate: '2026-07-26',
              status: CheckInStatus.completed,
              xpEarned: 10,
              streakAfter: 2,
              createdAt: '2026-07-26T10:00:00Z',
            ),
            summary: const CheckInSummary(
              currentStreak: 2,
              longestStreak: 2,
              xpTotal: 50,
              xpEarned: 10,
              challengeProgressPercent: 28.57,
              recoveryAvailable: false,
            ),
          );
        },
      );

      final container = ProviderContainer(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(checkInControllerProvider(1).notifier);
      await notifier.submit(status: 'completed');
      expect(capturedStatus, 'completed');
      expect(
        container.read(checkInControllerProvider(1)).phase,
        CheckInPhase.completed,
      );
    });

    test('submit skipped sets skipped phase', () async {
      final fake = FakeChallengeRepository();
      final container = ProviderContainer(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(checkInControllerProvider(1).notifier)
          .submit(status: 'skipped');
      expect(
        container.read(checkInControllerProvider(1)).phase,
        CheckInPhase.skipped,
      );
    });

    test('error sets error phase', () async {
      final fake = FakeChallengeRepository(shouldFail: true);
      final container = ProviderContainer(
        overrides: [
          challengeRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(checkInControllerProvider(1).notifier)
          .submit(status: 'completed');
      expect(
        container.read(checkInControllerProvider(1)).phase,
        CheckInPhase.error,
      );
    });
  });

  group('CheckInSheet widget', () {
    testWidgets('shows I did it and Skip today buttons', (tester) async {
      final fake = FakeChallengeRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            challengeRepositoryProvider.overrideWithValue(fake),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: CheckInSheet(
                challengeId: 1,
                challengeTitle: 'Morning Walk',
              ),
            ),
          ),
        ),
      );

      expect(find.text('I did it!'), findsOneWidget);
      expect(find.text('Skip today'), findsOneWidget);
      expect(find.text('How did today go?'), findsOneWidget);
    });

    testWidgets('completed shows celebration with streak', (tester) async {
      final fake = FakeChallengeRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            challengeRepositoryProvider.overrideWithValue(fake),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: CheckInSheet(
                challengeId: 1,
                challengeTitle: 'Morning Walk',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('I did it!'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Nice!'), findsOneWidget);
      expect(find.textContaining('Streak:'), findsOneWidget);
    });

    testWidgets('skipped shows calm acknowledgment not failed', (tester) async {
      final fake = FakeChallengeRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            challengeRepositoryProvider.overrideWithValue(fake),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: CheckInSheet(
                challengeId: 1,
                challengeTitle: 'Morning Walk',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Skip today'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('fresh start'), findsOneWidget);
      expect(find.textContaining('failed'), findsNothing);
    });
  });
}
