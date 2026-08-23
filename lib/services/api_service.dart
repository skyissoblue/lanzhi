import 'package:dio/dio.dart';

import '../models/condition.dart';
import '../models/selection_combo.dart';
import '../models/stock.dart';

class StepResult {
  const StepResult({
    required this.before,
    required this.after,
    required this.removed,
    required this.stocks,
    this.action,
    this.condition,
    this.conditions = const [],
    this.appliedConditions,
    this.message,
  });

  final int before;
  final int after;
  final int removed;
  final List<Stock> stocks;
  final String? action;
  final Condition? condition;
  final List<Condition> conditions;
  final List<Condition>? appliedConditions;
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
    conditions: (json['conditions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Condition.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
    appliedConditions: json.containsKey('applied_conditions')
        ? (json['applied_conditions'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map(
                (item) => Condition.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
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
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthTokenStore.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  int lastSessionTotal = 0;

  Future<Map<String, dynamic>> register(
    String phone,
    String password,
    String? nickname,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {
        'phone': phone,
        'password': password,
        if (nickname?.isNotEmpty == true) 'nickname': nickname,
      },
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'phone': phone, 'password': password},
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
    return response.data ?? const {};
  }

  Future<List<Map<String, dynamic>>> groupedWatchlist() async {
    final response = await _dio.get<List<dynamic>>('/api/watchlist/by-combo');
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> removeWatchlist(String code) =>
      _dio.delete<void>('/api/watchlist/$code');

  Future<List<Map<String, dynamic>>> getKline(
    String code, {
    String period = 'daily',
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/stock/$code/kline',
      queryParameters: {'period': period},
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<String> transcribeAudio(String path) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/voice/transcribe',
      data: FormData.fromMap({
        'audio': await MultipartFile.fromFile(path, filename: 'recording.wav'),
      }),
    );
    return response.data?['text']?.toString().trim() ?? '';
  }

  Future<void> addWatchlist(String code, String name, String comboId) =>
      _dio.post<void>(
        '/api/watchlist',
        data: {
          'stock_code': code,
          'stock_name': name,
          'source_combo_id': int.parse(comboId),
        },
      );

  Future<bool> favoriteCombo(String comboId, bool favorite) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/combos/$comboId/favorite',
      data: {'favorite': favorite},
    );
    return response.data?['favorite'] == true;
  }

  Future<SelectionCombo> createSession([String? name]) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/combos',
      data: {'name': name ?? '默认组合'},
    );
    final data = response.data ?? const {};
    lastSessionTotal = (data['total'] as num?)?.toInt() ?? 0;
    return SelectionCombo.fromJson({
      ...data,
      'current_count': lastSessionTotal,
    });
  }

  Future<List<SelectionCombo>> getSessions() async {
    final response = await _dio.get<List<dynamic>>('/api/combos');
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => SelectionCombo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<SelectionCombo>> getFavoriteSessions() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/combos',
      queryParameters: {'favorite': true},
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => SelectionCombo.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<SelectionCombo> getSession(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/combos/$sessionId',
    );
    return SelectionCombo.fromJson(response.data ?? const {});
  }

  Future<String> renameSession(String sessionId, String name) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/combos/$sessionId',
      data: {'name': name},
    );
    return name;
  }

  Future<void> dropSession(String sessionId) async {
    await _dio.delete<void>('/api/combos/$sessionId');
  }

  Future<void> resetSession(String sessionId) async {
    await _dio.post<void>('/api/combos/$sessionId/reset');
  }

  Future<StepResult> applyCondition(
    String sessionId,
    Condition condition,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/combos/$sessionId/condition',
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

  Future<StepResult> removeCondition(String sessionId, int index) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/api/combos/$sessionId/condition/$index',
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
      '/api/combos/$sessionId/parse',
      data: {'text': text},
    );
    return StepResult.fromJson(response.data ?? const {});
  }

  bool isSessionMissing(Object error) =>
      error is DioException &&
      error.response?.statusCode == 404 &&
      (error.response?.data is! Map ||
          (error.response?.data as Map)['detail'] == 'session not found');
}

class AuthTokenStore {
  static String? token;
}
