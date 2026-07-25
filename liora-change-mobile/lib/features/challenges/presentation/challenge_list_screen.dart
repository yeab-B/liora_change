import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/shared_widgets.dart';

class ChallengeListScreen extends StatelessWidget {
  const ChallengeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          AppCard(
            child: ListTile(
              title: const Text('Morning Walk'),
              subtitle: const Text('Active · tap to open detail'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/challenges/1'),
            ),
          ),
        ],
      ),
    );
  }
}
