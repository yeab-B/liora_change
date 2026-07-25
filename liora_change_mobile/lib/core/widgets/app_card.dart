import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Rounded surface container with the design system's shared padding, radius
/// and soft shadow. Every card-like surface in the app uses this rather than a
/// bespoke [Container].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Overrides the card surface, e.g. `primaryContainer` for highlighted cards.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.card);

    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
