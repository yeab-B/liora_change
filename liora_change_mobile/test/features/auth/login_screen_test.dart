import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';
import 'package:liora_change_mobile/features/auth/presentation/login_screen.dart';
import 'package:liora_change_mobile/features/home/presentation/home_screen.dart';

import '../../support/fake_api.dart';

Future<void> _fillCredentials(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'selam@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
}

void main() {
  testWidgets('an unauthenticated cold start lands on the login screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('submitting an empty form shows validation errors', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi();
    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(
      api.callsTo('POST', '/auth/login'),
      0,
      reason: 'An invalid form must not reach the network',
    );
  });

  testWidgets('an invalid email is rejected before submitting', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('the field validates as soon as it loses focus', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'nope');
    expect(find.text('Enter a valid email address'), findsNothing);

    // Moving to the password field blurs the email field.
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('the button shows a spinner and blocks a second submit', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub(
        'POST',
        '/auth/login',
        FakeResponse(
          200,
          authSessionBody(),
          delay: const Duration(milliseconds: 300),
        ),
      )
      ..stub('GET', '/me', FakeResponse(200, <String, dynamic>{}));

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await _fillCredentials(tester);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(api.callsTo('POST', '/auth/login'), 1);
  });

  testWidgets('a successful login navigates to home', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub('POST', '/auth/login', FakeResponse(200, authSessionBody()));

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await _fillCredentials(tester);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a rejected login shows the API message and stays put', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub(
        'POST',
        '/auth/login',
        FakeResponse(
          422,
          errorBody(
            'These credentials do not match our records.',
            code: 'VALIDATION_ERROR',
            errors: <String, List<String>>{
              'email': <String>['These credentials do not match our records.'],
            },
          ),
        ),
      );

    await pumpApp(tester, api);
    await tester.pumpAndSettle();

    await _fillCredentials(tester);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('These credentials do not match our records.'),
      findsWidgets,
      reason: 'The banner and the email field both surface the message',
    );
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('the password can be revealed', (WidgetTester tester) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('login links across to register', (WidgetTester tester) async {
    await pumpApp(tester, FakeApi());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Start your streak'), findsOneWidget);
  });
}
