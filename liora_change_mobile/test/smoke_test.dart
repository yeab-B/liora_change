import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/theme/app_colors.dart';
import 'package:liora_change_mobile/features/auth/presentation/login_screen.dart';
import 'package:liora_change_mobile/features/challenges/presentation/challenge_detail_screen.dart';
import 'package:liora_change_mobile/features/home/presentation/home_screen.dart';
import 'package:liora_change_mobile/router/app_router.dart';

import 'support/fake_api.dart';

/// The placeholder screen also lists route names as navigation chips, so
/// titles are matched inside the app bar to stay unambiguous.
Finder _appBarTitle(String title) {
  return find.descendant(of: find.byType(AppBar), matching: find.text(title));
}

/// Boots straight into an authenticated session so route coverage is not
/// blocked by the auth guard.
Future<GoRouter> _pumpSignedIn(WidgetTester tester) async {
  final FakeApi api = FakeApi()
    ..stub(
      'GET',
      '/me',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'id': 1,
          'name': 'Selam',
          'email': 'selam@example.com',
          'timezone': 'Africa/Addis_Ababa',
          'xp_total': 0,
          'level': 1,
          'current_streak': 0,
          'longest_streak': 0,
        },
      }),
    )
    ..stub(
      'GET',
      '/dashboard',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'user': <String, dynamic>{
            'name': 'Selam',
            'xp_total': 0,
            'level': 1,
            'current_streak': 0,
            'longest_streak': 0,
          },
          'today': <String, dynamic>{
            'date': '2026-07-26',
            'active_challenges_count': 0,
            'completed_checkins_count': 0,
            'pending_checkins_count': 0,
          },
          'active_challenges': <Map<String, dynamic>>[],
          'recovery': <String, dynamic>{'active': false},
          'motivation_preview': null,
        },
      }),
    )
    // The challenge list sits under `/challenges/:id` in the navigator stack,
    // so it loads on any challenge route.
    ..stub(
      'GET',
      '/challenges',
      FakeResponse(200, <String, dynamic>{'data': <Map<String, dynamic>>[]}),
    )
    ..stub(
      'GET',
      '/challenge-categories',
      FakeResponse(200, <String, dynamic>{'data': <Map<String, dynamic>>[]}),
    )
    ..stub(
      'GET',
      '/challenges/1',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{
          'id': 1,
          'title': 'Morning Walk',
          'status': 'draft',
          'duration_days': 7,
        },
      }),
    )
    ..stub(
      'GET',
      '/challenges/1/check-ins',
      FakeResponse(200, <String, dynamic>{'data': <Map<String, dynamic>>[]}),
    )
    ..stub(
      'GET',
      '/recovery/current',
      FakeResponse(200, <String, dynamic>{
        'data': <String, dynamic>{'active': false},
      }),
    );

  await pumpApp(tester, api, storedToken: 'stored-token');
  await tester.pumpAndSettle();

  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
      .read(routerProvider);
}

void main() {
  testWidgets('app boots to login when there is no session', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme exposes the design system semantic colours', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.byType(Scaffold));
    final ThemeData theme = Theme.of(context);

    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppColorTokens.primary);
    expect(theme.extension<AppSemanticColors>(), isNotNull);
    expect(context.semanticColors.recovery, AppColorTokens.recovery);
    expect(context.semanticColors.success, AppColorTokens.success);
  });

  testWidgets('every navigable route resolves without a 404', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpSignedIn(tester);

    for (final AppRoute route in AppRoute.values.where(
      (AppRoute r) => r.isNavigable && !r.isPublic && r != AppRoute.home,
    )) {
      router.go(route.path);
      await tester.pumpAndSettle();

      expect(
        _appBarTitle(route.title),
        findsOneWidget,
        reason: 'Route ${route.path} should render its screen',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('home renders the dashboard rather than a placeholder', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpSignedIn(tester);

    router.go(AppRoute.home.path);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Start your first challenge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parameterised challenge detail route resolves', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpSignedIn(tester);

    router.go('/challenges/1');
    await tester.pumpAndSettle();

    expect(find.byType(ChallengeDetailScreen), findsOneWidget);
    expect(_appBarTitle('Morning Walk'), findsOneWidget);
    expect(find.text('Activate challenge'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The challenge list sits under this page and is still fetching; let it
    // finish so teardown does not trip over an in-flight request.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
