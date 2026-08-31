import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CloudApiException implements Exception {
  final String message;
  final int? statusCode;
  const CloudApiException(this.message, {this.statusCode});
  @override String toString() => message;
}
class CloudConflictException extends CloudApiException { const CloudConflictException(super.message) : super(statusCode: 409); }
class CloudSession { final String email; const CloudSession(this.email); }
class CloudDocument {
  final Map<String, dynamic>? document; final int version; final DateTime? updatedAt;
  const CloudDocument({required this.document, required this.version, this.updatedAt});
}

/// Desktop API client. The JWT is sent only as a Bearer header and is held in
/// Windows secure storage (DPAPI); it is never written to shared preferences.
class CloudApi {
  static const _base = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://101.37.24.186/api');
  static const _tokenKey = 'study_manager_cloud_token_v1';
  final http.Client _client;
  final FlutterSecureStorage _storage;
  String? _token;
  CloudApi({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(), _storage = storage ?? const FlutterSecureStorage();

  Uri _uri(String path) { final base = _base.endsWith('/') ? _base.substring(0, _base.length - 1) : _base; return Uri.parse('$base$path'); }
  Future<Map<String, String>> _headers() async { final token = _token ??= await _storage.read(key: _tokenKey); return token == null ? const {} : {'Authorization': 'Bearer $token'}; }
  Future<CloudSession> register(String email, String password) => _credentials('/v1/auth/register', email, password);
  Future<CloudSession> login(String email, String password) => _credentials('/v1/auth/login', email, password);
  Future<CloudSession> _credentials(String path, String email, String password) async {
    final response = await _send(() => _client.post(_uri(path), headers: const {'Content-Type': 'application/json'}, body: jsonEncode({'email': email.trim(), 'password': password})));
    final json = _json(response) as Map<String, dynamic>;
    _token = json['access_token'] as String;
    await _storage.write(key: _tokenKey, value: _token);
    return CloudSession(json['email'] as String);
  }
  Future<CloudSession?> session() async {
    final response = await _send(() async => _client.get(_uri('/v1/auth/session'), headers: await _headers()), allowUnauthorized: true);
    if (response.statusCode == 401) { await _storage.delete(key: _tokenKey); _token = null; return null; }
    return CloudSession((_json(response) as Map<String, dynamic>)['email'] as String);
  }
  Future<void> logout() async {
    await _send(() async => _client.post(_uri('/v1/auth/logout'), headers: await _headers()), allowUnauthorized: true);
    await _storage.delete(key: _tokenKey); _token = null;
  }
  Future<CloudDocument> getDocument() async => _document(await _send(() async => _client.get(_uri('/v1/study-document'), headers: await _headers())));
  Future<CloudDocument> putDocument(Map<String, dynamic> document, int expectedVersion, {bool force = false}) async => _document(await _send(() async => _client.put(_uri('/v1/study-document'), headers: {'Content-Type': 'application/json', ...await _headers()}, body: jsonEncode({'document': document, 'expected_version': expectedVersion, 'force': force}))));
  CloudDocument _document(http.Response response) { final json = _json(response) as Map<String, dynamic>; final raw = json['document']; return CloudDocument(document: raw == null ? null : Map<String, dynamic>.from(raw as Map), version: json['version'] as int, updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'] as String)); }
  Future<http.Response> _send(Future<http.Response> Function() action, {bool allowUnauthorized = false}) async {
    try { final response = await action().timeout(const Duration(seconds: 12)); if (allowUnauthorized && response.statusCode == 401) return response; if (response.statusCode == 409) throw CloudConflictException(_message(response)); if (response.statusCode < 200 || response.statusCode >= 300) throw CloudApiException(_message(response), statusCode: response.statusCode); return response; } on CloudApiException { rethrow; } catch (_) { throw const CloudApiException('网络连接失败，请稍后重试。'); }
  }
  Object? _json(http.Response response) { try { return jsonDecode(response.body); } catch (_) { throw const CloudApiException('服务器返回了损坏的数据。'); } }
  String _message(http.Response response) { try { final body = jsonDecode(response.body) as Map<String, dynamic>; return (body['detail'] as String?) ?? '请求失败，请稍后重试。'; } catch (_) { return '请求失败（${response.statusCode}）。'; } }
}
