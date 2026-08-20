import 'dart:math';

import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

import '../widgets/indicator_panel.dart';

class KlinePage extends StatefulWidget {
  const KlinePage({super.key, required this.stockCode, this.stockName});

  final String stockCode;
  final String? stockName;

  @override
  State<KlinePage> createState() => _KlinePageState();
}

class _KlinePageState extends State<KlinePage> {
  late final IndicatorController _indicators;
  late final List<KLineEntity> _data;

  @override
  void initState() {
    super.initState();
    _indicators = IndicatorController()..addListener(_refreshIndicators);
    _data = _sampleData();
    _calculate();
  }

  @override
  void dispose() {
    _indicators
      ..removeListener(_refreshIndicators)
      ..dispose();
    super.dispose();
  }

  List<MainIndicator> get _mainIndicators => [
    MAIndicator(calcParams: const [5, 10, 20]),
  ];

  List<SecondaryIndicator> get _secondaryIndicators => [
    if (_indicators.macd) MACDIndicator(),
    if (_indicators.kdj) KDJIndicator(),
    if (_indicators.rsi) RSIIndicator(),
  ];

  void _calculate() =>
      DataUtil.calculateAll(_data, _mainIndicators, _secondaryIndicators);

  void _refreshIndicators() {
    _calculate();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.stockName ?? '股票'} ${widget.stockCode}'),
      actions: [
        PopupMenuButton<String>(
          tooltip: '指标菜单',
          onSelected: (value) {
            switch (value) {
              case 'volume':
                _indicators.setVolume(!_indicators.volume);
              case 'macd':
                _indicators.setMacd(!_indicators.macd);
              case 'kdj':
                _indicators.setKdj(!_indicators.kdj);
              case 'rsi':
                _indicators.setRsi(!_indicators.rsi);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'volume', child: Text('显示/隐藏成交量')),
            PopupMenuItem(value: 'macd', child: Text('添加/移除 MACD')),
            PopupMenuItem(value: 'kdj', child: Text('添加/移除 KDJ')),
            PopupMenuItem(value: 'rsi', child: Text('添加/移除 RSI')),
          ],
        ),
      ],
    ),
    body: Column(
      children: [
        IndicatorPanel(controller: _indicators),
        Expanded(
          child: ColoredBox(
            key: const ValueKey('kline-chart'),
            color: Colors.white,
            child: KChartWidget(
              _data,
              const KChartStyle(),
              const KChartColors(),
              isTrendLine: false,
              mainIndicators: _mainIndicators,
              secondaryIndicators: _secondaryIndicators,
              volHidden: !_indicators.volume,
              mBaseHeight: 330,
              mSecondaryHeight: 90,
              isTapShowInfoDialog: true,
              detailBuilder: (entity) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '开 ${entity.open.toStringAsFixed(2)}  高 ${entity.high.toStringAsFixed(2)}  低 ${entity.low.toStringAsFixed(2)}  收 ${entity.close.toStringAsFixed(2)}',
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  List<KLineEntity> _sampleData() {
    final random = Random(widget.stockCode.hashCode);
    var close = 18.0 + random.nextDouble() * 12;
    final start = DateTime(2025, 1, 2);
    return List.generate(90, (index) {
      final open = close + (random.nextDouble() - .5) * 1.2;
      close = max(3, open + (random.nextDouble() - .48) * 1.6);
      final high = max(open, close) + random.nextDouble() * .8;
      final low = min(open, close) - random.nextDouble() * .8;
      return KLineEntity.fromCustom(
        open: open,
        close: close,
        high: high,
        low: low,
        vol: 800000 + random.nextDouble() * 3000000,
        amount: close * (800000 + random.nextDouble() * 3000000),
        time: start.add(Duration(days: index)).millisecondsSinceEpoch,
      );
    });
  }
}
