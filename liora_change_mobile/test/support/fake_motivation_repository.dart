import 'package:liora_change_mobile/features/motivation/data/motivation_repository.dart';
import 'package:liora_change_mobile/models/enums.dart';
import 'package:liora_change_mobile/models/motivation.dart';

/// In-memory stand-in for `POST /ai/motivation`.
class FakeMotivationRepository implements MotivationRepository {
  FakeMotivationRepository({this.messages = const <String>['Keep walking.']});

  /// Handed out in order, so a regenerate returns something new.
  List<String> messages;
  MotivationSource source = MotivationSource.openai;
  Object? error;
  Duration? delay;

  int calls = 0;
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];

  @override
  Future<Motivation> getMotivation({
    required int challengeId,
    MotivationContext? context,
  }) async {
    requests.add(<String, Object?>{
      'challenge_id': challengeId,
      'context': context?.wire,
    });
    final int index = calls++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;

    return Motivation(
      message: messages[index % messages.length],
      tone: MotivationTone.encouraging,
      source: source,
      challengeId: challengeId,
      challengeTitle: 'Morning Walk',
    );
  }
}
