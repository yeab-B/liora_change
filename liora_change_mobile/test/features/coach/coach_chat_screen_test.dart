import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/api/api_exception.dart';
import 'package:liora_change_mobile/core/services/addis_voice_service.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/chat_bubble.dart';
import 'package:liora_change_mobile/features/coach/data/chat_repository.dart';
import 'package:liora_change_mobile/features/coach/presentation/coach_chat_screen.dart';
import 'package:liora_change_mobile/models/chat_source.dart';

import '../../support/fake_chat_repository.dart';

/// Keeps widget tests offline — demo TTS must not call Addis AI.
class _SilentVoice extends AddisVoiceController {
  @override
  AddisVoiceStatus build() =>
      const AddisVoiceStatus(state: AddisVoiceState.idle);

  @override
  Future<void> play(String text) async {}
}

Future<void> _pumpCoach(
  WidgetTester tester,
  FakeChatRepository repository, {
  ThemeData? theme,
  Size? surface,
}) async {
  if (surface != null) {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        chatRepositoryProvider.overrideWithValue(repository),
        addisVoiceProvider.overrideWith(_SilentVoice.new),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        home: const CoachChatScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the empty state greets and offers a way in', (
    WidgetTester tester,
  ) async {
    final FakeChatRepository repository = FakeChatRepository();
    await _pumpCoach(tester, repository);

    expect(find.text(CoachChatScreen.greeting), findsOneWidget);
    for (final String starter in CoachChatScreen.starters) {
      expect(find.text(starter), findsOneWidget);
    }
    expect(find.byType(ChatBubble), findsNothing);
    expect(repository.calls, 0);
  });

  testWidgets('tapping a starter asks it as a question', (
    WidgetTester tester,
  ) async {
    final FakeChatRepository repository = FakeChatRepository();
    await _pumpCoach(tester, repository);

    await tester.tap(find.text(CoachChatScreen.starters.first));
    await tester.pumpAndSettle();

    expect(repository.requests.single['message'], CoachChatScreen.starters[0]);
    expect(find.byType(ChatBubble), findsNWidgets(2));
    expect(find.text(CoachChatScreen.greeting), findsNothing);
  });

  testWidgets('a sent question appears at once, with the coach writing', (
    WidgetTester tester,
  ) async {
    final FakeChatRepository repository = FakeChatRepository()
      ..delay = const Duration(milliseconds: 400);
    await _pumpCoach(tester, repository);

    await tester.enterText(find.byType(TextField), 'How do I start?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // The question is on screen before the network has answered.
    expect(find.text('How do I start?'), findsOneWidget);
    expect(find.byType(TypingIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(TypingIndicator), findsNothing);
  });

  testWidgets('the answer renders with the articles it leaned on', (
    WidgetTester tester,
  ) async {
    final FakeChatRepository repository = FakeChatRepository(
      answers: <String>['Do the smallest version today.'],
      sources: const <ChatSource>[
        ChatSource(
          title: 'Recovery basics',
          snippet: 'After a miss, restart with a tiny action.',
        ),
      ],
    );
    await _pumpCoach(tester, repository);

    await tester.tap(find.text(CoachChatScreen.starters[1]));
    await tester.pumpAndSettle();

    expect(find.text('Do the smallest version today.'), findsOneWidget);
    expect(find.text('Based on: Recovery basics'), findsOneWidget);

    await tester.tap(find.text('Based on: Recovery basics'));
    await tester.pumpAndSettle();

    expect(
      find.text('After a miss, restart with a tiny action.'),
      findsOneWidget,
    );
  });

  testWidgets('the second question carries the session the API opened', (
    WidgetTester tester,
  ) async {
    final FakeChatRepository repository = FakeChatRepository(
      answers: <String>['First answer.', 'Second answer.'],
    )..sessionId = 42;
    await _pumpCoach(tester, repository);

    await tester.tap(find.text(CoachChatScreen.starters.first));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'And after that?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(repository.requests.first['session_id'], isNull);
    expect(repository.requests.last['session_id'], 42);
    expect(find.text('Second answer.'), findsOneWidget);
  });

  testWidgets('a failed send offers a retry on that message alone', (
    WidgetTester tester,
  ) async {
    // One answer per attempt, including the one that never lands.
    final FakeChatRepository repository = FakeChatRepository(
      answers: <String>[
        'First answer.',
        'Never delivered.',
        'Recovered answer.',
      ],
    );
    await _pumpCoach(tester, repository);

    await tester.tap(find.text(CoachChatScreen.starters.first));
    await tester.pumpAndSettle();
    expect(find.byType(ChatBubble), findsNWidgets(2));

    repository.error = const ApiException(message: 'Cannot reach the server.');
    await tester.enterText(find.byType(TextField), 'Second question');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Not sent'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // The question stays put and the earlier exchange is untouched.
    expect(find.text('Second question'), findsOneWidget);
    expect(find.byType(ChatBubble), findsNWidgets(3));
    expect(find.byType(TypingIndicator), findsNothing);

    repository.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Not sent'), findsNothing);
    expect(find.text('Recovered answer.'), findsOneWidget);
    expect(find.byType(ChatBubble), findsNWidgets(4));
  });

  testWidgets('send is dead until there is something to say', (
    WidgetTester tester,
  ) async {
    final FakeChatRepository repository = FakeChatRepository()
      ..delay = const Duration(milliseconds: 400);
    await _pumpCoach(tester, repository);

    IconButton sendButton() => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send_rounded),
    );

    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Real question');
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    // Locked while the coach is writing, and the field is already clear.
    expect(sendButton().onPressed, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(repository.calls, 1);
  });

  testWidgets('a long answer stays inside the bubble on a small phone', (
    WidgetTester tester,
  ) async {
    await _pumpCoach(
      tester,
      FakeChatRepository(
        answers: <String>[
          'A deliberately long answer that has to wrap several times inside '
              'its bubble without spilling over the edge of the screen or '
              'pushing the avatar out of the way.',
        ],
      ),
      surface: const Size(320, 640),
    );

    await tester.tap(find.text(CoachChatScreen.starters.first));
    await tester.pumpAndSettle();

    final Size bubble = tester.getSize(find.byType(ChatBubble).last);
    expect(bubble.width, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode renders the conversation', (
    WidgetTester tester,
  ) async {
    await _pumpCoach(
      tester,
      FakeChatRepository(answers: <String>['Dark answer.']),
      theme: AppTheme.dark,
    );

    await tester.tap(find.text(CoachChatScreen.starters.first));
    await tester.pumpAndSettle();

    expect(find.text('Dark answer.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
