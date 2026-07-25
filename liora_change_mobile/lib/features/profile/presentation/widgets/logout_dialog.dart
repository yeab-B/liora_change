import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Confirms logging out. Returns true only when the member says so.
///
/// Signing out is not a punishment, so the dialog stays in the app's own
/// palette rather than borrowing error styling.
Future<bool> showLogoutDialog(BuildContext context) async {
  final ThemeData theme = Theme.of(context);

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      backgroundColor: theme.colorScheme.surface,
      title: Text('Log out?', style: theme.textTheme.titleLarge),
      content: Text(
        'Are you sure you want to log out? Your streak and progress stay '
        'exactly where they are.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
