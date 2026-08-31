import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_api.dart';

class AuthResult {
  final bool ok;
  final String message;
  const AuthResult({required this.ok, required this.message});
}

class AuthAccount {
  final String email;
  final String salt;
  final String passwordHash;
  const AuthAccount({required this.email, required this.salt, required this.passwordHash});
  Map<String, dynamic> toJson() => {'email': email, 'salt': salt, 'passwordHash': passwordHash};
  factory AuthAccount.fromJson(Map<String, dynamic> json) => AuthAccount(
        email: (json['email'] ?? '') as String,
        salt: (json['salt'] ?? '') as String,
        passwordHash: (json['passwordHash'] ?? '') as String,
      );
}

enum AccountMode { local, cloud }

/// Local accounts retain the old on-device format. Cloud auth uses an HttpOnly
/// cookie set by the same-origin API, so no JWT is persisted in preferences.
class AuthStore extends ChangeNotifier {
  static const _accountsKey = 'auth_accounts_v1';
  static const _sessionKey = 'auth_session_email_v1';
  static const _modeKey = 'auth_mode_v2';
  final CloudApi api;
  AuthStore({CloudApi? api}) : api = api ?? CloudApi();

  bool loaded = false;
  String? currentEmail;
  AccountMode mode = AccountMode.local;
  List<AuthAccount> _accounts = [];
  bool get isLoggedIn => currentEmail?.isNotEmpty ?? false;
  bool get isCloudUser => isLoggedIn && mode == AccountMode.cloud;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accounts = (prefs.getStringList(_accountsKey) ?? [])
        .map((item) => AuthAccount.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
    if (prefs.getString(_modeKey) == 'cloud') {
      mode = AccountMode.cloud;
      currentEmail = prefs.getString(_sessionKey);
      try {
        final session = await api.session();
        if (session != null) currentEmail = session.email;
        if (session == null) { mode = AccountMode.local; currentEmail = null; await prefs.remove(_modeKey); }
      } catch (_) { /* Offline: retain known cloud identity and retry on sync. */ }
    } else {
      currentEmail = prefs.getString(_sessionKey);
    }
    loaded = true;
    notifyListeners();
  }

  Future<AuthResult> registerCloud({required String email, required String password}) =>
      _cloud(() => api.register(email, password));
  Future<AuthResult> loginCloud({required String email, required String password}) =>
      _cloud(() => api.login(email, password));

  Future<AuthResult> _cloud(Future<CloudSession> Function() action) async {
    try {
      final session = await action();
      mode = AccountMode.cloud;
      currentEmail = session.email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, 'cloud');
      await prefs.setString(_sessionKey, session.email);
      notifyListeners();
      return const AuthResult(ok: true, message: '云端登录成功');
    } on CloudApiException catch (error) {
      return AuthResult(ok: false, message: error.message);
    }
  }

  Future<AuthResult> register({required String email, required String password}) async {
    final normalized = _normalizeEmail(email);
    final check = _validate(normalized, password);
    if (check != null) return AuthResult(ok: false, message: check);
    if (_find(normalized) != null) return const AuthResult(ok: false, message: '这个本地账号已经注册过，请直接登录');
    final salt = _randomSalt();
    _accounts.add(AuthAccount(email: normalized, salt: salt, passwordHash: _hashPassword(password, salt)));
    mode = AccountMode.local;
    currentEmail = normalized;
    await _persist();
    notifyListeners();
    return const AuthResult(ok: true, message: '本地账号已创建（仅此设备）');
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || password.isEmpty) return const AuthResult(ok: false, message: '请填写邮箱和密码');
    final account = _find(normalized);
    if (account == null) return const AuthResult(ok: false, message: '本机没有这个账号，请先创建本地账号');
    if (account.passwordHash != _hashPassword(password, account.salt)) return const AuthResult(ok: false, message: '密码不对');
    mode = AccountMode.local;
    currentEmail = normalized;
    await _persistSession();
    notifyListeners();
    return const AuthResult(ok: true, message: '本地登录成功');
  }

  Future<void> logout() async {
    if (mode == AccountMode.cloud) { try { await api.logout(); } catch (_) {} }
    currentEmail = null;
    mode = AccountMode.local;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modeKey);
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  AuthAccount? _find(String email) { for (final account in _accounts) { if (account.email == email) return account; } return null; }
  String _normalizeEmail(String email) => email.trim().toLowerCase();
  String? _validate(String email, String password) {
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) return '请填写有效邮箱';
    if (password.length < 6) return '密码至少 6 位';
    return null;
  }
  String _randomSalt() => base64UrlEncode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
  String _hashPassword(String password, String salt) => sha256.convert(utf8.encode('$salt::$password')).toString();
  Future<void> _persist() async { final prefs = await SharedPreferences.getInstance(); await prefs.setStringList(_accountsKey, _accounts.map((item) => jsonEncode(item.toJson())).toList()); await _persistSession(); }
  Future<void> _persistSession() async { final prefs = await SharedPreferences.getInstance(); if (currentEmail == null || currentEmail!.isEmpty) { await prefs.remove(_sessionKey); } else { await prefs.setString(_sessionKey, currentEmail!); } }
}
