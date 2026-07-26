import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/challenge.dart';
import '../../../models/challenge_template.dart';
import '../../home/application/dashboard_controller.dart';
import '../data/challenge_repository.dart';
import 'challenge_list_controller.dart';

/// What the two-step create flow has gathered so far.
class CreateChallengeState {
  const CreateChallengeState({
    this.categoryId,
    this.template,
    this.customTitle = '',
    this.isCustom = false,
    this.submission = const AsyncValue<Challenge?>.data(null),
  });

  final int? categoryId;

  /// Kept whole rather than by id so [submit] can copy its fields without a
  /// second request.
  final ChallengeTemplate? template;
  final String customTitle;

  /// True once the member chooses "Something else" over a template.
  final bool isCustom;
  final AsyncValue<Challenge?> submission;

  bool get isSubmitting => submission.isLoading;

  bool get hasSelection =>
      isCustom ? customTitle.trim().isNotEmpty : template != null;

  bool get canSubmit => categoryId != null && hasSelection && !isSubmitting;

  CreateChallengeState copyWith({
    int? categoryId,
    ChallengeTemplate? template,
    bool clearTemplate = false,
    String? customTitle,
    bool? isCustom,
    AsyncValue<Challenge?>? submission,
  }) {
    return CreateChallengeState(
      categoryId: categoryId ?? this.categoryId,
      template: clearTemplate ? null : (template ?? this.template),
      customTitle: customTitle ?? this.customTitle,
      isCustom: isCustom ?? this.isCustom,
      submission: submission ?? this.submission,
    );
  }
}

class CreateChallengeController extends Notifier<CreateChallengeState> {
  @override
  CreateChallengeState build() => const CreateChallengeState();

  /// Switching category invalidates a template picked from the previous one.
  void selectCategory(int categoryId) {
    if (state.categoryId == categoryId) return;
    state = state.copyWith(
      categoryId: categoryId,
      clearTemplate: true,
      isCustom: false,
    );
  }

  void selectTemplate(ChallengeTemplate template) {
    state = state.copyWith(template: template, isCustom: false);
  }

  void useCustom() {
    state = state.copyWith(isCustom: true, clearTemplate: true);
  }

  void setCustomTitle(String title) {
    state = state.copyWith(customTitle: title, isCustom: true);
  }

  /// Returns the created challenge, or null when the API rejected it — the
  /// failure stays on [CreateChallengeState.submission] for the screen to show.
  Future<Challenge?> submit() async {
    if (!state.canSubmit) return null;

    final ChallengeTemplate? template = state.template;
    state = state.copyWith(submission: const AsyncValue<Challenge?>.loading());

    final AsyncValue<Challenge?> result = await AsyncValue.guard<Challenge?>(
      () async {
        final Challenge created = await ref
            .read(challengeRepositoryProvider)
            .createChallenge(
              title: state.isCustom
                  ? state.customTitle.trim()
                  : template!.title,
              description: state.isCustom ? null : template!.description,
              difficulty: state.isCustom ? null : template!.difficulty,
              durationDays: state.isCustom ? null : template!.durationDays,
              categoryId: state.categoryId,
            );
        // Activate immediately so Home can lead with it — create alone leaves
        // a draft that the dashboard ignores.
        return ref
            .read(challengeRepositoryProvider)
            .activateChallenge(created.id);
      },
    );

    state = state.copyWith(submission: result);

    if (result.hasError) return null;

    ref.invalidate(challengeListControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    return result.value;
  }
}

final NotifierProvider<CreateChallengeController, CreateChallengeState>
createChallengeControllerProvider =
    NotifierProvider<CreateChallengeController, CreateChallengeState>(
      CreateChallengeController.new,
    );
