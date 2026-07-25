import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/content_bounds.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../models/challenge.dart';
import '../../../models/challenge_category.dart';
import '../../../models/check_in.dart';
import '../../../models/enums.dart';
import '../../checkins/presentation/check_in_sheet.dart';
import '../application/challenge_detail_controller.dart';
import '../application/challenge_list_controller.dart';
import 'widgets/challenge_badges.dart';
import 'widgets/check_in_history.dart';

/// A challenge's home base: where it stands, and the one thing to do next.
class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Challenge> challenge = ref.watch(
      challengeDetailControllerProvider(challengeId),
    );
    final Challenge? data = challenge.value;

    return Scaffold(
      appBar: AppBar(title: Text(data?.title ?? 'Challenge')),
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            ref.invalidate(challengeDetailControllerProvider(challengeId));
            ref.invalidate(checkInHistoryProvider(challengeId));
          },
          child: _Scrollable(
            fillHeight: data == null,
            child: switch ((data, challenge.hasError)) {
              (final Challenge challenge, _) => _Detail(challenge: challenge),
              (null, true) => ErrorRetryView(
                message: challenge.error is ApiException
                    ? (challenge.error! as ApiException).message
                    : 'We could not load this challenge. Please try again.',
                onRetry: () => ref.invalidate(
                  challengeDetailControllerProvider(challengeId),
                ),
              ),
              (null, false) => const _DetailSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ChallengeCategory? category = ref
        .watch(categoriesProvider)
        .value
        ?.where((ChallengeCategory c) => c.id == challenge.categoryId)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ChallengeStatusBadge(status: challenge.status),
                  if (category != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: CategoryChip(
                        name: category.name,
                        slug: category.slug,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(challenge.title, style: theme.textTheme.titleLarge),
              if (challenge.description != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(challenge.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.md),
              ProgressBar(percent: challenge.progressPercent),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${challenge.progressPercent.round()}% · '
                '${challenge.completedCheckins} of ${challenge.durationDays} days',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Stats(challenge: challenge),
        const SizedBox(height: AppSpacing.md),
        _PrimaryAction(challenge: challenge),
        const SizedBox(height: AppSpacing.lg),
        Text('History', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _History(challengeId: challenge.id),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatTile(
            label: 'Streak',
            value: '${challenge.currentStreak}',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Best',
            value: '${challenge.longestStreak}',
            icon: Icons.emoji_events_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Missed',
            value: '${challenge.missedCheckins}',
            icon: Icons.wb_twilight_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: theme.textTheme.titleLarge),
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

/// Exactly one call to action, decided by the challenge's status.
class _PrimaryAction extends ConsumerStatefulWidget {
  const _PrimaryAction({required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends ConsumerState<_PrimaryAction> {
  bool _activating = false;

  Future<void> _activate() async {
    setState(() => _activating = true);
    final ChallengeDetailController controller = ref.read(
      challengeDetailControllerProvider(widget.challenge.id).notifier,
    );
    final bool activated = await controller.activate();

    if (!mounted) return;
    setState(() => _activating = false);

    if (activated) {
      AppSnackbar.showSuccess(context, 'Day one starts now. Good luck.');
      return;
    }

    final Object? error = controller.lastError;
    AppSnackbar.showError(
      context,
      error is ApiException
          ? error.message
          : 'We could not start this challenge. Please try again.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final Challenge challenge = widget.challenge;

    return switch (challenge.status) {
      ChallengeStatus.draft || ChallengeStatus.ready => PrimaryButton(
        label: 'Activate challenge',
        icon: Icons.play_arrow_rounded,
        isLoading: _activating,
        onPressed: _activate,
      ),
      ChallengeStatus.active when !challenge.checkedInToday => PrimaryButton(
        label: 'Check in today',
        icon: Icons.check_circle_outline_rounded,
        onPressed: () => showCheckInSheet(
          context,
          challengeId: challenge.id,
          challengeTitle: challenge.title,
        ),
      ),
      ChallengeStatus.active => const _DoneToday(),
      ChallengeStatus.completed => const _ClosedNote(
        icon: Icons.emoji_events_rounded,
        message: 'Finished. Every day of this one is behind you.',
      ),
      _ => const _ClosedNote(
        icon: Icons.pause_circle_outline_rounded,
        message: 'This challenge is not running right now.',
      ),
    };
  }
}

class _DoneToday extends StatelessWidget {
  const _DoneToday();

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = context.semanticColors;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: semantic.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.check_circle_rounded, color: semantic.success, size: 22),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Checked in today',
              style: text.bodyLarge?.copyWith(color: semantic.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedNote extends StatelessWidget {
  const _ClosedNote({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.challengeId});

  final int challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CheckIn>> history = ref.watch(
      checkInHistoryProvider(challengeId),
    );

    return history.when(
      loading: () => const LoadingSkeleton(height: 56),
      error: (Object error, StackTrace stack) => ErrorRetryView(
        message: error is ApiException
            ? error.message
            : 'We could not load this history.',
        onRetry: () => ref.invalidate(checkInHistoryProvider(challengeId)),
      ),
      data: (List<CheckIn> checkIns) => checkIns.isEmpty
          ? const EmptyState(
              icon: Icons.wb_sunny_rounded,
              title: 'Your journey starts today',
              message: 'Every day you record shows up here.',
            )
          : AppCard(child: CheckInHistoryStrip(checkIns: checkIns)),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const <Widget>[
        LoadingSkeleton.card(height: 190),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton.card(height: 96),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton.card(height: 56),
      ],
    );
  }
}

class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child, this.fillHeight = false});

  final Widget child;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: fillHeight
                  ? constraints.maxHeight - AppSpacing.md * 2
                  : 0,
            ),
            child: ContentBounds(
              alignment: fillHeight ? Alignment.center : Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
