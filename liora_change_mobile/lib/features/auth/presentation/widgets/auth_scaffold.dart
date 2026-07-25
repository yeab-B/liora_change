import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Shared branded layout for the login and register screens: wordmark on top,
/// breathable spacing, and a scroll view so the keyboard never covers a field.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Link across to the other auth screen.
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const AppWordmark(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(title, style: theme.textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  child,
                  const SizedBox(height: AppSpacing.lg),
                  footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sprout mark plus the product name.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = AppSpacing.xl});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.spa_rounded, size: size, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Liora Change',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
