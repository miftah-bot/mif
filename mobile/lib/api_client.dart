import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api/v1',
);

class ApiClient {
  String? token;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> loadToken() async {
    token = await _secureStorage.read(key: 'accessToken');
  }

  Future<void> setToken(String value) async {
    token = value;
    await _secureStorage.write(key: 'accessToken', value: value);
  }

  Future<void> clearToken() async {
    token = null;
    await _secureStorage.delete(key: 'accessToken');
  }

  String _requestId() => 'mobile-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';

  Map<String, String> _headers({String? operationKey}) {
    return {
      'X-Request-Id': _requestId(),
      if (token != null) 'Authorization': 'Bearer $token',
      if (operationKey != null) 'x-operation-key': operationKey,
    };
  }

  Future<http.Response> get(String path) async {
    final response = await http.get(Uri.parse('$apiBaseUrl$path'), headers: _headers());
    if (response.statusCode == 401) await clearToken();
    return response;
  }


  Future<http.Response> logout() async {
    final response = await post('/auth/logout', <String, dynamic>{});
    await clearToken();
    return response;
  }

  Future<http.Response> revokeSession(String sessionId) async {
    return post('/auth/sessions/${Uri.encodeComponent(sessionId)}/revoke', <String, dynamic>{});
  }

  Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    String? operationKey,
  }) {
    return http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {..._headers(operationKey: operationKey), 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).then((response) async {
      if (response.statusCode == 401) await clearToken();
      return response;
    });
  }
}
