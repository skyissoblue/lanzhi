import 'voice_transcriber_stub.dart'
    if (dart.library.io) 'voice_transcriber_native.dart'
    as implementation;

abstract interface class VoiceTranscriber {
  Future<String> transcribe(String audioPath);
}

VoiceTranscriber createDefaultTranscriber() =>
    implementation.createTranscriber();
