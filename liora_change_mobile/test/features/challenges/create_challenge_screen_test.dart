import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';
import 'package:liora_change_mobile/features/challenges/data/challenge_repository.dart';
import 'package:liora_change_mobile/features/challenges/presentation/create_challenge_screen.dart';

import '../../support/fake_challenge_repository.dart';

Future<void> _pumpCreate(
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
    initialLocation: '/challenges/create',
    routes: <RouteBase>[
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/challenges',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('list')),
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
  await tester.pumpAndSettle();
}

PrimaryButton _confirmButton(WidgetTester tester) {
  return tester.widget<PrimaryButton>(
    find.widgetWithText(PrimaryButton, 'Create challenge'),
  );
}

void main() {
  testWidgets('step one lists the categories and step two their goals', (
    WidgetTester tester,
  ) async {
    await _pumpCreate(tester, FakeChallengeRepository());

    expect(find.text('Step 1 of 2 · Choose an area'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(
      find.widgetWithText(PrimaryButton, 'Create challenge'),
      findsNothing,
    );

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 2 · Choose a goal'), findsOneWidget);
    expect(find.text('7-Day Morning Walk'), findsOneWidget);
    expect(find.text('No Sugar Week'), findsOneWidget);
    expect(find.text('Something else'), findsOneWidget);
  });

  testWidgets('only the chosen category\'s goals are offered', (
    WidgetTester tester,
  ) async {
    await _pumpCreate(tester, FakeChallengeRepository());

    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();

    expect(find.text('7-Day Morning Walk'), findsNothing);
    expect(find.text('Something else'), findsOneWidget);
  });

  testWidgets('confirm stays disabled until something is chosen', (
    WidgetTester tester,
  ) async {
    await _pumpCreate(tester, FakeChallengeRepository());

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    expect(_confirmButton(tester).onPressed, isNull);

    await tester.tap(find.text('7-Day Morning Walk'));
    await tester.pumpAndSettle();
    expect(_confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('going back keeps the category already picked', (
    WidgetTester tester,
  ) async {
    await _pumpCreate(tester, FakeChallengeRepository());

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back a step'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 2 · Choose an area'), findsOneWidget);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 2 · Choose a goal'), findsOneWidget);
  });

  testWidgets('a template submits the template\'s own fields', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository();
    await _pumpCreate(tester, repository);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No Sugar Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create challenge'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(repository.activateCalls, 1);
    expect(repository.lastCreateRequest, <String, Object?>{
      'title': 'No Sugar Week',
      'description': 'Skip added sugar for seven days.',
      'difficulty': 'medium',
      'visibility': null,
      'duration_days': 7,
      'category_id': 1,
    });
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a custom title submits just the title and category', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository();
    await _pumpCreate(tester, repository);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Something else'));
    await tester.pumpAndSettle();

    expect(_confirmButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Stretch every morning  ');
    await tester.pumpAndSettle();
    expect(_confirmButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Create challenge'));
    await tester.pumpAndSettle();

    expect(repository.lastCreateRequest, <String, Object?>{
      'title': 'Stretch every morning',
      'description': null,
      'difficulty': null,
      'visibility': null,
      'duration_days': null,
      'category_id': 1,
    });
  });

  testWidgets('a rejected create surfaces the API message', (
    WidgetTester tester,
  ) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..createError = const ApiException(
        message: 'The title field is required.',
        statusCode: 422,
        fieldErrors: <String, List<String>>{
          'title': <String>['The title field is required.'],
        },
      );

    await _pumpCreate(tester, repository);

    await tester.tap(find.text('Health'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7-Day Morning Walk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create challenge'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('The title field is required.'), findsOneWidget);
    expect(find.text('Step 2 of 2 · Choose a goal'), findsOneWidget);
  });

  testWidgets('categories failing offers a retry', (WidgetTester tester) async {
    final FakeChallengeRepository repository = FakeChallengeRepository()
      ..categoriesError = const ApiException(
        message: 'Cannot reach the server.',
      );

    await _pumpCreate(tester, repository);

    expect(find.text('Cannot reach the server.'), findsOneWidget);

    repository.categoriesError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Health'), findsOneWidget);
  });

  group('responsiveness', () {
    const Map<String, Size> surfaces = <String, Size>{
      'small phone': Size(320, 640),
      'large phone': Size(430, 932),
      'tablet': Size(1024, 1366),
    };

    for (final MapEntry<String, Size> surface in surfaces.entries) {
      testWidgets('the create flow lays out on a ${surface.key}', (
        WidgetTester tester,
      ) async {
        await _pumpCreate(
          tester,
          FakeChallengeRepository(),
          surface: surface.value,
        );

        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Health'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Something else'), findsOneWidget);
      });
    }

    testWidgets('dark mode renders both steps', (WidgetTester tester) async {
      await _pumpCreate(
        tester,
        FakeChallengeRepository(),
        theme: AppTheme.dark,
      );

      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('7-Day Morning Walk'), findsOneWidget);
    });
  });
}
