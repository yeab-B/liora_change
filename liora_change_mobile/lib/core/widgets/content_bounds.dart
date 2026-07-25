import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Applies the design system's §6 layout rule in one place: screen-edge insets
/// on phones, and a capped, centred column once the window gets wider than a
/// comfortable reading width.
///
/// Screens wrap their scrollable content in this instead of hand-rolling
/// padding, so every screen breaks at the same width.
class ContentBounds extends StatelessWidget {
  const ContentBounds({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.horizontalPadding = AppSpacing.screenHorizontal,
  });

  final Widget child;

  /// [Alignment.center] suits a full-screen empty or error view; the default
  /// keeps content reading from the top.
  final AlignmentGeometry alignment;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.maxWidth - horizontalPadding * 2;
        final double width = math.min(available, AppLayout.maxContentWidth);

        return Align(
          alignment: alignment,
          child: SizedBox(width: math.max(width, 0), child: child),
        );
      },
    );
  }
}
