import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/features/auth/presentation/login_screen.dart';
import 'package:liora_change_mobile/features/auth/presentation/splash_screen.dart';
import 'package:liora_change_mobile/features/home/presentation/home_screen.dart';
import 'package:liora_change_mobile/router/app_router.dart';

import '../../support/fake_api.dart';

Map<String, dynamic> _meBody() => <String, dynamic>{
  'data': <String, dynamic>{
    'id': 1,
    'name': 'Selam',
    'email': 'selam@example.com',
    'timezone': 'Africa/Addis_Ababa',
    'xp_total': 120,
    'level': 2,
    'current_streak': 3,
    'longest_streak': 7,
  },
};

void main() {
  testWidgets('a stored token that /me accepts restores the session', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub(
        'GET',
        '/me',
        FakeResponse(200, _meBody(), delay: const Duration(milliseconds: 200)),
      );

    await pumpApp(tester, api, storedToken: 'stored-token');
    await tester.pump();

    expect(
      find.byType(SplashScreen),
      findsOneWidget,
      reason: 'The splash holds while the token is verified',
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      api.requests.first.headers['Authorization'],
      'Bearer stored-token',
      reason: 'The interceptor must attach the stored token',
    );
  });

  testWidgets('a stored token that /me rejects falls back to login', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub(
        'GET',
        '/me',
        FakeResponse(401, errorBody('Unauthenticated.', code: 'UNAUTHORIZED')),
      );

    await pumpApp(tester, api, storedToken: 'expired-token');
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('protected routes bounce back to login while signed out', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    final GoRouter router = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(routerProvider);

    for (final AppRoute route in AppRoute.values.where(
      (AppRoute route) => route.isNavigable && !route.isPublic,
    )) {
      router.go(route.path);
      await tester.pumpAndSettle();

      expect(
        find.byType(LoginScreen),
        findsOneWidget,
        reason: '${route.path} must not be reachable while signed out',
      );
    }
  });

  testWidgets('signed-in users are kept out of the auth screens', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub('GET', '/me', FakeResponse(200, _meBody()));

    await pumpApp(tester, api, storedToken: 'stored-token');
    await tester.pumpAndSettle();

    final GoRouter router = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    ).read(routerProvider);

    for (final AppRoute route in <AppRoute>[
      AppRoute.login,
      AppRoute.register,
    ]) {
      router.go(route.path);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    }
  });
}
