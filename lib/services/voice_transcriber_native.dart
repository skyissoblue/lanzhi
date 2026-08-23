import 'api_service.dart';
import 'voice_transcriber.dart';

VoiceTranscriber createTranscriber() => ServerVoiceTranscriber();

class ServerVoiceTranscriber implements VoiceTranscriber {
  ServerVoiceTranscriber({ApiService? api}) : _api = api ?? ApiService();
  final ApiService _api;

  @override
  Future<String> transcribe(String audioPath) =>
      _api.transcribeAudio(audioPath);
}
