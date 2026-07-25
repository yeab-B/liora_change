import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Consistent toast styling drawn from the theme, never raw `Colors.*`.
abstract final class AppSnackbar {
  static void showSuccess(BuildContext context, String message) {
    final AppSemanticColors semantic = context.semanticColors;
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      background: semantic.success,
      foreground: semantic.onSuccess,
    );
  }

  /// Reserved for genuine failures — never for a skipped or missed check-in.
  static void showError(BuildContext context, String message) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      background: colors.error,
      foreground: colors.onError,
    );
  }

  static void showInfo(BuildContext context, String message) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      background: colors.surfaceContainerHighest,
      foreground: colors.onSurface,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    final TextTheme text = Theme.of(context).textTheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Row(
            children: <Widget>[
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: text.bodyLarge?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
