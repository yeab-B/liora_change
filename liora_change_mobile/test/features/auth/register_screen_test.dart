import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';
import 'package:liora_change_mobile/features/home/presentation/home_screen.dart';

import '../../support/fake_api.dart';

Future<void> _openRegister(WidgetTester tester, FakeApi api) async {
  await pumpApp(tester, api);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create an account'));
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester, {
  String password = 'password123',
  String confirmation = 'password123',
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Selam');
  await tester.enterText(find.byType(TextFormField).at(1), 'selam@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), password);
  await tester.enterText(find.byType(TextFormField).at(3), confirmation);
}

void main() {
  testWidgets('a mismatched confirmation blocks the request', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi();
    await _openRegister(tester, api);

    await _fillForm(tester, confirmation: 'different');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(api.callsTo('POST', '/auth/register'), 0);
  });

  testWidgets('a short password is rejected before submitting', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi();
    await _openRegister(tester, api);

    await _fillForm(tester, password: 'short', confirmation: 'short');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(api.callsTo('POST', '/auth/register'), 0);
  });

  testWidgets('a successful registration lands on home', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub('POST', '/auth/register', FakeResponse(201, authSessionBody()));

    await _openRegister(tester, api);
    await _fillForm(tester);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(api.callsTo('POST', '/auth/register'), 1);
  });

  testWidgets('a taken email is shown under the email field', (
    WidgetTester tester,
  ) async {
    final FakeApi api = FakeApi()
      ..stub(
        'POST',
        '/auth/register',
        FakeResponse(
          422,
          errorBody(
            'The given data was invalid.',
            code: 'VALIDATION_ERROR',
            errors: <String, List<String>>{
              'email': <String>['The email has already been taken.'],
            },
          ),
        ),
      );

    await _openRegister(tester, api);
    await _fillForm(tester);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('The email has already been taken.'), findsOneWidget);
    expect(find.text('The given data was invalid.'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
