import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/app_error.dart';
import '../services/voice_service.dart';
import 'selection_combo.dart';

class ComboState {
  const ComboState({
    this.combos = const [],
    this.currentSessionId,
    this.loading = false,
    this.error,
    this.lastBefore,
    this.lastRemoved,
    this.revision = 0,
  });
  final List<SelectionCombo> combos;
  final String? currentSessionId;
  final bool loading;
  final String? error;
  final int? lastBefore;
  final int? lastRemoved;
  final int revision;

  SelectionCombo? get current {
    for (final combo in combos) {
      if (combo.sessionId == currentSessionId) return combo;
    }
    return null;
  }

  ComboState copyWith({
    List<SelectionCombo>? combos,
    String? currentSessionId,
    bool clearCurrent = false,
    bool? loading,
    String? error,
    bool clearError = false,
    int? lastBefore,
    int? lastRemoved,
    bool clearStats = false,
    int? revision,
  }) => ComboState(
    combos: combos ?? this.combos,
    currentSessionId: clearCurrent
        ? null
        : currentSessionId ?? this.currentSessionId,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    lastBefore: clearStats ? null : lastBefore ?? this.lastBefore,
    lastRemoved: clearStats ? null : lastRemoved ?? this.lastRemoved,
    revision: revision ?? this.revision,
  );
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(service.dispose);
  return service;
});
final sessionProvider = StateNotifierProvider<ComboController, ComboState>(
  (ref) => ComboController(ref.read(apiServiceProvider)),
);

class ComboController extends StateNotifier<ComboState> {
  ComboController(this._api) : super(const ComboState());
  final ApiService _api;

  Future<void> initialize() async {
    if (state.loading || state.currentSessionId != null) return;
    await _guard(() async {
      var combos = await _api.getSessions();
      if (combos.isEmpty) combos = [await _api.createSession('组合1')];
      state = state.copyWith(
        combos: combos,
        currentSessionId: combos.first.sessionId,
      );
      await _loadCurrent();
    });
  }

  Future<void> createCombo(String name, {String? assetType}) =>
      _guard(() async {
        final type = assetType ?? state.current?.assetType ?? 'stock';
        final combo = await _api.createSession(name.trim(), type);
        state = state.copyWith(
          combos: [...state.combos, combo],
          currentSessionId: combo.sessionId,
          clearStats: true,
        );
      });

  Future<void> switchAssetType(String assetType) => _guard(() async {
    if (assetType != 'stock' && assetType != 'etf') return;
    for (final combo in state.combos) {
      if (combo.assetType == assetType) {
        state = state.copyWith(
          currentSessionId: combo.sessionId,
          clearStats: true,
        );
        await _loadCurrent();
        return;
      }
    }
    final name = assetType == 'etf' ? 'ETF组合' : '股票组合';
    final combo = await _api.createSession(name, assetType);
    state = state.copyWith(
      combos: [...state.combos, combo],
      currentSessionId: combo.sessionId,
      clearStats: true,
    );
  });

  Future<void> switchCombo(String sessionId) => _guard(() async {
    state = state.copyWith(currentSessionId: sessionId, clearStats: true);
    await _loadCurrent();
  });

  Future<void> reloadCurrent() => _guard(_loadCurrent);

  Future<void> submitText(String text) => _guard(() async {
    final combo = state.current;
    if (combo == null || text.trim().isEmpty) return;
    final result = await _api.parseAndApply(combo.sessionId, text.trim());
    if (result.action == 'error') throw StateError(result.message ?? '条件解析失败');
    final conditions =
        result.appliedConditions ??
        [
          ...combo.conditions,
          ...result.conditions,
          if (result.conditions.isEmpty && result.condition != null)
            result.condition!,
        ];
    _replaceCurrent(
      combo.copyWith(
        conditions: conditions,
        currentCount: result.after,
        stocks: conditions.isEmpty ? const [] : result.stocks,
      ),
      before: result.before,
      removed: result.removed,
    );
  });

  Future<void> removeCondition(int index) => _guard(() async {
    final combo = state.current;
    if (combo == null || index < 0 || index >= combo.conditions.length) return;
    final result = await _api.removeCondition(combo.sessionId, index);
    final conditions = [...combo.conditions]..removeAt(index);
    _replaceCurrent(
      combo.copyWith(
        conditions: conditions,
        currentCount: result.after,
        stocks: conditions.isEmpty ? const [] : result.stocks,
      ),
      before: result.before,
      removed: result.removed,
    );
  });

  Future<void> resetCombo() => _guard(() async {
    final combo = state.current;
    if (combo == null) return;
    await _api.resetSession(combo.sessionId);
    _replaceCurrent(
      combo.copyWith(
        conditions: const [],
        currentCount: combo.total,
        stocks: const [],
      ),
      clearStats: true,
    );
  });

  Future<void> renameCombo(String name) => _guard(() async {
    final combo = state.current;
    if (combo == null || name.trim().isEmpty) return;
    _replaceCurrent(
      combo.copyWith(
        name: await _api.renameSession(combo.sessionId, name.trim()),
      ),
    );
  });

  Future<void> toggleFavorite() => _guard(() async {
    final combo = state.current;
    if (combo == null) return;
    final favorite = await _api.favoriteCombo(
      combo.sessionId,
      !combo.isFavorite,
    );
    _replaceCurrent(combo.copyWith(isFavorite: favorite));
  });

  Future<void> addToWatchlist(String code, String name) => _guard(() async {
    final combo = state.current;
    if (combo == null) return;
    await _api.addWatchlist(code, name, combo.sessionId);
  });

  Future<void> deleteCombo(String sessionId) => _guard(() async {
    await _api.dropSession(sessionId);
    var combos = state.combos
        .where((item) => item.sessionId != sessionId)
        .toList();
    if (combos.isEmpty) combos = [await _api.createSession('组合1')];
    state = state.copyWith(
      combos: combos,
      currentSessionId: combos.first.sessionId,
      clearStats: true,
    );
    await _loadCurrent();
  });

  Future<void> _loadCurrent() async {
    final id = state.currentSessionId;
    if (id == null) return;
    final detail = await _api.getSession(id);
    _replaceCurrent(
      detail.copyWith(
        stocks: detail.conditions.isEmpty ? const [] : detail.stocks,
      ),
    );
  }

  void _replaceCurrent(
    SelectionCombo combo, {
    int? before,
    int? removed,
    bool clearStats = false,
  }) {
    state = state.copyWith(
      combos: [
        for (final item in state.combos)
          if (item.sessionId == combo.sessionId) combo else item,
      ],
      lastBefore: before,
      lastRemoved: removed,
      clearStats: clearStats,
      revision: state.revision + 1,
    );
  }

  Future<void> _guard(Future<void> Function() operation) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await operation();
      state = state.copyWith(loading: false);
    } catch (error) {
      state = state.copyWith(
        loading: false,
        error: friendlyErrorMessage(error),
      );
    }
  }
}
