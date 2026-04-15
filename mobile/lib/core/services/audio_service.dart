import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

/// Handles microphone recording and audio playback throughout the app.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _currentRecordingPath;

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasMicPermission() async {
    return Permission.microphone.isGranted;
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) {
      return false;
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentRecordingPath = '${dir.path}/recording_$timestamp.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: _currentRecordingPath!,
    );

    return true;
  }

  /// Stops recording and returns the [File] on disk.
  Future<File?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    _currentRecordingPath = null;
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) return null;
    return file;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  // ── Playback ──────────────────────────────────────────────────────────────

  Future<void> playFile(String filePath) async {
    await _player.setFilePath(filePath);
    await _player.play();
  }

  Future<void> playUrl(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<void> pausePlayback() async {
    await _player.pause();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
