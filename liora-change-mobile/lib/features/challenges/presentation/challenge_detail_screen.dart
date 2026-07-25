import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/ui_widgets.dart';
import '../../../models/check_in_models.dart';
import '../../checkins/presentation/check_in_sheet.dart';
import '../application/challenge_detail_controller.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChallenge = ref.watch(challengeDetailControllerProvider(challengeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: asyncChallenge.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: LoadingSkeleton(height: 200),
        ),
        error: (e, _) => ErrorRetryView(
          message: 'Could not load challenge',
          onRetry: () =>
              ref.read(challengeDetailControllerProvider(challengeId).notifier).refresh(),
        ),
        data: (challenge) => _DetailBody(challenge: challenge),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canActivate = challenge.status == ChallengeStatus.draft ||
        challenge.status == ChallengeStatus.ready;
    final isActive = challenge.status == ChallengeStatus.active;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(challenge.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(challenge.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreakBadge(streak: challenge.currentStreak),
                const SizedBox(height: AppSpacing.lg),
                ProgressBar(progress: challenge.progressPercent),
                const SizedBox(height: AppSpacing.sm),
                Text('${challenge.progressPercent.toStringAsFixed(0)}% complete'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (canActivate)
            PrimaryButton(
              label: 'Activate challenge',
              onPressed: () async {
                await ref
                    .read(challengeDetailControllerProvider(challenge.id).notifier)
                    .activate();
                if (context.mounted) {
                  AppSnackbar.showSuccess(context, 'Challenge activated!');
                }
              },
            )
          else if (isActive && !challenge.checkedInToday)
            PrimaryButton(
              label: 'Check in today',
              onPressed: () => showCheckInSheet(
                context,
                challengeId: challenge.id,
                challengeTitle: challenge.title,
              ),
            )
          else if (isActive && challenge.checkedInToday)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).extension<AppSemanticColors>()!.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('Checked in today'),
              ],
            ),
        ],
      ),
    );
  }
}

class RecoveryPlaceholderScreen extends StatelessWidget {
  const RecoveryPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recovery =
        Theme.of(context).extension<AppSemanticColors>()!.recovery;
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.spa, size: 64, color: recovery),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Recovery flow',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'TODO: Issue #7 implements the full recovery screen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Back to Home',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
