import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Short push-to-talk WAV capture for Addis AI audio understanding.
class VoiceRecorder {
  VoiceRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _path;

  Future<bool> ensureMicPermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start() async {
    final bool allowed = await ensureMicPermission();
    if (!allowed) {
      throw StateError('Microphone permission was not granted.');
    }

    final Directory dir = await getTemporaryDirectory();
    _path =
        '${dir.path}/liora_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _path!,
    );
  }

  Future<Uint8List?> stop() async {
    final String? path = await _recorder.stop() ?? _path;
    _path = null;
    if (path == null) return null;
    final File file = File(path);
    if (!await file.exists()) return null;
    final Uint8List bytes = await file.readAsBytes();
    unawaited(file.delete().catchError((_) => file));
    return bytes;
  }

  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _path = null;
  }

  Future<void> dispose() => _recorder.dispose();
}
