import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/selection_combo.dart';
import '../models/session_state.dart';
import '../widgets/condition_chip.dart';
import '../widgets/stock_result_list.dart';
import '../widgets/voice_button.dart';
import 'kline_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _controller = TextEditingController();
  int _tabIndex = 0;
  bool _transcribing = false;
  String? _recognizedText;

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

  Future<String?> _askName(String title, [String initial = '']) async {
    final input = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: input, autofocus: true, maxLength: 40),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    input.dispose();
    return value?.trim().isEmpty == true ? null : value;
  }

  Future<void> _newCombo() async {
    final name = await _askName(
      '新建选股组合',
      '组合${ref.read(sessionProvider).combos.length + 1}',
    );
    if (name != null) {
      await ref.read(sessionProvider.notifier).createCombo(name);
    }
  }

  Future<void> _comboMenu(SelectionCombo combo) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('重命名'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('删除组合'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'rename') {
      final name = await _askName('重命名组合', combo.name);
      if (name != null) {
        await ref.read(sessionProvider.notifier).renameCombo(name);
      }
    } else if (action == 'delete') {
      await ref.read(sessionProvider.notifier).deleteCombo(combo.sessionId);
    }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> _stopVoice() async {
    setState(() => _transcribing = true);
    try {
      final text = await ref.read(voiceServiceProvider).stopAndTranscribe();
      if (text.trim().isEmpty) throw StateError('未识别到文字，请重试');
      if (!mounted) return;
      setState(() => _recognizedText = text);
      await ref.read(sessionProvider.notifier).submitText(text);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('语音识别失败：$error')));
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
        title: Text(['组合选股', '自选股', '行情'][_tabIndex]),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _tabIndex == 0
          ? _selectionBody(state)
          : const Center(child: Text('敬请期待')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.filter_alt_outlined),
            selectedIcon: Icon(Icons.filter_alt),
            label: '选股',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: '自选股',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            label: '行情',
          ),
        ],
      ),
    );
  }

  Widget _selectionBody(ComboState state) {
    final combo = state.current;
    return SafeArea(
      child: Column(
        children: [
          _comboTabs(state),
          if (state.error != null)
            MaterialBanner(
              content: Text(state.error!),
              actions: [
                TextButton(
                  onPressed: () =>
                      ref.read(sessionProvider.notifier).initialize(),
                  child: const Text('重试'),
                ),
              ],
            ),
          if (combo != null) _resultHeader(combo, state),
          if (combo != null) _conditionArea(combo, state),
          Expanded(child: _results(combo, state)),
          _inputBar(state),
        ],
      ),
    );
  }

  Widget _comboTabs(ComboState state) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
    child: Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final combo in state.combos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onLongPress: () => _comboMenu(combo),
                      child: ChoiceChip(
                        key: ValueKey('combo-${combo.sessionId}'),
                        label: Text('${combo.name} · ${combo.currentCount}'),
                        selected: combo.sessionId == state.currentSessionId,
                        onSelected: state.loading
                            ? null
                            : (_) => ref
                                  .read(sessionProvider.notifier)
                                  .switchCombo(combo.sessionId),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('add-combo'),
          onPressed: state.loading ? null : _newCombo,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: '新建组合',
        ),
      ],
    ),
  );

  Widget _resultHeader(SelectionCombo combo, ComboState state) => Container(
    width: double.infinity,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '全市场 ${combo.total}  →  当前',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  '${combo.currentCount} 只',
                  key: ValueKey(combo.currentCount),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF126B4D),
                  ),
                ),
              ),
              if (state.lastRemoved != null)
                Text(
                  '本次筛掉 ${state.lastRemoved} 只',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (combo.conditions.isNotEmpty)
          TextButton.icon(
            onPressed: state.loading
                ? null
                : () => ref.read(sessionProvider.notifier).resetCombo(),
            icon: const Icon(Icons.restart_alt),
            label: const Text('清空条件'),
          ),
      ],
    ),
  );

  Widget _conditionArea(SelectionCombo combo, ComboState state) => Container(
    width: double.infinity,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
    child: combo.conditions.isEmpty
        ? const Text('还没有条件，用语音或文字加一个吧', key: ValueKey('empty-conditions'))
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < combo.conditions.length; index++)
                ConditionTag(
                  condition: combo.conditions[index],
                  onDeleted: state.loading
                      ? null
                      : () => ref
                            .read(sessionProvider.notifier)
                            .removeCondition(index),
                ),
            ],
          ),
  );

  Widget _results(SelectionCombo? combo, ComboState state) {
    if (combo == null || state.loading && state.combos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: StockResultList(
        hasConditions: combo.conditions.isNotEmpty,
        stocks: combo.stocks,
        loading: state.loading,
        revision: state.revision,
        onStockTap: (stock) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                KlinePage(stockCode: stock.code, stockName: stock.name),
          ),
        ),
      ),
    );
  }

  Widget _inputBar(ComboState state) => Container(
    color: Colors.white,
    padding: EdgeInsets.fromLTRB(
      12,
      10,
      12,
      10 + MediaQuery.paddingOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_transcribing || _recognizedText != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _transcribing ? '正在识别…' : '识别文字：$_recognizedText',
              key: const ValueKey('recognized-text'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Row(
          children: [
            VoiceButton(
              enabled: !state.loading && !_transcribing,
              onRecordStart: _startVoice,
              onRecordEnd: _stopVoice,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !state.loading,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '例如：创业板站上10周线RPS>87',
                  filled: true,
                  fillColor: const Color(0xFFF1F4F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
      ],
    ),
  );
}
