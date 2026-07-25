import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/content_bounds.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/recovery_banner.dart';
import '../../../models/challenge.dart';
import '../../../models/dashboard.dart';
import '../../../router/app_router.dart';
import '../../checkins/presentation/check_in_sheet.dart';
import '../../motivation/presentation/motivation_card.dart';
import '../application/dashboard_controller.dart';
import 'widgets/active_challenge_card.dart';
import 'widgets/greeting_header.dart';
import 'widgets/home_slots.dart';

/// The daily return screen: where the member stands, and the one thing to do
/// next.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Dashboard> dashboard = ref.watch(
      dashboardControllerProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
          child: _Body(dashboard: dashboard),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.dashboard});

  final AsyncValue<Dashboard> dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A refresh keeps the previous data on screen, so only a genuine first
    // load falls through to the skeletons.
    final Dashboard? data = dashboard.value;

    if (data == null && dashboard.hasError) {
      return _Scrollable(
        fillHeight: true,
        child: ErrorRetryView(
          message: _messageFor(dashboard.error),
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
      );
    }

    if (data == null) {
      return const _Scrollable(child: HomeSkeleton());
    }

    return _Scrollable(child: _Dashboard(dashboard: data));
  }

  static String _messageFor(Object? error) {
    if (error is ApiException) return error.message;
    return 'We could not load your day. Please try again.';
  }
}

/// Always scrollable so pull-to-refresh works even when the content is short,
/// and capped at the design system's reading width so the layout stays a
/// single centred column on tablets instead of stretching edge to edge.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child, this.fillHeight = false});

  final Widget child;

  /// Centres the child in the viewport — right for a full-screen retry view,
  /// wrong for the dashboard, which reads from the top down.
  final bool fillHeight;

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.screenHorizontal,
    vertical: AppSpacing.lg,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: _padding.vertical / 2),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: fillHeight
                  ? constraints.maxHeight - _padding.vertical
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

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final Challenge? challenge = dashboard.primaryChallenge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        GreetingHeader(
          user: dashboard.user,
          onOpenCoach: () => context.push(AppRoute.coach.path),
          onOpenProfile: () => context.push(AppRoute.profile.path),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (dashboard.recovery.active) ...<Widget>[
          RecoveryBanner(
            recovery: dashboard.recovery,
            onOpen: () => context.push(AppRoute.recovery.path),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (challenge != null) ...<Widget>[
          ActiveChallengeCard(
            challenge: challenge,
            onCheckIn: () => _openCheckIn(context, challenge),
            onOpen: () => context.push('/challenges/${challenge.id}'),
          ),
          const SizedBox(height: AppSpacing.md),
          MotivationCard(
            challengeId: challenge.id,
            preview: dashboard.motivationPreview,
          ),
        ] else
          EmptyState(
            icon: Icons.eco_rounded,
            title: 'Start your first challenge',
            message:
                'One small habit, seven days. We will keep the streak and '
                'help you back after a slip.',
            actionLabel: 'Create a challenge',
            onAction: () => context.push(AppRoute.createChallenge.path),
          ),
      ],
    );
  }

  void _openCheckIn(BuildContext context, Challenge challenge) {
    showCheckInSheet(
      context,
      challengeId: challenge.id,
      challengeTitle: challenge.title,
    );
  }
}
