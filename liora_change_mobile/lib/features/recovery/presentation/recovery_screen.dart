import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/content_bounds.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/check_in_result.dart';
import '../../../models/enums.dart';
import '../../../models/recovery.dart';
import '../../../router/app_router.dart';
import '../../checkins/presentation/check_in_sheet.dart';
import '../application/recovery_controller.dart';

/// The comeback screen: what the app says after a day did not happen.
///
/// There is no acknowledge endpoint in the contract — recovery clears when the
/// member checks in — so "accepting" the suggestion means doing the smallest
/// version of the challenge, right here.
class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  /// Shown immediately while the suggestion loads, and kept if it never
  /// arrives. A blank screen would be the worst possible answer to a slip.
  static const String fallbackTitle = 'Life happens. Let us pick this back up.';
  static const String fallbackMessage =
      'A missed day is information, not failure. Pick the smallest version of '
      'your challenge and start there — that still counts.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Recovery> state = ref.watch(recoveryControllerProvider);
    final Recovery? recovery = state.value;

    return Scaffold(
      appBar: AppBar(title: Text(AppRoute.recovery.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: ContentBounds(
            alignment: Alignment.topCenter,
            child: recovery != null && !recovery.active
                ? const _NothingToRecover()
                : _Support(recovery: recovery),
          ),
        ),
      ),
    );
  }
}

class _Support extends ConsumerStatefulWidget {
  const _Support({required this.recovery});

  /// Null while the suggestion is still loading or if it failed.
  final Recovery? recovery;

  @override
  ConsumerState<_Support> createState() => _SupportState();
}

class _SupportState extends ConsumerState<_Support> {
  Future<void> _acceptSuggestion(SuggestedAction? action) async {
    final Recovery? recovery = widget.recovery;
    final int? challengeId = action?.challengeId ?? recovery?.challengeId;
    if (challengeId == null) return;

    final CheckInResult? result = await showCheckInSheet(
      context,
      challengeId: challengeId,
      challengeTitle: recovery?.challengeTitle ?? 'your challenge',
      fromRecovery: true,
    );
    if (!mounted || result == null) return;

    if (result.checkIn.status == CheckInStatus.completed) {
      // The check-in already invalidated the dashboard and this controller, so
      // Home comes back without its banner.
      AppSnackbar.showSuccess(
        context,
        'That is the comeback. Well done for starting again.',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;
    final Recovery? recovery = widget.recovery;
    final SuggestedAction? action = recovery?.suggestedAction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: semantic.recovery.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.spa_rounded, size: 40, color: semantic.recovery),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          recovery?.title ?? RecoveryScreen.fallbackTitle,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          recovery?.message ?? RecoveryScreen.fallbackMessage,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ActionCard(
          icon: Icons.wb_sunny_rounded,
          title: 'Restart today',
          body: recovery?.challengeTitle == null
              ? 'One check-in puts you back on the board.'
              : 'One check-in on ${recovery!.challengeTitle} puts you back on '
                    'the board.',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _ActionCard(
          icon: Icons.eco_rounded,
          title: 'Make it smaller',
          body:
              'Shrink today to the two-minute version. Showing up matters more '
              'than the size of the step.',
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: action?.label ?? 'Check in now',
          icon: Icons.check_circle_outline_rounded,
          onPressed: () => _acceptSuggestion(action),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoute.home.path),
          child: const Text('Maybe later'),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: semantic.recovery, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reached when there is nothing pending — a compliment, not a dead end.
class _NothingToRecover extends StatelessWidget {
  const _NothingToRecover();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Icon(
            Icons.wb_sunny_rounded,
            size: 40,
            color: semantic.success,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Nothing to pick up right now.',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'You are on track. Come back here any time a day slips by.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Back to today',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoute.home.path),
        ),
      ],
    );
  }
}
