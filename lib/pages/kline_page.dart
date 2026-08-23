import 'dart:math';

import 'package:flutter/material.dart';
import 'package:k_chart_plus/k_chart_plus.dart';

import '../widgets/indicator_panel.dart';
import '../services/api_service.dart';

enum KlinePeriod { daily, weekly, monthly, yearly }

extension on KlinePeriod {
  String get label => switch (this) {
    KlinePeriod.daily => '日',
    KlinePeriod.weekly => '周',
    KlinePeriod.monthly => '月',
    KlinePeriod.yearly => '年',
  };
}

class _Bar {
  const _Bar({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.amount,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double amount;
}

class KlinePage extends StatefulWidget {
  const KlinePage({super.key, required this.stockCode, this.stockName});

  final String stockCode;
  final String? stockName;

  @override
  State<KlinePage> createState() => _KlinePageState();
}

class _KlinePageState extends State<KlinePage> {
  late final IndicatorController _indicators;
  late List<_Bar> _dailyBars;
  late List<KLineEntity> _data;
  KlinePeriod _period = KlinePeriod.daily;

  @override
  void initState() {
    super.initState();
    _indicators = IndicatorController()..addListener(_refreshIndicators);
    _dailyBars = _sampleDailyBars();
    _data = _entitiesFor(_period);
    _calculate();
    _loadRealBars();
  }

  Future<void> _loadRealBars() async {
    try {
      final rows = await ApiService().getKline(widget.stockCode);
      if (rows.isEmpty || !mounted) return;
      _dailyBars = rows
          .map(
            (row) => _Bar(
              time: DateTime.parse('${row['date']}'),
              open: (row['open'] as num).toDouble(),
              high: (row['high'] as num).toDouble(),
              low: (row['low'] as num).toDouble(),
              close: (row['close'] as num).toDouble(),
              volume: (row['volume'] as num?)?.toDouble() ?? 0,
              amount: (row['amount'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList();
      setState(() {
        _data = _entitiesFor(_period);
        _calculate();
      });
    } catch (_) {
      // Keep deterministic sample bars when local market data is unavailable.
    }
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

  void _setPeriod(KlinePeriod period) {
    if (_period == period) return;
    setState(() {
      _period = period;
      _data = _entitiesFor(period);
      _calculate();
    });
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
        Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('周期'),
                const SizedBox(width: 12),
                for (final period in KlinePeriod.values) ...[
                  ChoiceChip(
                    key: ValueKey('period-${period.name}'),
                    label: Text('${period.label}K'),
                    selected: _period == period,
                    onSelected: (_) => _setPeriod(period),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        IndicatorPanel(controller: _indicators),
        Expanded(
          child: ColoredBox(
            key: ValueKey('kline-chart-${_period.name}'),
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

  List<_Bar> _sampleDailyBars() {
    final random = Random(widget.stockCode.hashCode);
    var close = 18.0 + random.nextDouble() * 12;
    var date = DateTime(2018, 1, 2);
    return List.generate(2200, (index) {
      while (date.weekday > DateTime.friday) {
        date = date.add(const Duration(days: 1));
      }
      final open = close + (random.nextDouble() - .5) * 1.2;
      close = max(3, open + (random.nextDouble() - .48) * 1.6);
      final high = max(open, close) + random.nextDouble() * .8;
      final low = min(open, close) - random.nextDouble() * .8;
      final volume = 800000 + random.nextDouble() * 3000000;
      final bar = _Bar(
        time: date,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
        amount: close * volume,
      );
      date = date.add(const Duration(days: 1));
      return bar;
    });
  }

  List<KLineEntity> _entitiesFor(KlinePeriod period) =>
      _aggregate(_dailyBars, period)
          .map(
            (bar) => KLineEntity.fromCustom(
              open: bar.open,
              close: bar.close,
              high: bar.high,
              low: bar.low,
              vol: bar.volume,
              amount: bar.amount,
              time: bar.time.millisecondsSinceEpoch,
            ),
          )
          .toList();

  List<_Bar> _aggregate(List<_Bar> daily, KlinePeriod period) {
    if (period == KlinePeriod.daily) return daily;
    final result = <_Bar>[];
    for (final bar in daily) {
      final key = switch (period) {
        KlinePeriod.daily =>
          '${bar.time.year}-${bar.time.month}-${bar.time.day}',
        KlinePeriod.weekly =>
          '${bar.time.year}-${bar.time.subtract(Duration(days: bar.time.weekday - 1)).month}-${bar.time.subtract(Duration(days: bar.time.weekday - 1)).day}',
        KlinePeriod.monthly => '${bar.time.year}-${bar.time.month}',
        KlinePeriod.yearly => '${bar.time.year}',
      };
      final previous = result.isEmpty ? null : result.last;
      final previousKey = previous == null
          ? null
          : switch (period) {
              KlinePeriod.daily =>
                '${previous.time.year}-${previous.time.month}-${previous.time.day}',
              KlinePeriod.weekly =>
                '${previous.time.year}-${previous.time.subtract(Duration(days: previous.time.weekday - 1)).month}-${previous.time.subtract(Duration(days: previous.time.weekday - 1)).day}',
              KlinePeriod.monthly =>
                '${previous.time.year}-${previous.time.month}',
              KlinePeriod.yearly => '${previous.time.year}',
            };
      if (previous == null || key != previousKey) {
        result.add(bar);
      } else {
        result[result.length - 1] = _Bar(
          time: bar.time,
          open: previous.open,
          high: max(previous.high, bar.high),
          low: min(previous.low, bar.low),
          close: bar.close,
          volume: previous.volume + bar.volume,
          amount: previous.amount + bar.amount,
        );
      }
    }
    return result;
  }
}
