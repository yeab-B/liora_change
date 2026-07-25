import 'package:flutter/material.dart';

import '../../models/recovery.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Home's answer to a skipped or missed day.
///
/// Everything here is deliberate: the `recovery` amber token (never the error
/// red), a sunrise rather than a warning triangle, and copy that treats the
/// gap as information. See `docs/mvp/mobile-issues/00-design-system.md`.
class RecoveryBanner extends StatelessWidget {
  const RecoveryBanner({
    super.key,
    required this.recovery,
    required this.onOpen,
  });

  final Recovery recovery;
  final VoidCallback onOpen;

  static const String fallbackTitle = 'Life happens. Let us pick this back up.';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    return _GentleEntrance(
      child: AppCard(
        color: semantic.recovery.withValues(alpha: 0.14),
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: semantic.recovery.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.spa_rounded,
                    color: semantic.recovery,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        recovery.title ?? fallbackTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (recovery.message != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          recovery.message!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(foregroundColor: semantic.recovery),
                child: Text(recovery.suggestedAction?.label ?? 'Come back in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and lifts the banner into place, so it never pops in as an alarm.
class _GentleEntrance extends StatelessWidget {
  const _GentleEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (BuildContext context, double t, Widget? child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
