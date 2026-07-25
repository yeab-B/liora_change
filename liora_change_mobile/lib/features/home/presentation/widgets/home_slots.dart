import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';

/// Reserved space for the AI motivation card.
///
/// TODO(issue-8): replace with the generated card backed by
/// `POST /ai/motivation`. Until then it shows `motivation_preview`, which the
/// dashboard payload already carries.
class MotivationSlot extends StatelessWidget {
  const MotivationSlot({super.key, this.preview});

  final String? preview;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('Motivate me', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preview ?? 'Your daily nudge will appear here.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// First-paint placeholder shaped like the real layout, so nothing jumps when
/// the data lands.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const <Widget>[
        LoadingSkeleton(width: 220, height: 28),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: 140, height: 16),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton.card(height: 180),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton.card(height: 110),
      ],
    );
  }
}
