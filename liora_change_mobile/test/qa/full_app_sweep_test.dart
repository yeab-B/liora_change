import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/router/app_router.dart';

import '../support/fake_api.dart';

/// The whole app, populated: an active challenge mid-streak, a live comeback,
/// one earned badge. Enough content on every screen for a layout to fail.
FakeApi populatedApi() {
  return FakeApi()
    ..stub(
      'GET',
      '/me',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'id': 1,
          'name': 'Alexandria Demonstration',
          'email': 'alexandria.demonstration@example.com',
          'timezone': 'Africa/Addis_Ababa',
          'xp_total': 120,
          'level': 2,
          'current_streak': 4,
          'longest_streak': 6,
        },
      }),
    )
    ..stub(
      'GET',
      '/dashboard',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'user': <String, dynamic>{
            'name': 'Alexandria Demonstration',
            'xp_total': 120,
            'level': 2,
            'current_streak': 4,
            'longest_streak': 6,
          },
          'today': <String, dynamic>{
            'date': '2026-07-26',
            'active_challenges_count': 1,
            'completed_checkins_count': 0,
            'pending_checkins_count': 1,
          },
          'active_challenges': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'title': 'Walk before breakfast every single morning',
              'status': 'active',
              'progress_percent': 42.86,
              'current_streak': 4,
              'checked_in_today': false,
            },
          ],
          'recovery': <String, dynamic>{
            'active': true,
            'challenge_id': 1,
            'title': 'Yesterday got away from you',
            'message': 'Pick the smallest version of the walk and start there.',
          },
          'motivation_preview': 'Four days in. Today is just the next one.',
        },
      }),
    )
    ..stub(
      'GET',
      '/challenges',
      FakeResponse(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'title': 'Walk before breakfast every single morning',
            'status': 'active',
            'difficulty': 'medium',
            'duration_days': 7,
            'progress_percent': 42.86,
            'current_streak': 4,
            'checked_in_today': false,
          },
        ],
      }),
    )
    ..stub(
      'GET',
      '/challenge-categories',
      FakeResponse(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'Movement', 'slug': 'movement'},
        ],
      }),
    )
    ..stub(
      'GET',
      '/challenge-templates',
      FakeResponse(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'title': 'Walk before breakfast every single morning',
            'description': 'A gentle start that does not need a gym.',
            'difficulty': 'easy',
            'duration_days': 7,
            'category_id': 1,
          },
        ],
      }),
    )
    ..stub(
      'GET',
      '/challenges/1',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'id': 1,
          'title': 'Walk before breakfast every single morning',
          'status': 'active',
          'difficulty': 'medium',
          'duration_days': 7,
          'progress_percent': 42.86,
          'current_streak': 4,
          'longest_streak': 6,
          'missed_checkins': 1,
          'checked_in_today': false,
        },
      }),
    )
    ..stub(
      'GET',
      '/challenges/1/check-ins',
      FakeResponse(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'challenge_id': 1,
            'status': 'completed',
            'check_in_date': '2026-07-24',
          },
          <String, dynamic>{
            'id': 2,
            'challenge_id': 1,
            'status': 'skipped',
            'check_in_date': '2026-07-25',
          },
        ],
      }),
    )
    ..stub(
      'GET',
      '/recovery/current',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'active': true,
          'challenge_id': 1,
          'challenge_title': 'Walk before breakfast every single morning',
          'reason': 'skipped',
          'title': 'Yesterday got away from you',
          'message': 'Pick the smallest version of the walk and start there.',
          'suggested_action': <String, dynamic>{
            'type': 'check_in',
            'challenge_id': 1,
            'label': 'Check in now',
          },
        },
      }),
    )
    ..stub(
      'GET',
      '/progress',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'xp_total': 120,
          'level': 2,
          'current_streak': 4,
          'longest_streak': 6,
          'success_rate': 80,
          'completed_checkins': 8,
          'skipped_checkins': 2,
          'active_challenges': 1,
          'completed_challenges': 1,
        },
      }),
    )
    ..stub(
      'GET',
      '/badges/unlocked',
      FakeResponse(200, <String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'code': 'first_checkin',
            'name': 'First step',
            'description': 'Completed your first check-in',
            'unlocked_at': '2026-07-20T08:01:00Z',
          },
        ],
      }),
    );
}

/// Walks every navigable route and reports the first that throws.
Future<void> _visitEveryScreen(WidgetTester tester, GoRouter router) async {
  for (final AppRoute route in AppRoute.values.where(
    (AppRoute r) => r.isNavigable && !r.isPublic,
  )) {
    router.go(route.path);
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: '${route.path} should lay out cleanly',
    );
  }

  router.go('/challenges/1');
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'challenge detail');

  // The list underneath is still fetching; let it land before teardown.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<GoRouter> _boot(WidgetTester tester, {required Size surface}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await pumpApp(tester, populatedApi(), storedToken: 'stored-token');
  await tester.pumpAndSettle();

  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
      .read(routerProvider);
}

/// The QA pass from `docs/mvp/mobile-issues/README.md`, run against the real
/// app rather than a screen at a time: small screens, large text, dark mode.
void main() {
  testWidgets('every screen lays out on the smallest supported phone', (
    WidgetTester tester,
  ) async {
    await _visitEveryScreen(
      tester,
      await _boot(tester, surface: const Size(320, 640)),
    );
  });

  testWidgets('every screen survives 130% OS text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _visitEveryScreen(
      tester,
      await _boot(tester, surface: const Size(360, 800)),
    );
  });

  testWidgets('every screen renders in dark mode', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final GoRouter router = await _boot(tester, surface: const Size(390, 844));

    final ThemeData theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.dark);

    await _visitEveryScreen(tester, router);
  });

  testWidgets('every screen lays out on a tablet', (WidgetTester tester) async {
    await _visitEveryScreen(
      tester,
      await _boot(tester, surface: const Size(1024, 1366)),
    );
  });

  testWidgets('every screen survives a rotation to landscape', (
    WidgetTester tester,
  ) async {
    await _visitEveryScreen(
      tester,
      await _boot(tester, surface: const Size(844, 390)),
    );
  });
}
