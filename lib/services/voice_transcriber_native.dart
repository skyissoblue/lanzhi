import 'package:whisper_kit/whisper_kit.dart';

import 'voice_transcriber.dart';

VoiceTranscriber createTranscriber() => WhisperTinyTranscriber();

class WhisperTinyTranscriber implements VoiceTranscriber {
  WhisperTinyTranscriber({Whisper? whisper})
      : _whisper = whisper ?? const Whisper(model: WhisperModel.tiny);

  final Whisper _whisper;

  @override
  Future<String> transcribe(String audioPath) async {
    final result = await _whisper.transcribe(
      transcribeRequest: TranscribeRequest(
        audio: audioPath,
        language: 'zh',
        isNoTimestamps: true,
      ),
    );
    return result.text.trim();
  }
}
