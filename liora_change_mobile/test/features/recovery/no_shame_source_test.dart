import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A source-level guard for the product's hardest rule: the recovery and
/// check-in flows may never reach for red or for alarm iconography, however
/// tempting it is when someone later adds "just one" error state.
void main() {
  const List<String> files = <String>[
    'lib/core/widgets/recovery_banner.dart',
    'lib/features/recovery/presentation/recovery_screen.dart',
    'lib/features/recovery/application/recovery_controller.dart',
    'lib/features/checkins/presentation/check_in_sheet.dart',
  ];

  const List<String> banned = <String>[
    'Colors.red',
    'colorScheme.error',
    'colors.error',
    'Icons.warning',
    'Icons.error',
    'Icons.dangerous',
    'showError',
  ];

  for (final String path in files) {
    test('$path uses no red and no alarm iconography', () {
      final String source = File(path).readAsStringSync();
      for (final String token in banned) {
        expect(
          source.contains(token),
          isFalse,
          reason: '$path must not use "$token"',
        );
      }
    });
  }
}
