import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'widgets/auth_scaffold.dart';

/// Branded hold while the stored session is verified, so a cold start never
/// flashes a blank white screen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppWordmark(size: AppSpacing.xxl),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Small steps, every day.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
