import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_stock_picker/services/voice_service.dart';
import 'package:voice_stock_picker/widgets/voice_button.dart';

class FakeCapture implements AudioCapture {
  bool stopped = false;

  @override
  Future<void> start(String path) async {}

  @override
  Future<String> stop() async {
    stopped = true;
    return '/tmp/voice.wav';
  }

  @override
  Future<void> dispose() async {}
}

class FakeTranscriber implements VoiceTranscriber {
  String? receivedPath;

  @override
  Future<String> transcribe(String audioPath) async {
    receivedPath = audioPath;
    return '选出科技股里站上十周线的';
  }
}

void main() {
  test('停止录音后调用 Whisper 并返回文字', () async {
    final capture = FakeCapture();
    final transcriber = FakeTranscriber();
    final service = VoiceService(capture: capture, transcriber: transcriber);

    final text = await service.stopAndTranscribe();

    expect(capture.stopped, isTrue);
    expect(transcriber.receivedPath, '/tmp/voice.wav');
    expect(text, '选出科技股里站上十周线的');
  });

  testWidgets('按住语音按钮触发录音开始和结束', (tester) async {
    var started = false;
    var ended = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceButton(
            onRecordStart: () async => started = true,
            onRecordEnd: () async => ended = true,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('voice-button'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(started, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(ended, isTrue);
  });
}
