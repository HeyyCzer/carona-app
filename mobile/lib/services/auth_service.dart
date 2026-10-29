import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/carona_api.dart';
import '../api/models.dart';
import '../app/routes.dart';

/// Sessão do usuário: guarda o token JWT e os dados do usuário logado.
class AuthService extends GetxService {
  static const _tokenKey = 'auth.token';
  static const _userKey = 'auth.user';
  static const _expiresKey = 'auth.expiresAt';

  final CaronaApi api;
  final SharedPreferences prefs;

  final user = Rxn<User>();

  AuthService(this.api, this.prefs);

  bool get isLoggedIn => user.value != null;

  /// Usuário logado; só use em telas que exigem login.
  User get currentUser => user.value!;

  @override
  void onInit() {
    super.onInit();
    api.client.onUnauthorized = () {
      logout();
      Get.snackbar('Sessão expirada', 'Entre novamente para continuar.');
    };
    _restore();
  }

  void _restore() {
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    final expiresAt = prefs.getInt(_expiresKey) ?? 0;
    if (token == null || userJson == null || DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      _clear();
      return;
    }
    api.client.token = token;
    user.value = User.fromJson(jsonDecode(userJson));
    // Atualiza os dados em segundo plano; um 401 aqui derruba a sessão via onUnauthorized.
    api.me().then((fresh) {
      user.value = fresh;
      prefs.setString(_userKey, jsonEncode(fresh.toJson()));
    }).catchError((_) {});
  }

  Future<void> login(String email, String password) async {
    await _start(await api.login(email.trim(), password));
  }

  Future<void> register(String name, String email, String password) async {
    await _start(await api.register(name.trim(), email.trim(), password));
  }

  Future<void> _start(AuthResponse auth) async {
    api.client.token = auth.accessToken;
    final expiresAt = DateTime.now().add(Duration(seconds: auth.expiresIn)).millisecondsSinceEpoch;
    await prefs.setString(_tokenKey, auth.accessToken);
    await prefs.setString(_userKey, jsonEncode(auth.user.toJson()));
    await prefs.setInt(_expiresKey, expiresAt);
    user.value = auth.user;
  }

  void logout() {
    if (!isLoggedIn && api.client.token == null) return;
    _clear();
    Get.offAllNamed(Routes.login);
  }

  void _clear() {
    api.client.token = null;
    user.value = null;
    prefs.remove(_tokenKey);
    prefs.remove(_userKey);
    prefs.remove(_expiresKey);
  }
}

/// Mensagem de erro amigável para qualquer exceção vinda da API.
String errorMessage(Object error) => error is ApiException ? error.message : 'Algo deu errado. Tente de novo.';
