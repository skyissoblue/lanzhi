import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/voice_service.dart';
import 'condition.dart';
import 'stock.dart';

class SessionState {
  const SessionState({
    this.sessionId,
    this.total = 0,
    this.stocks = const [],
    this.conditions = const [],
    this.loading = false,
    this.error,
    this.revision = 0,
  });

  final String? sessionId;
  final int total;
  final List<Stock> stocks;
  final List<Condition> conditions;
  final bool loading;
  final String? error;
  final int revision;

  SessionState copyWith({
    String? sessionId,
    int? total,
    List<Stock>? stocks,
    List<Condition>? conditions,
    bool? loading,
    String? error,
    bool clearError = false,
    int? revision,
  }) => SessionState(
    sessionId: sessionId ?? this.sessionId,
    total: total ?? this.total,
    stocks: stocks ?? this.stocks,
    conditions: conditions ?? this.conditions,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    revision: revision ?? this.revision,
  );
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(service.dispose);
  return service;
});

final sessionProvider = StateNotifierProvider<SessionController, SessionState>(
  (ref) => SessionController(ref.read(apiServiceProvider)),
);

class SessionController extends StateNotifier<SessionState> {
  SessionController(this._api) : super(const SessionState());

  final ApiService _api;

  Future<void> initialize() async {
    if (state.loading || state.sessionId != null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final sessionId = await _api.createSession();
      final stocks = await _api.getStocks(sessionId, 1, 100);
      state = state.copyWith(
        sessionId: sessionId,
        total: _api.lastSessionTotal,
        stocks: stocks,
        loading: false,
        revision: state.revision + 1,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> submitText(String text) async {
    var sessionId = state.sessionId;
    if (sessionId == null || text.trim().isEmpty || state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      StepResult result;
      try {
        result = await _api.parseAndApply(sessionId, text.trim());
      } catch (error) {
        if (!_api.isSessionMissing(error)) rethrow;
        sessionId = await _restoreSession();
        result = await _api.parseAndApply(sessionId, text.trim());
      }
      if (result.action == 'error') {
        throw StateError(result.message ?? '条件解析失败');
      }
      final conditions = result.appliedConditions ?? [...state.conditions];
      if (result.appliedConditions == null && result.action == 'add') {
        if (result.conditions.isNotEmpty) {
          conditions.addAll(result.conditions);
        } else if (result.condition != null) {
          conditions.add(result.condition!);
        }
      } else if (result.appliedConditions == null &&
          result.action == 'remove_last' &&
          conditions.isNotEmpty) {
        conditions.removeLast();
      } else if (result.appliedConditions == null && result.action == 'reset') {
        conditions.clear();
      }
      state = state.copyWith(
        sessionId: sessionId,
        total: result.after,
        stocks: result.stocks,
        conditions: conditions,
        loading: false,
        revision: state.revision + 1,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<String> _restoreSession() async {
    final sessionId = await _api.createSession();
    for (final condition in state.conditions) {
      await _api.applyCondition(sessionId, condition);
    }
    return sessionId;
  }

  Future<void> removeCondition(int index) async {
    var sessionId = state.sessionId;
    if (sessionId == null || index < 0 || index >= state.conditions.length) {
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final original = [...state.conditions];
      StepResult? result;
      try {
        result = await _removeAt(sessionId, index, original);
      } catch (error) {
        if (!_api.isSessionMissing(error)) rethrow;
        sessionId = await _restoreSession();
        result = await _removeAt(sessionId, index, original);
      }
      final remaining = [...original]..removeAt(index);
      state = state.copyWith(
        sessionId: sessionId,
        total: result?.after ?? state.total,
        stocks: result?.stocks ?? state.stocks,
        conditions: remaining,
        loading: false,
        revision: state.revision + 1,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<StepResult?> _removeAt(
    String sessionId,
    int index,
    List<Condition> original,
  ) async {
    StepResult? result;
    for (var cursor = original.length - 1; cursor >= index; cursor--) {
      result = await _api.removeLast(sessionId);
    }
    for (final condition in original.skip(index + 1)) {
      result = await _api.applyCondition(sessionId, condition);
    }
    return result;
  }
}
