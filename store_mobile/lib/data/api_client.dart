import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  String? _token;
  String _baseUrl = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  bool _resolved = false;

  String? get token => _token;

  String get baseUrl => _baseUrl;

  void resetBase() {
    _resolved = false;
  }

  void setToken(String? token) {
    _token = (token == null || token.isEmpty) ? null : token;
  }

  Future<void> ensureBase() async {
    if (_resolved) {
      return;
    }
    for (final candidate in AppConfig.apiBaseCandidates) {
      final base = candidate.replaceAll(RegExp(r'/+$'), '');
      try {
        final uri = Uri.parse('$base/api/categories');
        final res = await http
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _baseUrl = base;
          _resolved = true;
          debugPrint('ApiClient connected to $_baseUrl');
          return;
        }
      } catch (e) {
        debugPrint('ApiClient candidate failed $base: $e');
      }
    }
    _resolved = true;
    debugPrint('ApiClient falling back to $_baseUrl');
  }

  Uri _uri(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$clean');
  }

  Map<String, String> _headers({bool auth = false, bool jsonBody = false}) {
    return {
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    await ensureBase();
    final response = await http
        .post(
          _uri(path),
          headers: _headers(auth: auth, jsonBody: body != null),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
  }) async {
    await ensureBase();
    final response = await http
        .get(
          _uri(path),
          headers: _headers(auth: auth),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    await ensureBase();
    final response = await http
        .put(
          _uri(path),
          headers: _headers(auth: auth, jsonBody: body != null),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    await ensureBase();
    final response = await http
        .delete(
          _uri(path),
          headers: _headers(auth: auth),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        }
      } catch (_) {
        // ignore malformed body
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final errors = json['errors'];
    String message = (json['message'] as String?)?.trim() ?? '';
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        message = first.first.toString();
      } else if (first != null) {
        message = first.toString();
      }
    }
    if (message.isEmpty) {
      message = 'تعذر الاتصال بالخادم (${response.statusCode})';
    }

    throw ApiException(
      message,
      statusCode: response.statusCode,
      errors: errors is Map<String, dynamic> ? errors : null,
    );
  }
}
