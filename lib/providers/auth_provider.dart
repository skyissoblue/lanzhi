import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  const AuthState({
    this.ready = false,
    this.loggedIn = false,
    this.loading = false,
    this.user,
    this.error,
  });
  final bool ready, loggedIn, loading;
  final Map<String, dynamic>? user;
  final String? error;
}

final authServiceProvider = Provider((ref) => AuthService());
final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(authServiceProvider)),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service) : super(const AuthState());
  final AuthService _service;
  Future<void> initialize() async {
    final ok = await _service.restore();
    state = AuthState(ready: true, loggedIn: ok);
  }

  Future<void> login(
    String phone,
    String password, {
    String? nickname,
    bool register = false,
  }) async {
    state = const AuthState(ready: true, loading: true);
    try {
      final user = register
          ? await _service.register(phone, password, nickname ?? '')
          : await _service.login(phone, password);
      state = AuthState(ready: true, loggedIn: true, user: user);
    } catch (e) {
      state = AuthState(ready: true, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(ready: true);
  }
}
