import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_skeleton.dart';

/// First-paint placeholder shaped like the real layout, so nothing jumps when
/// the data lands.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const <Widget>[
        LoadingSkeleton(width: 220, height: 28),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: 140, height: 16),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton.card(height: 180),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton.card(height: 110),
      ],
    );
  }
}
