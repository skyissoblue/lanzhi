import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  AuthService({ApiService? api, FlutterSecureStorage? storage})
    : _api = api ?? ApiService(),
      _storage = storage ?? const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  final ApiService _api;
  final FlutterSecureStorage _storage;

  Future<bool> restore() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return false;
    AuthTokenStore.token = token;
    try {
      await _api.me();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String phone, String password) async =>
      _save(await _api.login(phone, password));
  Future<Map<String, dynamic>> register(
    String phone,
    String password,
    String nickname,
  ) async => _save(await _api.register(phone, password, nickname));
  Future<Map<String, dynamic>> _save(Map<String, dynamic> data) async {
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) throw StateError('服务器未返回登录令牌');
    AuthTokenStore.token = token;
    await _storage.write(key: _tokenKey, value: token);
    return data;
  }

  Future<void> logout() async {
    AuthTokenStore.token = null;
    await _storage.delete(key: _tokenKey);
  }
}
