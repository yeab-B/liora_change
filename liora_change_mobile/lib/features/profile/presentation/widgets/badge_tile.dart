import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../models/badge_unlocked.dart';

/// One badge, earned or still ahead of the member.
///
/// Locked badges stay on screen as goals. The distinction is carried by a lock
/// icon and a semantics label as well as opacity, so it survives greyscale and
/// a screen reader.
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.definition, this.unlocked});

  final BadgeDefinition definition;

  /// The API's record of the earned badge; null means still locked.
  final BadgeUnlocked? unlocked;

  static const double lockedOpacity = 0.4;

  static IconData iconFor(String code) {
    return switch (code) {
      'first_checkin' => Icons.hiking_rounded,
      'streak_3' => Icons.local_fire_department_rounded,
      'streak_7' => Icons.calendar_month_rounded,
      'comeback' => Icons.favorite_rounded,
      _ => Icons.workspace_premium_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEarned = unlocked != null;
    final String name = unlocked?.name ?? definition.name;

    final Widget content = AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: isEarned
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  iconFor(definition.code),
                  color: isEarned
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isEarned)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxs / 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            style: theme.textTheme.labelLarge,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Flexible(
            child: Text(
              isEarned
                  ? (unlocked!.description ?? definition.description)
                  : definition.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: isEarned ? '$name, earned' : '$name, locked',
      child: isEarned
          ? content
          : Opacity(opacity: lockedOpacity, child: content),
    );
  }
}
