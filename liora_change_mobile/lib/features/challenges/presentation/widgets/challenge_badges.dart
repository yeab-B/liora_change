import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/enums.dart';

/// Status pill for a challenge card.
///
/// Nothing here is red: a paused or cancelled challenge is a neutral fact, not
/// an error, per the design system's tone rules.
class ChallengeStatusBadge extends StatelessWidget {
  const ChallengeStatusBadge({super.key, required this.status});

  final ChallengeStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    final (Color background, Color foreground) = switch (status) {
      ChallengeStatus.active => (
        semantic.success.withValues(alpha: 0.14),
        semantic.success,
      ),
      ChallengeStatus.completed => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
      _ => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    // Animated so activation reads as something happening, rather than the
    // label quietly swapping underneath the member.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          _label,
          key: ValueKey<ChallengeStatus>(status),
          style: theme.textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }

  String get _label => switch (status) {
    ChallengeStatus.draft => 'Draft',
    ChallengeStatus.ready => 'Ready',
    ChallengeStatus.active => 'Active',
    ChallengeStatus.paused => 'Paused',
    ChallengeStatus.completed => 'Completed',
    ChallengeStatus.cancelled => 'Cancelled',
    ChallengeStatus.archived => 'Archived',
  };
}

/// Quiet category label shown next to a challenge title.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.name, this.slug});

  final String name;
  final String? slug;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          categoryIcon(slug),
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          name,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The contract's `ChallengeCategory` carries no icon, so the app maps the
/// stable slug to one and falls back to a neutral mark for new categories.
IconData categoryIcon(String? slug) => switch (slug) {
  'health' => Icons.favorite_rounded,
  'fitness' => Icons.directions_run_rounded,
  'focus' => Icons.center_focus_strong_rounded,
  'wellbeing' => Icons.self_improvement_rounded,
  'learning' => Icons.menu_book_rounded,
  'finance' => Icons.savings_rounded,
  _ => Icons.flag_rounded,
};
