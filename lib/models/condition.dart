import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false, createToJson: false)
class Condition {
  const Condition({
    required this.type,
    this.op,
    this.value,
    this.name,
    this.extra = const {},
  });

  final String type;
  final String? op;
  final Object? value;
  final String? name;
  final Map<String, dynamic> extra;

  factory Condition.fromJson(Map<String, dynamic> json) => Condition(
    type: json['type']?.toString() ?? '',
    op: json['op']?.toString(),
    value: json['value'],
    name: json['name']?.toString(),
    extra: Map<String, dynamic>.from(json)
      ..removeWhere(
        (key, _) => {'type', 'op', 'value', 'name'}.contains(key),
      ),
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (op != null) 'op': op,
    if (value != null) 'value': value,
    if (name != null) 'name': name,
    ...extra,
  };

  String get label {
    const names = {
      'industry': '行业',
      'board': '板块',
      'ma_cross_weekly': '站上10周线',
      'ma_deviation_weekly': '周线偏离',
      'rps': 'RPS',
      'volume_ratio': '量比',
      'market_cap': '市值',
      'pe': '市盈率',
      'macd_cross': 'MACD金叉',
      'kdj_cross': 'KDJ金叉',
      'exclude_st': '排除ST',
      'ma_cross': '均线条件',
      'ma_deviation': '均线偏离',
      'factor': '因子',
    };
    if (type == 'ma_cross_weekly' ||
        type == 'exclude_st' ||
        type == 'macd_cross' ||
        type == 'kdj_cross') {
      return names[type] ?? type;
    }
    if (type == 'ma_deviation_weekly') return '周线偏离 ≤ $value%';
    if (type == 'factor') {
      return [
        name ?? '因子',
        op,
        value?.toString(),
      ].whereType<String>().join(' ');
    }
    if (type == 'ma_cross') {
      final period = extra['period'] == 'weekly' ? '周' : '日';
      return extra['ma_fast'] != null
          ? 'MA${extra['ma_fast']} ${extra['cross'] == 'death' ? '死叉' : '金叉'} MA${extra['ma_slow']}'
          : '${extra['ma']}$period线 ${op ?? '>='}';
    }
    if (type == 'ma_deviation') {
      return '偏离MA${extra['ma']} ≤ ${extra['max_pct']}%';
    }
    return [
      names[type] ?? type,
      op,
      value?.toString(),
    ].whereType<String>().join(' ');
  }
}
