import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/ui_widgets.dart';
import '../../../models/check_in_models.dart';
import '../application/check_in_controller.dart';

/// Opens the check-in bottom sheet for [challengeId].
Future<void> showCheckInSheet(
  BuildContext context, {
  required int challengeId,
  required String challengeTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.cardRadius),
      ),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: CheckInSheet(
        challengeId: challengeId,
        challengeTitle: challengeTitle,
      ),
    ),
  );
}

class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
  });

  final int challengeId;
  final String challengeTitle;

  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  final _noteController = TextEditingController();
  bool _showNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkInControllerProvider(widget.challengeId));
    final controller = ref.read(checkInControllerProvider(widget.challengeId).notifier);
    final isSubmitting = state.phase == CheckInPhase.submitting;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildContent(context, state, controller, isSubmitting),
    );
  }

  Widget _buildContent(
    BuildContext context,
    CheckInState state,
    CheckInController controller,
    bool isSubmitting,
  ) {
    switch (state.phase) {
      case CheckInPhase.completed:
        return _CelebrationView(
          key: const ValueKey('celebration'),
          result: state.result!,
          onContinue: () => Navigator.of(context).pop(),
        );
      case CheckInPhase.skipped:
        return _SkippedView(
          key: const ValueKey('skipped'),
          onContinue: () {
            Navigator.of(context).pop();
            // TODO(Issue #7): wire recovery screen when route exists.
            context.push('/recovery');
          },
        );
      default:
        return _FormView(
          key: const ValueKey('form'),
          challengeTitle: widget.challengeTitle,
          noteController: _noteController,
          showNote: _showNote,
          onToggleNote: () => setState(() => _showNote = !_showNote),
          isSubmitting: isSubmitting,
          errorMessage:
              state.phase == CheckInPhase.error ? state.errorMessage : null,
          onComplete: () => controller.submit(
            status: 'completed',
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ),
          onSkip: () => controller.submit(
            status: 'skipped',
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ),
        );
    }
  }
}

class _FormView extends StatelessWidget {
  const _FormView({
    super.key,
    required this.challengeTitle,
    required this.noteController,
    required this.showNote,
    required this.onToggleNote,
    required this.isSubmitting,
    required this.onComplete,
    required this.onSkip,
    this.errorMessage,
  });

  final String challengeTitle;
  final TextEditingController noteController;
  final bool showNote;
  final VoidCallback onToggleNote;
  final bool isSubmitting;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final success =
        Theme.of(context).extension<AppSemanticColors>()!.success;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
        AppSpacing.screenHorizontal,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(challengeTitle, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('How did today go?', style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 52),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('I did it!'),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: SecondaryButton(
                  label: 'Skip today',
                  isLoading: false,
                  onPressed: isSubmitting ? null : onSkip,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: onToggleNote,
            child: Text(showNote ? 'Hide note' : 'Add a note (optional)'),
          ),
          if (showNote)
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Optional note…',
                border: OutlineInputBorder(),
              ),
            ),
          if (isSubmitting) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: CircularProgressIndicator()),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _CelebrationView extends StatelessWidget {
  const _CelebrationView({
    super.key,
    required this.result,
    required this.onContinue,
  });

  final CheckInResult result;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final success =
        Theme.of(context).extension<AppSemanticColors>()!.success;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Icon(Icons.celebration, size: 64, color: success),
          ),
          const SizedBox(height: AppSpacing.lg),
          TweenAnimationBuilder<int>(
            tween: IntTween(
              begin: 0,
              end: result.summary.currentStreak,
            ),
            duration: const Duration(milliseconds: 800),
            builder: (context, streak, _) => Text(
              'Streak: $streak',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: success,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: result.summary.xpEarned),
            duration: const Duration(milliseconds: 800),
            builder: (context, xp, _) => Text('+ $xp XP'),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Nice!', onPressed: onContinue),
        ],
      ),
    );
  }
}

class _SkippedView extends StatelessWidget {
  const _SkippedView({
    super.key,
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final recovery =
        Theme.of(context).extension<AppSemanticColors>()!.recovery;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa_outlined, size: 56, color: recovery),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No worries — tomorrow\'s a fresh start',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Missed day — let\'s restart small when you\'re ready.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Continue', onPressed: onContinue),
        ],
      ),
    );
  }
}
