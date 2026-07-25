import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../../core/widgets/content_bounds.dart';
import '../../../models/chat_message.dart';
import '../../../router/app_router.dart';
import '../application/chat_controller.dart';

/// The coach: a grounded answer to a behaviour-change question, in the shape
/// everyone already knows how to use.
class CoachChatScreen extends ConsumerStatefulWidget {
  const CoachChatScreen({super.key});

  static const String greeting =
      'I am your coach. Ask me anything about building a habit, keeping a '
      'streak, or picking it back up after a slip.';

  static const List<String> starters = <String>[
    'How do I build a streak?',
    'I keep skipping — help?',
    'How small should I start?',
  ];

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// Whether the member was reading the newest message before this change.
  /// If they had scrolled up into the history, they are left where they are.
  bool _wasAtBottom = true;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _isNearBottom {
    if (!_scroll.hasClients) return true;
    final ScrollPosition position = _scroll.position;
    return position.maxScrollExtent - position.pixels < 120;
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _wasAtBottom = _isNearBottom;
    _input.clear();
    ref.read(chatControllerProvider.notifier).send(text);
    _scrollToEndSoon();
  }

  void _scrollToEndSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChatState chat = ref.watch(chatControllerProvider);

    ref.listen<ChatState>(chatControllerProvider, (
      ChatState? previous,
      ChatState next,
    ) {
      final bool grew = (previous?.messages.length ?? 0) < next.messages.length;
      if (grew && _wasAtBottom) _scrollToEndSoon();
      if (!grew) _wasAtBottom = _isNearBottom;
    });

    return Scaffold(
      appBar: AppBar(title: Text(AppRoute.coach.title)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: chat.isEmpty
                  ? _Welcome(onAsk: _send)
                  : _Conversation(chat: chat, controller: _scroll),
            ),
            _Composer(
              controller: _input,
              enabled: !chat.isWaitingForReply,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Conversation extends ConsumerWidget {
  const _Conversation({required this.chat, required this.controller});

  final ChatState chat;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      itemCount: chat.messages.length + (chat.isWaitingForReply ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index >= chat.messages.length) return const TypingIndicator();

        final ChatMessage message = chat.messages[index];
        return ChatBubble(
          message: message,
          onRetry: () =>
              ref.read(chatControllerProvider.notifier).retry(message.id),
        );
      },
    );
  }
}

/// First entry: a hello and three ways in, so nobody has to invent a question.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onAsk});

  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xl,
      ),
      child: ContentBounds(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const CoachAvatar(size: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              CoachChatScreen.greeting,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final String starter in CoachChatScreen.starters)
                  ActionChip(
                    onPressed: () => onAsk(starter),
                    label: Text(starter),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots that breathe, so waiting feels like someone is writing.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          const CoachAvatar(),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.card),
                topRight: Radius.circular(AppRadius.card),
                bottomRight: Radius.circular(AppRadius.card),
                bottomLeft: Radius.circular(AppSpacing.xxs),
              ),
            ),
            child: Semantics(
              label: 'Coach is writing',
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int dot = 0; dot < 3; dot++) ...<Widget>[
                        if (dot > 0) const SizedBox(width: AppSpacing.xxs),
                        Opacity(
                          opacity: _opacityFor(dot),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: colors.onSurfaceVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _opacityFor(int dot) {
    final double phase = (_controller.value - dot * 0.15) % 1;
    return 0.35 + 0.65 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.xs,
        ),
        child: ContentBounds(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: enabled ? onSend : null,
                  decoration: const InputDecoration(
                    hintText: 'Ask your coach…',
                    border: InputBorder.none,
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (BuildContext context, TextEditingValue value, _) {
                  final bool canSend = enabled && value.text.trim().isNotEmpty;
                  return IconButton.filled(
                    onPressed: canSend ? () => onSend(controller.text) : null,
                    tooltip: 'Send',
                    icon: const Icon(Icons.send_rounded, size: 20),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
