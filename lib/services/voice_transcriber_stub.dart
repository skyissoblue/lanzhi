import 'voice_transcriber.dart';

VoiceTranscriber createTranscriber() => UnsupportedVoiceTranscriber();

class UnsupportedVoiceTranscriber implements VoiceTranscriber {
  @override
  Future<String> transcribe(String audioPath) {
    throw UnsupportedError('当前平台不支持本地 Whisper，请使用 Android 或 iOS App');
  }
}
