import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/check_in.dart';
import '../../../../models/enums.dart';

/// One recorded day. Completed is filled success; a skipped or missed day is
/// amber recovery, never red — a missed day is a state to come back from, not
/// a failure to punish.
class CheckInIndicator extends StatelessWidget {
  const CheckInIndicator({
    super.key,
    required this.status,
    required this.label,
  });

  final CheckInStatus status;

  /// Short day label, e.g. `26/7`.
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = context.semanticColors;

    final Color accent = switch (status) {
      CheckInStatus.completed => semantic.success,
      CheckInStatus.skipped || CheckInStatus.missed => semantic.recovery,
    };
    final bool filled = status != CheckInStatus.missed;

    return Semantics(
      label: '$label ${status.name}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? accent.withValues(alpha: 0.16) : null,
              border: Border.all(
                color: filled ? accent : theme.colorScheme.outlineVariant,
                width: filled ? 1.5 : 1,
              ),
            ),
            child: Icon(
              switch (status) {
                CheckInStatus.completed => Icons.check_rounded,
                CheckInStatus.skipped => Icons.pause_rounded,
                CheckInStatus.missed => Icons.remove_rounded,
              },
              size: 18,
              color: filled ? accent : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// Wraps so a long history reflows instead of scrolling off the card.
class CheckInHistoryStrip extends StatelessWidget {
  const CheckInHistoryStrip({super.key, required this.checkIns});

  final List<CheckIn> checkIns;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final CheckIn checkIn in checkIns)
          CheckInIndicator(
            status: checkIn.status,
            label: shortDate(checkIn.checkInDate),
          ),
      ],
    );
  }

  /// `2026-07-26` becomes `26/7`; anything unparseable is shown as sent.
  static String shortDate(String isoDate) {
    final DateTime? date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${date.day}/${date.month}';
  }
}
