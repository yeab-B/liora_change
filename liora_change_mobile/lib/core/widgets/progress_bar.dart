import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Rounded linear progress indicator: `primaryContainer` track, `primary` fill.
///
/// Takes the API's `progress_percent` (0–100) directly and animates changes
/// rather than snapping, per design system §5.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.percent,
    this.height = 10,
    this.animate = true,
  });

  final double percent;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double value = (percent / 100).clamp(0.0, 1.0);

    Widget bar(double v) => ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: colors.primaryContainer,
        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
      ),
    );

    return Semantics(
      label: 'Progress ${value * 100 ~/ 1} percent',
      excludeSemantics: true,
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double v, _) => bar(v),
            )
          : bar(value),
    );
  }
}
