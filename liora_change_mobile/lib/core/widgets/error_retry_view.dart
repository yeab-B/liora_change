import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'primary_button.dart';

/// Network/system failure state with a retry action.
///
/// This is the only place the app uses error styling — a missed check-in is a
/// recovery state, not an error.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.onRetry,
    this.message = 'Something went wrong. Please try again.',
    this.retryLabel = 'Try again',
  });

  final VoidCallback onRetry;
  final String message;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_rounded,
              size: AppSpacing.xl,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: retryLabel,
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}
