import 'enums.dart';

/// `Recovery` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.9.
///
/// Only [active] is guaranteed; when it is false the API sends
/// `{ "active": false }` and every other field is absent.
class Recovery {
  const Recovery({
    required this.active,
    this.challengeId,
    this.challengeTitle,
    this.reason,
    this.title,
    this.message,
    this.suggestedAction,
  });

  static const Recovery inactive = Recovery(active: false);

  final bool active;
  final int? challengeId;
  final String? challengeTitle;
  final RecoveryReason? reason;

  /// Short heading, e.g. "Yesterday does not cancel you".
  final String? title;
  final String? message;
  final SuggestedAction? suggestedAction;

  /// The dashboard may send `null` instead of an inactive object.
  factory Recovery.fromJson(Map<String, dynamic>? json) {
    if (json == null) return inactive;
    if (json['active'] != true) return inactive;

    final Object? action = json['suggested_action'];
    return Recovery(
      active: true,
      challengeId: json['challenge_id'] as int?,
      challengeTitle: json['challenge_title'] as String?,
      reason: RecoveryReason.fromWire(json['reason']),
      title: json['title'] as String?,
      message: json['message'] as String?,
      suggestedAction: action is Map<String, dynamic>
          ? SuggestedAction.fromJson(action)
          : null,
    );
  }
}

/// `SuggestedAction` from the contract's §3.10.
class SuggestedAction {
  const SuggestedAction({
    required this.type,
    required this.challengeId,
    required this.label,
  });

  final SuggestedActionType type;
  final int challengeId;
  final String label;

  factory SuggestedAction.fromJson(Map<String, dynamic> json) {
    return SuggestedAction(
      type: SuggestedActionType.fromWire(json['type']),
      challengeId: json['challenge_id'] as int,
      label: json['label'] as String? ?? 'Check in now',
    );
  }
}
