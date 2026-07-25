import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Flame icon plus the current streak count, in the semantic `success` colour.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak, this.compact = false});

  /// `current_streak` from the API.
  final int streak;

  /// Renders a smaller pill for dense rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = context.semanticColors;
    final TextTheme text = Theme.of(context).textTheme;
    final String label = streak == 1 ? '1 day' : '$streak days';

    return Semantics(
      label: 'Current streak: $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: semantic.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.local_fire_department_rounded,
              size: compact ? 18 : 24,
              color: semantic.success,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: (compact ? text.labelSmall : text.titleMedium)?.copyWith(
                color: semantic.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
