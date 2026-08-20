import 'package:flutter/material.dart';

class VoiceButton extends StatefulWidget {
  const VoiceButton({
    super.key,
    required this.onRecordStart,
    required this.onRecordEnd,
    this.enabled = true,
  });

  final Future<void> Function() onRecordStart;
  final Future<void> Function() onRecordEnd;
  final bool enabled;

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!widget.enabled || _recording) return;
    setState(() => _recording = true);
    _animation.repeat(reverse: true);
    try {
      await widget.onRecordStart();
    } catch (_) {
      _finishVisual();
      rethrow;
    }
  }

  Future<void> _end() async {
    if (!_recording) return;
    _finishVisual();
    await widget.onRecordEnd();
  }

  void _finishVisual() {
    if (!mounted) return;
    _animation.stop();
    setState(() => _recording = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('voice-button'),
    onLongPressStart: widget.enabled ? (_) => _start() : null,
    onLongPressEnd: widget.enabled ? (_) => _end() : null,
    child: AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: 52 + (_recording ? _animation.value * 8 : 0),
        height: 52 + (_recording ? _animation.value * 8 : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _recording
              ? Colors.redAccent
              : Theme.of(context).colorScheme.primary,
          boxShadow: _recording
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: .3),
                    blurRadius: 14,
                    spreadRadius: 5 * _animation.value,
                  ),
                ]
              : null,
        ),
        child: Icon(
          _recording ? Icons.graphic_eq : Icons.mic,
          color: Colors.white,
        ),
      ),
    ),
  );
}
