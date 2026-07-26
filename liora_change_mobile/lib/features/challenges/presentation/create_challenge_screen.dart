import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/content_bounds.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/challenge.dart';
import '../../../models/challenge_category.dart';
import '../../../models/challenge_template.dart';
import '../../../router/app_router.dart';
import '../application/challenge_list_controller.dart';
import '../application/create_challenge_controller.dart';
import 'widgets/challenge_badges.dart';

/// Two taps to a challenge: pick an area of life, then pick (or write) the
/// promise. A blank form would make starting feel like work.
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  static const int _categoryStep = 0;
  static const int _templateStep = 1;

  int _step = _categoryStep;
  final TextEditingController _customTitle = TextEditingController();

  @override
  void dispose() {
    _customTitle.dispose();
    super.dispose();
  }

  void _goToStep(int step) => setState(() => _step = step);

  Future<void> _submit() async {
    final Challenge? created = await ref
        .read(createChallengeControllerProvider.notifier)
        .submit();

    if (!mounted) return;

    if (created == null) {
      final Object? error = ref
          .read(createChallengeControllerProvider)
          .submission
          .error;
      AppSnackbar.showError(
        context,
        error is ApiException
            ? error.message
            : 'We could not create that challenge. Please try again.',
      );
      return;
    }

    AppSnackbar.showSuccess(context, '${created.title} is ready to start.');
    context.go(AppRoute.home.path);
  }

  @override
  Widget build(BuildContext context) {
    final CreateChallengeState state = ref.watch(
      createChallengeControllerProvider,
    );
    final bool onTemplateStep = _step == _templateStep;

    return PopScope(
      // Back on step two returns to the categories with the choice intact,
      // rather than dropping the member out of the flow.
      canPop: !onTemplateStep,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _goToStep(_categoryStep);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('New challenge')),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: ContentBounds(
                  child: _StepIndicator(
                    step: _step,
                    onBack: onTemplateStep
                        ? () => _goToStep(_categoryStep)
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: onTemplateStep
                    ? _TemplateStep(
                        categoryId: state.categoryId!,
                        customTitle: _customTitle,
                      )
                    : _CategoryStep(
                        selectedId: state.categoryId,
                        onSelected: (int id) {
                          ref
                              .read(createChallengeControllerProvider.notifier)
                              .selectCategory(id);
                          _goToStep(_templateStep);
                        },
                      ),
              ),
              if (onTemplateStep)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ContentBounds(
                      horizontalPadding: 0,
                      child: PrimaryButton(
                        label: 'Create challenge',
                        isLoading: state.isSubmitting,
                        onPressed: state.canSubmit ? _submit : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, this.onBack});

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const List<String> labels = <String>['Choose an area', 'Choose a goal'];

    return Row(
      children: <Widget>[
        if (onBack != null)
          IconButton(
            tooltip: 'Back a step',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
        Expanded(
          child: Text(
            'Step ${step + 1} of 2 · ${labels[step]}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        for (int i = 0; i < labels.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(left: AppSpacing.xxs),
            height: 8,
            width: i == step ? 24 : 8,
            decoration: BoxDecoration(
              color: i == step
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}

class _CategoryStep extends ConsumerWidget {
  const _CategoryStep({required this.onSelected, this.selectedId});

  final ValueChanged<int> onSelected;
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChallengeCategory>> categories = ref.watch(
      categoriesProvider,
    );

    return categories.when(
      loading: () => const _StepSkeleton(),
      error: (Object error, StackTrace stack) => ErrorRetryView(
        message: error is ApiException
            ? error.message
            : 'We could not load the categories.',
        onRetry: () => ref.invalidate(categoriesProvider),
      ),
      data: (List<ChallengeCategory> data) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: ContentBounds(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final ChallengeCategory category in data)
                _CategoryChoice(
                  category: category,
                  selected: category.id == selectedId,
                  onTap: () => onSelected(category.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ChallengeCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color background = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final Color foreground = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(categoryIcon(category.slug), size: 18, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                category.name,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateStep extends ConsumerWidget {
  const _TemplateStep({required this.categoryId, required this.customTitle});

  final int categoryId;
  final TextEditingController customTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChallengeTemplate>> templates = ref.watch(
      templatesProvider(categoryId),
    );
    final CreateChallengeState state = ref.watch(
      createChallengeControllerProvider,
    );
    final CreateChallengeController controller = ref.read(
      createChallengeControllerProvider.notifier,
    );

    return templates.when(
      loading: () => const _StepSkeleton(),
      error: (Object error, StackTrace stack) => ErrorRetryView(
        message: error is ApiException
            ? error.message
            : 'We could not load any goals for this area.',
        onRetry: () => ref.invalidate(templatesProvider(categoryId)),
      ),
      data: (List<ChallengeTemplate> data) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: ContentBounds(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ChallengeTemplate template in data) ...<Widget>[
                _TemplateCard(
                  template: template,
                  selected:
                      !state.isCustom && state.template?.id == template.id,
                  onTap: () => controller.selectTemplate(template),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _CustomCard(
                selected: state.isCustom,
                controller: customTitle,
                onTap: () => controller.useCustom(),
                onChanged: controller.setCustomTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final ChallengeTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(template.title, style: theme.textTheme.titleMedium),
                if (template.description != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    template.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${template.durationDays} days · ${template.difficulty.name}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _CustomCard extends StatelessWidget {
  const _CustomCard({
    required this.selected,
    required this.controller,
    required this.onTap,
    required this.onChanged,
  });

  final bool selected;
  final TextEditingController controller;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      color: selected ? theme.colorScheme.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.edit_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Something else',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Write your own promise in a few words.',
            style: theme.textTheme.bodyMedium,
          ),
          if (selected) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Challenge title',
                hintText: 'e.g. Walk 10 minutes after breakfast',
              ),
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepSkeleton extends StatelessWidget {
  const _StepSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: 3,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) =>
          const ContentBounds(child: LoadingSkeleton.card(height: 96)),
    );
  }
}
