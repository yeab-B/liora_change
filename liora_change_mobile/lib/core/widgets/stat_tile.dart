import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'animated_count.dart';
import 'app_card.dart';

/// One number with its label, sized to sit in a row of equals.
///
/// Shared by the challenge detail and the profile so a streak looks the same
/// wherever it is read.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.animate = true,
    this.suffix = '',
  });

  final String label;
  final int value;
  final IconData icon;

  /// False for numbers that are not an achievement, e.g. a day count.
  final bool animate;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(height: AppSpacing.xs),
          if (animate)
            AnimatedCount(
              value: value,
              suffix: suffix,
              style: theme.textTheme.titleLarge,
            )
          else
            Text('$value$suffix', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
