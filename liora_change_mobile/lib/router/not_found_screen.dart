import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_spacing.dart';
import '../core/widgets/empty_state.dart';
import 'app_router.dart';

/// Shown when a link points at something the app cannot resolve.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: EmptyState(
              icon: Icons.explore_off_rounded,
              title: 'We could not find that',
              message:
                  'The link may be out of date. Your challenges are all still '
                  'here.',
              actionLabel: 'Go to my challenges',
              onAction: () => context.go(AppRoute.challenges.path),
            ),
          ),
        ),
      ),
    );
  }
}
