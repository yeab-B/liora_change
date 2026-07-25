import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/content_bounds.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../models/badge_unlocked.dart';
import '../../../models/progress.dart';
import '../../../models/user.dart';
import '../../../router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import 'widgets/badge_tile.dart';
import 'widgets/logout_dialog.dart';

/// Who the member is and what they have earned — the quiet counterpart to
/// Home's "what next".
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String badgesEmptyMessage =
      'No badges yet. Your first check-in unlocks one.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProfileData> profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppRoute.profile.title)),
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () => ref.read(profileControllerProvider.notifier).refresh(),
          child: _Body(profile: profile),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile});

  final AsyncValue<ProfileData> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A pull-to-refresh keeps the old numbers on screen; only a genuine first
    // load falls through to the skeleton.
    final ProfileData? data = profile.value;

    if (data == null && profile.hasError) {
      return _Scrollable(
        fillHeight: true,
        child: ErrorRetryView(
          message: _messageFor(profile.error),
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
      );
    }

    if (data == null) return const _Scrollable(child: _ProfileSkeleton());

    return _Scrollable(child: _Profile(data: data));
  }

  static String _messageFor(Object? error) {
    if (error is ApiException) return error.message;
    return 'We could not load your profile. Please try again.';
  }
}

/// Always scrollable so pull-to-refresh works on a short page, and capped at
/// the design system's reading width so tablets keep a single centred column.
class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child, this.fillHeight = false});

  final Widget child;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: fillHeight
                  ? constraints.maxHeight - AppSpacing.lg * 2
                  : 0,
            ),
            child: ContentBounds(
              alignment: fillHeight ? Alignment.center : Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _Profile extends ConsumerWidget {
  const _Profile({required this.data});

  final ProfileData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authControllerProvider).value;
    final Progress progress = data.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Header(user: user, progress: progress),
        const SizedBox(height: AppSpacing.lg),
        _Stats(progress: progress),
        const SizedBox(height: AppSpacing.lg),
        _Badges(data: data),
        const SizedBox(height: AppSpacing.xl),
        SecondaryButton(
          label: 'Log out',
          icon: Icons.logout_rounded,
          onPressed: () => _confirmLogout(context, ref),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await showLogoutDialog(context);
    if (!confirmed || !context.mounted) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.go(AppRoute.login.path);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.progress});

  final User? user;
  final Progress progress;

  static String initialsOf(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    final String first = parts.isEmpty || parts.first.isEmpty
        ? '?'
        : parts.first[0];
    final String last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name = user?.name ?? 'Your profile';

    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            initialsOf(name),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(name, style: theme.textTheme.headlineSmall),
              if (user != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  user!.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Level ${progress.level} · ${progress.xpTotal} XP',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    // Intrinsic height keeps the three cards level when one label wraps.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: StatTile(
              label: 'Challenges',
              value: progress.totalChallenges,
              icon: Icons.flag_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatTile(
              label: 'Current streak',
              value: progress.currentStreak,
              icon: Icons.local_fire_department_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatTile(
              label: 'Longest streak',
              value: progress.longestStreak,
              icon: Icons.emoji_events_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.data});

  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int earned = data.badges.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text('Badges', style: theme.textTheme.titleMedium)),
            Text(
              '$earned of ${BadgeCatalogue.all.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (earned == 0) ...<Widget>[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            ProfileScreen.badgesEmptyMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Two columns on a phone, three once there is room, so a 320px screen
        // never squeezes a badge name into a single character per line.
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double tileHeight = 148;
            final int columns = constraints.maxWidth >= 420 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: BadgeCatalogue.all.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: tileHeight,
              ),
              itemBuilder: (BuildContext context, int index) {
                final BadgeDefinition definition = BadgeCatalogue.all[index];
                return BadgeTile(
                  definition: definition,
                  unlocked: data.earned(definition.code),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            LoadingSkeleton(width: 64, height: 64, radius: AppRadius.pill),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LoadingSkeleton(width: 160, height: 20),
                  SizedBox(height: AppSpacing.xs),
                  LoadingSkeleton(width: 200),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(child: LoadingSkeleton.card(height: 96)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: LoadingSkeleton.card(height: 96)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: LoadingSkeleton.card(height: 96)),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton.card(height: 148),
      ],
    );
  }
}