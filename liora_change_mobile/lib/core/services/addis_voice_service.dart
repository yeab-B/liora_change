import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/addis_coach_client.dart';
import '../config/demo_ai_config.dart';

enum AddisVoiceState { idle, loading, playing, error }

class AddisVoiceStatus {
  const AddisVoiceStatus({
    required this.state,
    this.currentText,
    this.errorMessage,
  });

  final AddisVoiceState state;
  final String? currentText;
  final String? errorMessage;
}

/// Speaks coach text through Addis AI TTS (Amharic when the text is Ethiopic).
class AddisVoiceController extends Notifier<AddisVoiceStatus> {
  late final AddisCoachClient _addis;
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;

  @override
  AddisVoiceStatus build() {
    _addis = AddisCoachClient();
    _playerSub = _player.onPlayerStateChanged.listen((PlayerState playerState) {
      if (playerState == PlayerState.completed) {
        state = const AddisVoiceStatus(state: AddisVoiceState.idle);
      }
    });
    ref.onDispose(() {
      unawaited(_playerSub?.cancel());
      unawaited(_player.dispose());
      _addis.close();
    });
    return const AddisVoiceStatus(state: AddisVoiceState.idle);
  }

  Future<void> play(String text) async {
    if (!DemoAiConfig.addisEnabled || text.trim().isEmpty) return;

    if (state.state == AddisVoiceState.playing && state.currentText == text) {
      await stop();
      return;
    }

    try {
      state = AddisVoiceStatus(
        state: AddisVoiceState.loading,
        currentText: text,
      );
      await _player.stop();

      final Uint8List audioBytes = await _addis.synthesize(text);
      await _player.play(BytesSource(audioBytes, mimeType: 'audio/wav'));

      state = AddisVoiceStatus(
        state: AddisVoiceState.playing,
        currentText: text,
      );
    } on Object catch (error) {
      state = AddisVoiceStatus(
        state: AddisVoiceState.error,
        currentText: text,
        errorMessage: error.toString(),
      );
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (state.currentText == text) {
          state = const AddisVoiceStatus(state: AddisVoiceState.idle);
        }
      });
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = const AddisVoiceStatus(state: AddisVoiceState.idle);
  }
}

final NotifierProvider<AddisVoiceController, AddisVoiceStatus>
addisVoiceProvider = NotifierProvider<AddisVoiceController, AddisVoiceStatus>(
  AddisVoiceController.new,
);
