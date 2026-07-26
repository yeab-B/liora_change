import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/animated_count.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../../models/challenge.dart';
import '../../../../models/dashboard.dart';

/// Time-of-day greeting, level/XP line, and the streak — the "how am I doing"
/// glance that opens Home.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.user,
    this.activeChallenges = const <Challenge>[],
    this.onOpenCoach,
    this.onOpenProfile,
  });

  final DashboardUser user;

  /// Used so the flame reflects the best live challenge streak, not a stale
  /// user counter that the real API may leave at zero.
  final List<Challenge> activeChallenges;

  /// Home's way into the coach; omitted, the button is not rendered.
  final VoidCallback? onOpenCoach;

  /// Home's way into the profile; omitted, the avatar is not rendered.
  final VoidCallback? onOpenProfile;

  int get _displayStreak {
    if (activeChallenges.isEmpty) return user.currentStreak;
    final int best = activeChallenges.fold<int>(
      0,
      (int maxSoFar, Challenge c) => math.max(maxSoFar, c.currentStreak),
    );
    return math.max(best, user.currentStreak);
  }

  static String greetingFor(DateTime time) {
    if (time.hour < 12) return 'Good morning';
    if (time.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String firstName = user.name.split(' ').first;

    // The streak and the two shortcuts sit on their own line: sharing one row
    // with the greeting left the name wrapping over three lines on a phone.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            AnimatedStreakBadge(streak: _displayStreak),
            const Spacer(),
            if (onOpenCoach != null)
              IconButton(
                onPressed: onOpenCoach,
                tooltip: 'Ask your coach',
                icon: const Icon(Icons.forum_rounded),
              ),
            if (onOpenProfile != null)
              IconButton(
                onPressed: onOpenProfile,
                tooltip: 'Your profile',
                icon: const Icon(Icons.person_rounded),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
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
    return AnimatedCountBuilder(
      value: streak,
      builder: (BuildContext context, int value) =>
          StreakBadge(streak: value, compact: true),
    );
  }
}
