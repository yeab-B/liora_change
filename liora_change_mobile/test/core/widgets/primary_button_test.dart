import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liora_change_mobile/core/theme/app_theme.dart';
import 'package:liora_change_mobile/core/widgets/primary_button.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('PrimaryButton', () {
    testWidgets('renders its label and fires onPressed when idle', (
      WidgetTester tester,
    ) async {
      int taps = 0;

      await tester.pumpWidget(
        _host(PrimaryButton(label: 'Log in', onPressed: () => taps++)),
      );

      expect(find.text('Log in'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('swaps the label for a spinner and blocks taps when loading', (
      WidgetTester tester,
    ) async {
      int taps = 0;

      await tester.pumpWidget(
        _host(
          PrimaryButton(
            label: 'Log in',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.text('Log in'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(taps, 0);

      final FilledButton button = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(button.onPressed, isNull);
    });
  });
}
