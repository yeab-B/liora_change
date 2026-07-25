import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../../models/dashboard.dart';

/// Time-of-day greeting, level/XP line, and the streak — the "how am I doing"
/// glance that opens Home.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.user});

  final DashboardUser user;

  static String greetingFor(DateTime time) {
    if (time.hour < 12) return 'Good morning';
    if (time.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String firstName = user.name.split(' ').first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${greetingFor(DateTime.now())}, $firstName',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Level ${user.level} · ${user.xpTotal} XP',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AnimatedStreakBadge(streak: user.currentStreak),
      ],
    );
  }
}

/// Counts up to the new streak instead of snapping, so returning from a
/// check-in feels like something happened.
class AnimatedStreakBadge extends StatelessWidget {
  const AnimatedStreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: streak),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, int value, _) =>
          StreakBadge(streak: value, compact: true),
    );
  }
}
