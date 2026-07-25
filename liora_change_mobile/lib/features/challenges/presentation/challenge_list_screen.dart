import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/content_bounds.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../models/challenge.dart';
import '../../../models/challenge_category.dart';
import '../../../router/app_router.dart';
import '../application/challenge_list_controller.dart';
import 'widgets/challenge_badges.dart';

/// Everything the member has started, past and present.
class ChallengeListScreen extends ConsumerWidget {
  const ChallengeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Challenge>> challenges = ref.watch(
      challengeListControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        actions: <Widget>[
          IconButton(
            tooltip: 'New challenge',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppRoute.createChallenge.path),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () =>
              ref.read(challengeListControllerProvider.notifier).refresh(),
          child: _Body(challenges: challenges),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.challenges});

  final AsyncValue<List<Challenge>> challenges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Challenge>? data = challenges.value;

    if (data == null && challenges.hasError) {
      return _FullHeight(
        child: ErrorRetryView(
          message: challenges.error is ApiException
              ? (challenges.error! as ApiException).message
              : 'We could not load your challenges. Please try again.',
          onRetry: () => ref.invalidate(challengeListControllerProvider),
        ),
      );
    }

    if (data == null) return const _LoadingList();

    if (data.isEmpty) {
      return _FullHeight(
        child: EmptyState(
          icon: Icons.flag_rounded,
          title: 'No challenges yet',
          message: 'Start one and the streak takes care of itself.',
          actionLabel: 'Start a challenge',
          onAction: () => context.push(AppRoute.createChallenge.path),
        ),
      );
    }

    final Map<int, ChallengeCategory> categories = <int, ChallengeCategory>{
      for (final ChallengeCategory category
          in ref.watch(categoriesProvider).value ?? const <ChallengeCategory>[])
        category.id: category,
    };

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: data.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final Challenge challenge = data[index];
        return ContentBounds(
          child: _ChallengeTile(
            challenge: challenge,
            category: categories[challenge.categoryId],
          ),
        );
      },
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge, this.category});

  final Challenge challenge;
  final ChallengeCategory? category;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool started = challenge.status.isActive;

    return AppCard(
      onTap: () => context.push('/challenges/${challenge.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  challenge.title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChallengeStatusBadge(status: challenge.status),
            ],
          ),
          if (category != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            CategoryChip(name: category!.name, slug: category!.slug),
          ],
          if (started) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ProgressBar(percent: challenge.progressPercent),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${challenge.durationDays} days · '
            '${challenge.completedCheckins} completed',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) =>
          const ContentBounds(child: LoadingSkeleton.card(height: 104)),
    );
  }
}

/// Keeps a centred empty/error view pull-to-refreshable.
class _FullHeight extends StatelessWidget {
  const _FullHeight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: ContentBounds(alignment: Alignment.center, child: child),
          ),
        );
      },
    );
  }
}
