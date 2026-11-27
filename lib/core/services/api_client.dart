import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../features/auth/models/api_error.dart';
import 'secure_storage_service.dart';

/// Shared HTTP client helper for authenticated and public JSON API calls.
class ApiClient {
  final http.Client _client;
  final SecureStorageService _storage;
  final Duration timeoutDuration;

  ApiClient({
    http.Client? client,
    SecureStorageService? storageService,
    this.timeoutDuration = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _storage = storageService ?? SecureStorageService();

  Future<Map<String, String>> headers({bool auth = true}) async {
    if (!auth) return ApiConstants.defaultHeaders;
    final token = await _storage.getToken();
    if (token != null && token.trim().isNotEmpty) {
      return ApiConstants.authHeaders(token);
    }
    return ApiConstants.defaultHeaders;
  }

  Future<String?> getToken() => _storage.getToken();

  Future<dynamic> get(
    String url, {
    Map<String, String>? queryParameters,
    bool auth = true,
  }) async {
    final uri = Uri.parse(url).replace(
      queryParameters: (queryParameters != null && queryParameters.isNotEmpty)
          ? queryParameters
          : null,
    );
    return _send(() async {
      final h = await headers(auth: auth);
      return _client.get(uri, headers: h).timeout(timeoutDuration);
    });
  }

  Future<dynamic> post(
    String url, {
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse(url);
    return _send(() async {
      final h = await headers(auth: auth);
      return _client
          .post(uri, headers: h, body: body != null ? jsonEncode(body) : null)
          .timeout(timeoutDuration);
    });
  }

  Future<dynamic> put(
    String url, {
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse(url);
    return _send(() async {
      final h = await headers(auth: auth);
      return _client
          .put(uri, headers: h, body: body != null ? jsonEncode(body) : null)
          .timeout(timeoutDuration);
    });
  }

  Future<dynamic> patch(
    String url, {
    Object? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse(url);
    return _send(() async {
      final h = await headers(auth: auth);
      return _client
          .patch(uri, headers: h, body: body != null ? jsonEncode(body) : null)
          .timeout(timeoutDuration);
    });
  }

  Future<dynamic> delete(
    String url, {
    bool auth = true,
  }) async {
    final uri = Uri.parse(url);
    return _send(() async {
      final h = await headers(auth: auth);
      return _client.delete(uri, headers: h).timeout(timeoutDuration);
    });
  }

  Future<dynamic> _send(Future<http.Response> Function() execute) async {
    try {
      final response = await execute();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.trim().isEmpty) return null;
        return jsonDecode(response.body);
      }

      Map<String, dynamic> data = {};
      if (response.body.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {}
      }
      throw ApiError.fromJson(response.statusCode, data);
    } on ApiError {
      rethrow;
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on http.ClientException {
      throw ApiError.network();
    } on FormatException catch (e) {
      throw ApiError.generic(500, e.message);
    }
  }
}
