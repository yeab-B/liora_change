import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/loading_skeleton.dart';
import 'package:liora_change_mobile/features/motivation/data/motivation_repository.dart';
import 'package:liora_change_mobile/features/motivation/presentation/motivation_card.dart';
import 'package:liora_change_mobile/models/enums.dart';

import '../../support/fake_motivation_repository.dart';

Future<void> _pumpCard(
  WidgetTester tester,
  FakeMotivationRepository repository, {
  String? preview,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        motivationRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: MotivationCard(challengeId: 1, preview: preview)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('idle shows the invitation and asks for nothing yet', (
    WidgetTester tester,
  ) async {
    final FakeMotivationRepository repository = FakeMotivationRepository();
    await _pumpCard(tester, repository);

    expect(find.text(MotivationCard.idleLabel), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Motivate me'), findsOneWidget);
    expect(repository.calls, 0);
    // The regenerate control is not offered before there is a message.
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });

  testWidgets("the dashboard's preview line fills the resting state", (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      FakeMotivationRepository(),
      preview: 'Small and repeatable beats big and rare.',
    );

    expect(
      find.text('Small and repeatable beats big and rare.'),
      findsOneWidget,
    );
    expect(find.text(MotivationCard.idleLabel), findsNothing);
  });

  testWidgets('tapping shimmers inside the card and locks the button', (
    WidgetTester tester,
  ) async {
    final FakeMotivationRepository repository = FakeMotivationRepository()
      ..delay = const Duration(milliseconds: 300);
    await _pumpCard(tester, repository);

    await tester.tap(find.text('Motivate me'));
    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    // A second tap during the request must not queue another call.
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.requests.single['challenge_id'], 1);
  });

  testWidgets('a generated message renders with the sparkle and a refresh', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      FakeMotivationRepository(
        messages: <String>['Alex, five minutes is enough today.'],
      ),
    );

    await tester.tap(find.text('Motivate me'));
    await tester.pumpAndSettle();

    expect(find.text('Alex, five minutes is enough today.'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    // The filled affordance steps aside for the low-emphasis refresh.
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('an OpenAI message and a template message look the same', (
    WidgetTester tester,
  ) async {
    Future<(TextStyle?, List<IconData?>)> render(
      MotivationSource source,
    ) async {
      final FakeMotivationRepository repository = FakeMotivationRepository(
        messages: <String>['Same shape either way.'],
      )..source = source;
      await _pumpCard(tester, repository);
      await tester.tap(find.text('Motivate me'));
      await tester.pumpAndSettle();

      expect(find.text('Same shape either way.'), findsOneWidget);
      return (
        tester.widget<Text>(find.text('Same shape either way.')).style,
        tester
            .widgetList<Icon>(find.byType(Icon))
            .map((Icon icon) => icon.icon)
            .toList(),
      );
    }

    final (TextStyle?, List<IconData?>) fromAi = await render(
      MotivationSource.openai,
    );
    // Tear the tree down so the second render starts from a fresh, idle card.
    await tester.pumpWidget(const SizedBox.shrink());
    final (TextStyle?, List<IconData?>) fromTemplate = await render(
      MotivationSource.template,
    );

    expect(fromTemplate.$1, fromAi.$1);
    expect(fromTemplate.$2, fromAi.$2);
    // Nothing on screen names where the words came from.
    expect(find.textContaining('template'), findsNothing);
    expect(find.textContaining('AI'), findsNothing);
  });

  testWidgets('regenerating swaps in the next message', (
    WidgetTester tester,
  ) async {
    final FakeMotivationRepository repository = FakeMotivationRepository(
      messages: <String>['First nudge.', 'Second nudge.'],
    );
    await _pumpCard(tester, repository);

    await tester.tap(find.text('Motivate me'));
    await tester.pumpAndSettle();
    expect(find.text('First nudge.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('Second nudge.'), findsOneWidget);
    expect(find.text('First nudge.'), findsNothing);
  });

  testWidgets('a failure reads as a warm line, not a broken card', (
    WidgetTester tester,
  ) async {
    final FakeMotivationRepository repository = FakeMotivationRepository()
      ..error = const ApiException(message: 'Cannot reach the server.');
    await _pumpCard(tester, repository);

    await tester.tap(find.text('Motivate me'));
    await tester.pumpAndSettle();

    expect(find.text(MotivationCard.fallbackFor(1)), findsOneWidget);
    expect(find.text('Cannot reach the server.'), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

    for (final Icon icon in tester.widgetList<Icon>(find.byType(Icon))) {
      expect(icon.color, isNot(AppTheme.light.colorScheme.error));
    }

    // And the invitation is still there to try again.
    repository.error = null;
    await tester.tap(find.text('Motivate me'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(find.text('Keep walking.'), findsOneWidget);
  });

  testWidgets('dark mode renders the card without exceptions', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, FakeMotivationRepository(), theme: AppTheme.dark);

    await tester.tap(find.text('Motivate me'));
    await tester.pumpAndSettle();

    expect(find.text('Keep walking.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('responsiveness', () {
    for (final (String name, Size size) in <(String, Size)>[
      ('a small phone', Size(320, 640)),
      ('a tablet', Size(834, 1112)),
    ]) {
      testWidgets('the card lays out on $name', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await _pumpCard(
          tester,
          FakeMotivationRepository(
            messages: <String>[
              'A deliberately long nudge that has to wrap on the narrowest '
                  'phone without pushing anything off the edge of the card.',
            ],
          ),
        );

        await tester.tap(find.text('Motivate me'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
