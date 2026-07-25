import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_count.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../models/check_in_result.dart';
import '../../../models/enums.dart';
import '../../../router/app_router.dart';
import '../application/check_in_controller.dart';

/// Opens the day's check-in and resolves with what was recorded, or null if
/// the member dismissed the sheet without answering.
///
/// A sheet rather than a screen: this is the interaction the member performs
/// every day, and it should feel like a two-tap answer to a question, not a
/// destination they have to navigate back out of.
Future<CheckInResult?> showCheckInSheet(
  BuildContext context, {
  required int challengeId,
  required String challengeTitle,
  bool fromRecovery = false,
}) {
  return showModalBottomSheet<CheckInResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (BuildContext context) => CheckInSheet(
      challengeId: challengeId,
      challengeTitle: challengeTitle,
      fromRecovery: fromRecovery,
    ),
  );
}

class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
    this.fromRecovery = false,
  });

  final int challengeId;
  final String challengeTitle;

  /// True when the recovery screen opened this sheet, so a skip acknowledges
  /// in place instead of pushing recovery on top of itself.
  final bool fromRecovery;

  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  final TextEditingController _note = TextEditingController();
  bool _noteOpen = false;

  /// Which button is waiting, so only that one shows a spinner.
  CheckInStatus? _pending;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit(CheckInStatus status) async {
    setState(() => _pending = status);
    await ref
        .read(checkInControllerProvider(widget.challengeId).notifier)
        .submit(status: status, note: _note.text);
    if (mounted) setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<CheckInResult?> submission = ref.watch(
      checkInControllerProvider(widget.challengeId),
    );
    final CheckInResult? result = submission.value;

    return Padding(
      // Lift the sheet above the keyboard so the note field and the buttons
      // stay reachable while typing.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (result) {
            null => _Form(
              key: const ValueKey<String>('form'),
              title: widget.challengeTitle,
              note: _note,
              noteOpen: _noteOpen,
              onToggleNote: () => setState(() => _noteOpen = !_noteOpen),
              pending: _pending,
              busy: submission.isLoading,
              error: submission.error,
              onSubmit: _submit,
            ),
            final CheckInResult done
                when done.checkIn.status == CheckInStatus.completed =>
              _Celebration(
                key: const ValueKey<String>('celebration'),
                result: done,
              ),
            final CheckInResult done => _SkipAcknowledgement(
              key: const ValueKey<String>('skipped'),
              result: done,
              fromRecovery: widget.fromRecovery,
            ),
          },
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    super.key,
    required this.title,
    required this.note,
    required this.noteOpen,
    required this.onToggleNote,
    required this.pending,
    required this.busy,
    required this.error,
    required this.onSubmit,
  });

  final String title;
  final TextEditingController note;
  final bool noteOpen;
  final VoidCallback onToggleNote;
  final CheckInStatus? pending;
  final bool busy;
  final Object? error;
  final ValueChanged<CheckInStatus> onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text('How did today go?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        _Outcomes(pending: pending, busy: busy, onSubmit: onSubmit),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onToggleNote,
            icon: Icon(
              noteOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            label: const Text('Add a note (optional)'),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: noteOpen
              ? Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TextField(
                    controller: note,
                    autofocus: true,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Anything worth remembering about today?',
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          _InlineProblem(error: error!),
        ],
      ],
    );
  }
}

/// Two answers of equal weight. The colour says which outcome it was, not
/// which one was the "right" one — skip is neutral, never red.
class _Outcomes extends StatelessWidget {
  const _Outcomes({
    required this.pending,
    required this.busy,
    required this.onSubmit,
  });

  final CheckInStatus? pending;
  final bool busy;
  final ValueChanged<CheckInStatus> onSubmit;

  @override
  Widget build(BuildContext context) {
    final Widget did = _DidItButton(
      isLoading: busy && pending == CheckInStatus.completed,
      onPressed: busy ? null : () => onSubmit(CheckInStatus.completed),
    );
    final Widget skip = SecondaryButton(
      label: 'Skip today',
      icon: Icons.nights_stay_rounded,
      isLoading: busy && pending == CheckInStatus.skipped,
      onPressed: busy ? null : () => onSubmit(CheckInStatus.skipped),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Side by side when there is room; stacked keeps both labels legible
        // on the narrowest phones rather than shrinking one of them.
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              did,
              const SizedBox(height: AppSpacing.sm),
              skip,
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: did),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: skip),
          ],
        );
      },
    );
  }
}

class _DidItButton extends StatelessWidget {
  const _DidItButton({required this.isLoading, this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColors semantic = context.semanticColors;

    return PrimaryButton(
      label: 'I did it!',
      icon: Icons.celebration_rounded,
      isLoading: isLoading,
      onPressed: onPressed,
      backgroundColor: semantic.success,
      foregroundColor: semantic.onSuccess,
    );
  }
}

/// A failed request is a system problem, not a judgement on the member, so it
/// stays neutral — no red, no warning triangle.
class _InlineProblem extends StatelessWidget {
  const _InlineProblem({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String message = error is ApiException
        ? (error as ApiException).message
        : 'We could not save that just now. Please try again.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration({super.key, required this.result});

  final CheckInResult result;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;
    final CheckInSummary summary = result.summary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (BuildContext context, double scale, Widget? child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: semantic.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 44,
                color: semantic.success,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'That is today done.',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: _CountUp(
                value: summary.currentStreak,
                label: 'day streak',
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            Expanded(
              child: _CountUp(
                value: summary.xpEarned,
                label: 'XP earned',
                icon: Icons.auto_awesome_rounded,
                prefix: '+',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Nice!',
          onPressed: () => Navigator.of(context).pop(result),
        ),
      ],
    );
  }
}

class _CountUp extends StatelessWidget {
  const _CountUp({
    required this.value,
    required this.label,
    required this.icon,
    this.prefix = '',
  });

  final int value;
  final String label;
  final IconData icon;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    return Column(
      children: <Widget>[
        Icon(icon, color: semantic.success),
        const SizedBox(height: AppSpacing.xxs),
        AnimatedCount(
          value: value,
          prefix: prefix,
          duration: const Duration(milliseconds: 700),
          style: theme.textTheme.displaySmall,
        ),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _SkipAcknowledgement extends StatelessWidget {
  const _SkipAcknowledgement({
    super.key,
    required this.result,
    required this.fromRecovery,
  });

  final CheckInResult result;
  final bool fromRecovery;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: semantic.recovery.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_twilight_rounded,
              size: 44,
              color: semantic.recovery,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No worries — tomorrow is a fresh start.',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Resting a day is part of the plan. Come back with something small '
          'and the streak builds again.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (fromRecovery)
          // Already on the comeback screen; sending them there again would
          // just stack the same page on itself.
          PrimaryButton(
            label: 'Okay',
            onPressed: () => Navigator.of(context).pop(result),
          )
        else ...<Widget>[
          PrimaryButton(
            label: 'Help me come back',
            onPressed: () {
              final GoRouter router = GoRouter.of(context);
              Navigator.of(context).pop(result);
              router.push(AppRoute.recovery.path);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(result),
            child: const Text('Not now'),
          ),
        ],
      ],
    );
  }
}
