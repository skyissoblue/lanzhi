import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_state.dart';
import '../widgets/condition_chip.dart';
import '../widgets/stock_list_item.dart';
import '../widgets/voice_button.dart';
import 'kline_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _controller = TextEditingController();
  String? _recognizedText;
  bool _transcribing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sessionProvider.notifier).initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(sessionProvider.notifier).submitText(text);
  }

  Future<void> _startVoice() async {
    try {
      await ref.read(voiceServiceProvider).startRecording();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _stopVoice() async {
    setState(() => _transcribing = true);
    try {
      final text = await ref.read(voiceServiceProvider).stopAndTranscribe();
      if (text.isEmpty) throw StateError('没有识别到语音内容');
      if (!mounted) return;
      setState(() => _recognizedText = text);
      _controller.text = text;
      await ref.read(sessionProvider.notifier).submitText(text);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('语音识别失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('澜知选股'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前股票池', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${state.total} 只',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF126B4D),
                    ),
                  ),
                  if (state.conditions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (
                            var index = 0;
                            index < state.conditions.length;
                            index++
                          )
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ConditionTag(
                                condition: state.conditions[index],
                                onDeleted: state.loading
                                    ? null
                                    : () => ref
                                          .read(sessionProvider.notifier)
                                          .removeCondition(index),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (state.error != null)
              MaterialBanner(
                content: Text(state.error!),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('知道了')),
                ],
              ),
            Expanded(
              child: state.loading && state.stocks.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: ListView.separated(
                        key: ValueKey(state.revision),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.stocks.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final stock = state.stocks[index];
                          return StockListItem(
                            stock: stock,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => KlinePage(
                                  stockCode: stock.code,
                                  stockName: stock.name,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                10 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: '例如：选出科技股里站上10周线的',
                        prefixIcon: const Icon(Icons.mic_none),
                        filled: true,
                        fillColor: const Color(0xFFF1F4F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  VoiceButton(
                    enabled: !state.loading && !_transcribing,
                    onRecordStart: _startVoice,
                    onRecordEnd: _stopVoice,
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: state.loading ? null : _submit,
                    icon: state.loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
            if (_recognizedText != null || _transcribing)
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  _transcribing ? '正在使用 Whisper 识别…' : '识别文字：$_recognizedText',
                  key: const ValueKey('recognized-text'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
