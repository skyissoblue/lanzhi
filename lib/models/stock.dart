import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false, createToJson: false)
class Stock {
  const Stock({
    required this.code,
    required this.name,
    this.industry,
    this.board,
  });

  final String code;
  final String name;
  final String? industry;
  final String? board;

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    industry: json['industry']?.toString(),
    board: json['board']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    if (industry != null) 'industry': industry,
    if (board != null) 'board': board,
  };
}
