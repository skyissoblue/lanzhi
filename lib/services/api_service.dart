import 'package:dio/dio.dart';

import '../models/condition.dart';
import '../models/stock.dart';

class StepResult {
  const StepResult({
    required this.before,
    required this.after,
    required this.removed,
    required this.stocks,
    this.action,
    this.condition,
    this.message,
  });

  final int before;
  final int after;
  final int removed;
  final List<Stock> stocks;
  final String? action;
  final Condition? condition;
  final String? message;

  factory StepResult.fromJson(Map<String, dynamic> json) => StepResult(
    before: (json['before'] as num?)?.toInt() ?? 0,
    after: (json['after'] as num?)?.toInt() ?? 0,
    removed: (json['removed'] as num?)?.toInt() ?? 0,
    stocks: (json['stocks'] as List<dynamic>? ?? const [])
        .map((item) => Stock.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    action: json['action']?.toString(),
    condition: json['condition'] is Map
        ? Condition.fromJson(
            Map<String, dynamic>.from(json['condition'] as Map),
          )
        : null,
    message: json['message']?.toString(),
  );
}

class ApiService {
  ApiService({
    Dio? dio,
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  final Dio _dio;
  int lastSessionTotal = 0;

  Future<String> createSession() async {
    final response = await _dio.post<Map<String, dynamic>>('/api/session');
    final data = response.data ?? const {};
    lastSessionTotal = (data['total'] as num?)?.toInt() ?? 0;
    return data['session_id']?.toString() ?? '';
  }

  Future<StepResult> applyCondition(
    String sessionId,
    Condition condition,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/session/$sessionId/condition',
      data: condition.toJson(),
    );
    return StepResult.fromJson(response.data ?? const {});
  }

  Future<StepResult> removeLast(String sessionId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/session/$sessionId/condition/last',
    );
    return StepResult.fromJson(response.data ?? const {});
  }

  Future<List<Stock>> getStocks(String sessionId, int page, int size) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/session/$sessionId/stocks',
      queryParameters: {'page': page, 'size': size},
    );
    final items = response.data?['stocks'] as List<dynamic>? ?? const [];
    return items
        .map((item) => Stock.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<StepResult> parseAndApply(String sessionId, String text) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/session/$sessionId/parse-and-apply',
      data: {'text': text},
    );
    return StepResult.fromJson(response.data ?? const {});
  }
}
