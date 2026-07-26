import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/streak_badge.dart';
import '../../../../models/challenge.dart';

/// The day's main act: what the member signed up for, how far along they are,
/// and the one action that moves it forward.
class ActiveChallengeCard extends StatelessWidget {
  const ActiveChallengeCard({
    super.key,
    required this.challenge,
    required this.onCheckIn,
    required this.onOpen,
  });

  final Challenge challenge;
  final VoidCallback onCheckIn;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(challenge.title, style: theme.textTheme.titleLarge),
              ),
              StreakBadge(streak: challenge.currentStreak, compact: true),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${challenge.progressPercent.round()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressBar(percent: challenge.progressPercent),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${challenge.completedCheckins} of ${challenge.durationDays} days',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (challenge.checkedInToday)
            _DayLogged(skipped: challenge.skippedToday)
          else
            PrimaryButton(
              label: 'Check in today',
              icon: Icons.check_circle_outline_rounded,
              onPressed: onCheckIn,
            ),
        ],
      ),
    );
  }
}

/// Celebratory for a completed day; calm amber when the member skipped.
class _DayLogged extends StatelessWidget {
  const _DayLogged({required this.skipped});

  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = context.semanticColors;
    final TextTheme text = Theme.of(context).textTheme;
    final Color tone = skipped ? semantic.recovery : semantic.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            skipped
                ? Icons.restart_alt_rounded
                : Icons.check_circle_rounded,
            color: tone,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            skipped ? 'Skipped today — come back tomorrow' : 'Checked in today',
            style: text.bodyLarge?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}
