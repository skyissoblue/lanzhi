import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false, createToJson: false)
class Stock {
  const Stock({
    required this.code,
    required this.name,
    this.industry,
    this.board,
    this.close,
    this.rps250,
  });

  final String code;
  final String name;
  final String? industry;
  final String? board;
  final double? close;
  final double? rps250;

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    industry: json['industry']?.toString(),
    board: json['board']?.toString(),
    close: (json['close'] as num?)?.toDouble(),
    rps250: (json['rps_250'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    if (industry != null) 'industry': industry,
    if (board != null) 'board': board,
    if (close != null) 'close': close,
    if (rps250 != null) 'rps_250': rps250,
  };
}
