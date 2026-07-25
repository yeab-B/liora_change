import 'enums.dart';

/// `Motivation` from `docs/mvp/teams/SHARED-DATA-CONTRACT.md` §3.14.
class Motivation {
  const Motivation({
    required this.message,
    this.tone = MotivationTone.encouraging,
    this.source = MotivationSource.template,
    this.challengeId,
    this.challengeTitle,
  });

  final String message;
  final MotivationTone tone;

  /// `openai` or the template fallback. Never surfaced in the UI.
  final MotivationSource source;
  final int? challengeId;
  final String? challengeTitle;

  factory Motivation.fromJson(Map<String, dynamic> json) {
    return Motivation(
      message: json['message'] as String? ?? '',
      tone: MotivationTone.fromWire(json['tone']),
      source: MotivationSource.fromWire(json['source']),
      challengeId: json['challenge_id'] as int?,
      challengeTitle: json['challenge_title'] as String?,
    );
  }
}
