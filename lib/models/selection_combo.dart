import 'condition.dart';
import 'stock.dart';

class SelectionCombo {
  const SelectionCombo({
    required this.sessionId,
    required this.name,
    this.conditions = const [],
    this.total = 0,
    this.currentCount = 0,
    this.stocks = const [],
  });

  final String sessionId;
  final String name;
  final List<Condition> conditions;
  final int total;
  final int currentCount;
  final List<Stock> stocks;

  factory SelectionCombo.fromJson(Map<String, dynamic> json) => SelectionCombo(
    sessionId: (json['session_id'] ?? json['sessionId'] ?? '').toString(),
    name: (json['name'] ?? '未命名组合').toString(),
    conditions: (json['conditions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Condition.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    total: (json['total'] as num?)?.toInt() ?? 0,
    currentCount:
        (json['current_count'] as num?)?.toInt() ??
        (json['currentCount'] as num?)?.toInt() ??
        0,
    stocks: (json['stocks'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Stock.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );

  SelectionCombo copyWith({
    String? name,
    List<Condition>? conditions,
    int? total,
    int? currentCount,
    List<Stock>? stocks,
  }) => SelectionCombo(
    sessionId: sessionId,
    name: name ?? this.name,
    conditions: conditions ?? this.conditions,
    total: total ?? this.total,
    currentCount: currentCount ?? this.currentCount,
    stocks: stocks ?? this.stocks,
  );
}
