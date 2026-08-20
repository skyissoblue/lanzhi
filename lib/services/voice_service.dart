import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'voice_transcriber.dart';

export 'voice_transcriber.dart' show VoiceTranscriber;

abstract interface class AudioCapture {
  Future<void> start(String path);
  Future<String> stop();
  Future<void> dispose();
}

class RecordAudioCapture implements AudioCapture {
  RecordAudioCapture([AudioRecorder? recorder])
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<void> start(String path) async {
    if (!await _recorder.hasPermission()) {
      throw StateError('没有麦克风权限');
    }
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  @override
  Future<String> stop() async {
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) throw StateError('未生成录音文件');
    return path;
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

class VoiceService {
  VoiceService({AudioCapture? capture, VoiceTranscriber? transcriber})
    : _capture = capture ?? RecordAudioCapture(),
      _transcriber = transcriber ?? createDefaultTranscriber();

  final AudioCapture _capture;
  final VoiceTranscriber _transcriber;
  String? _recordingPath;

  Future<void> startRecording() async {
    final directory = await getTemporaryDirectory();
    final path = p.join(
      directory.path,
      'voice_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    _recordingPath = path;
    await _capture.start(path);
  }

  Future<String> stopRecording() async {
    final path = await _capture.stop();
    _recordingPath = path;
    return path;
  }

  Future<String> transcribe(String audioPath) =>
      _transcriber.transcribe(audioPath);

  Future<String> stopAndTranscribe() async => transcribe(await stopRecording());

  String? get recordingPath => _recordingPath;

  Future<void> dispose() => _capture.dispose();
}
