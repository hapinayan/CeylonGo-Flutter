import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../models/api_error.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// CeylonGo Authentication API Service
/// Handles Network Communication strictly according to Section 4 of Specification v1.0
class AuthService {
  final http.Client _client;
  final Duration timeoutDuration;

  AuthService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// 4.1 POST /api/v1/auth/register
  /// Payload contains strictly: full_name, email, password
  /// Passwords are NEVER trimmed or logged.
  Future<RegisterResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.registerEndpoint);

    // Section 4.1: registration payload
    final payload = {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password, // Password must never be trimmed
    };

    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _decodeResponseBody(response);

      if (response.statusCode == 201) {
        return RegisterResponse.fromJson(data);
      } else {
        throw ApiError.fromJson(response.statusCode, data);
      }
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

  /// 4.2 POST /api/v1/auth/login
  /// Payload contains strictly: email, password
  /// Passwords are NEVER trimmed or logged.
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.loginEndpoint);

    // Section 4.2: login payload
    final payload = {
      'email': email.trim(),
      'password': password, // Password must never be trimmed
    };

    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _decodeResponseBody(response);

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(data);
      } else {
        throw ApiError.fromJson(response.statusCode, data);
      }
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

  /// 4.3 GET /api/v1/auth/me
  /// Header: `Authorization: Bearer <access_token>`
  Future<UserModel> getMe(String accessToken) async {
    if (accessToken.trim().isEmpty) {
      throw const ApiError(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'Missing or empty access token.',
      );
    }

    final url = Uri.parse(ApiConstants.meEndpoint);

    try {
      final response = await _client
          .get(url, headers: ApiConstants.authHeaders(accessToken))
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _decodeResponseBody(response);

      if (response.statusCode == 200) {
        return UserModel.fromJson(data);
      } else {
        throw ApiError.fromJson(response.statusCode, data);
      }
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

  Map<String, dynamic> _decodeResponseBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'error': {
          'code': response.statusCode >= 500
              ? 'INTERNAL_ERROR'
              : 'MALFORMED_RESPONSE',
          'message': 'Expected JSON object in response body.',
        },
      };
    } catch (_) {
      return {
        'error': {
          'code': response.statusCode >= 500
              ? 'INTERNAL_ERROR'
              : 'MALFORMED_RESPONSE',
          'message': response.statusCode >= 500
              ? 'An unexpected server error occurred.'
              : 'Invalid response format from server.',
        },
      };
    }
  }
}
