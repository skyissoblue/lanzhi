import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false, createToJson: false)
class Condition {
  const Condition({required this.type, this.op, this.value});

  final String type;
  final String? op;
  final Object? value;

  factory Condition.fromJson(Map<String, dynamic> json) => Condition(
    type: json['type']?.toString() ?? '',
    op: json['op']?.toString(),
    value: json['value'],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    if (op != null) 'op': op,
    if (value != null) 'value': value,
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
    };
    if (type == 'ma_cross_weekly' ||
        type == 'macd_cross' ||
        type == 'kdj_cross') {
      return names[type] ?? type;
    }
    if (type == 'ma_deviation_weekly') return '周线偏离 ≤ $value%';
    return [
      names[type] ?? type,
      op,
      value?.toString(),
    ].whereType<String>().join(' ');
  }
}
