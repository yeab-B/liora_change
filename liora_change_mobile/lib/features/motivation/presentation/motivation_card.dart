import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/demo_ai_config.dart';
import '../../../core/services/addis_voice_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../models/motivation.dart';
import '../application/motivation_controller.dart';

/// A one-tap nudge for the day, written for this member's challenge.
///
/// The card has no failure state on purpose: if the call cannot be made, it
/// shows a warm line of its own and offers the tap again. Whether the message
/// came from OpenAI or the backend's template is deliberately invisible.
class MotivationCard extends ConsumerWidget {
  const MotivationCard({super.key, required this.challengeId, this.preview});

  final int challengeId;

  /// `motivation_preview` from the dashboard payload, used as the resting
  /// line so the card says something before it is ever tapped.
  final String? preview;

  static const String idleLabel = 'Need a boost?';

  /// Used only when the request cannot be completed at all.
  static const List<String> fallbackMessages = <String>[
    'Keep going — every small step counts.',
    'You do not need a perfect day, just the next one.',
    'Start smaller than feels impressive. That still moves you.',
  ];

  static String fallbackFor(int challengeId) =>
      fallbackMessages[challengeId.abs() % fallbackMessages.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<Motivation?> state = ref.watch(
      motivationControllerProvider(challengeId),
    );
    final Motivation? motivation = state.value;
    final bool busy = state.isLoading;

    void generate() {
      ref.read(motivationControllerProvider(challengeId).notifier).generate();
    }

    // A failed call still says something kind, and still invites the tap
    // again — it never presents itself as an error.
    final bool failed = state.hasError && motivation == null;
    final String? message = failed
        ? fallbackFor(challengeId)
        : motivation?.message;

    return AppCard(
      color: theme.colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(
            canRegenerate: motivation != null && !busy,
            onRegenerate: generate,
            speakText: message,
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: switch ((busy, message)) {
                (true, _) => const _Shimmer(key: ValueKey<String>('loading')),
                (false, final String text) => Text(
                  text,
                  key: ValueKey<String>('message:$text'),
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
                ),
                _ => Text(
                  preview ?? idleLabel,
                  key: const ValueKey<String>('idle'),
                  style: theme.textTheme.bodyMedium,
                ),
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // The regenerate icon takes over once a message has arrived, so the
          // filled affordance never competes with Home's check-in button.
          if (motivation == null)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: busy ? null : generate,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Motivate me'),
              ),
            ),
        ],
      ),
    );
  }
}

/// The icon keeps its space whatever the state, so the card does not twitch
/// while a new message is being written.
class _Header extends ConsumerWidget {
  const _Header({
    required this.canRegenerate,
    required this.onRegenerate,
    this.speakText,
  });

  final bool canRegenerate;
  final VoidCallback onRegenerate;
  final String? speakText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.colorScheme.onPrimaryContainer;
    final AddisVoiceStatus voice = ref.watch(addisVoiceProvider);
    final bool canSpeak =
        DemoAiConfig.addisEnabled &&
        speakText != null &&
        speakText!.trim().isNotEmpty;
    final bool speakingThis =
        canSpeak &&
        voice.currentText == speakText &&
        (voice.state == AddisVoiceState.playing ||
            voice.state == AddisVoiceState.loading);

    return Row(
      children: <Widget>[
        Icon(Icons.auto_awesome_rounded, size: 20, color: accent),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Your daily nudge',
            style: theme.textTheme.titleMedium?.copyWith(color: accent),
          ),
        ),
        if (canSpeak)
          IconButton(
            onPressed: () =>
                ref.read(addisVoiceProvider.notifier).play(speakText!),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: speakingThis ? 'Stop' : 'Listen',
            icon: Icon(
              speakingThis && voice.state == AddisVoiceState.playing
                  ? Icons.stop_circle_outlined
                  : Icons.volume_up_rounded,
            ),
          ),
        AnimatedOpacity(
          opacity: canRegenerate ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: IconButton(
            onPressed: canRegenerate ? onRegenerate : null,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: 'New message',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LoadingSkeleton(height: 14),
        SizedBox(height: AppSpacing.xs),
        LoadingSkeleton(height: 14, width: 180),
      ],
    );
  }
}
