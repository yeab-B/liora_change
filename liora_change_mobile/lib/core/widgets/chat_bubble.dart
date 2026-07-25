import 'package:flutter/material.dart';

import '../../models/chat_message.dart';
import '../../models/chat_source.dart';
import '../theme/app_spacing.dart';

/// One turn of the conversation: the member on the right, the coach on the
/// left with its own mark and, when the answer was grounded in the knowledge
/// base, the articles it leaned on.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onRetry});

  final ChatMessage message;

  /// Called from the inline affordance when a message never made it out.
  final VoidCallback? onRetry;

  /// Long answers stay readable instead of running the full width.
  static const double maxWidthFraction = 0.78;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool fromUser = message.isFromUser;
    final Color background = fromUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final Color foreground = fromUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final Widget bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppRadius.card),
          topRight: const Radius.circular(AppRadius.card),
          // The flat corner points at whoever is speaking.
          bottomLeft: Radius.circular(
            fromUser ? AppRadius.card : AppSpacing.xxs,
          ),
          bottomRight: Radius.circular(
            fromUser ? AppSpacing.xxs : AppRadius.card,
          ),
        ),
      ),
      child: Text(
        message.content,
        style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: fromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!fromUser) ...<Widget>[
            const CoachAvatar(),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * maxWidthFraction,
              ),
              child: Column(
                crossAxisAlignment: fromUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  bubble,
                  if (message.sources.isNotEmpty)
                    _Sources(sources: message.sources),
                  if (message.delivery == MessageDelivery.failed)
                    _RetryLine(onRetry: onRetry),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoachAvatar extends StatelessWidget {
  const CoachAvatar({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.spa_rounded,
        size: size * 0.6,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

/// Citations sit under the answer, quiet enough to ignore and specific enough
/// to trust.
class _Sources extends StatelessWidget {
  const _Sources({required this.sources});

  final List<ChatSource> sources;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xxs,
        children: <Widget>[
          for (final ChatSource source in sources)
            ActionChip(
              onPressed: () => _show(context, source),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: Icon(
                Icons.menu_book_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              label: Text('Based on: ${source.title}'),
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
        ],
      ),
    );
  }

  void _show(BuildContext context, ChatSource source) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(source.title),
        content: Text(source.snippet),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _RetryLine extends StatelessWidget {
  const _RetryLine({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Not sent',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
