import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../auth/models/api_error.dart';
import '../models/provider_profile_model.dart';

/// Production HTTP client for CeylonGo FastAPI Provider endpoints:
/// - `POST /api/v1/providers/login`
/// - `GET /api/v1/providers/me`
/// - `PATCH /api/v1/providers/me`
/// - `POST /api/v1/providers/me/change-password`
class ProviderApiService {
  final http.Client _client;
  final Duration timeoutDuration;

  ProviderApiService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  Future<ProviderLoginResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.providerLoginEndpoint);
    final payload = {
      'email': email.trim().toLowerCase(),
      'password': password,
    };

    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response);
      if (response.statusCode == 200) {
        return ProviderLoginResult.fromJson(data);
      }
      throw _parseApiError(response.statusCode, data);
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

  Future<ProviderProfile> getProfile(String accessToken) async {
    _ensureToken(accessToken);
    final url = Uri.parse(ApiConstants.providerMeEndpoint);

    try {
      final response = await _client
          .get(url, headers: ApiConstants.authHeaders(accessToken))
          .timeout(timeoutDuration);

      final data = _decodeJson(response);
      if (response.statusCode == 200) {
        return ProviderProfile.fromJson(data);
      }
      throw _parseApiError(response.statusCode, data);
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

  Future<ProviderProfile> updateProfile({
    required String accessToken,
    required Map<String, dynamic> patchData,
  }) async {
    _ensureToken(accessToken);
    if (patchData.isEmpty) {
      throw const ApiError(
        statusCode: 422,
        code: 'NO_CHANGES',
        message: 'No profile fields were modified.',
      );
    }
    final url = Uri.parse(ApiConstants.providerMeEndpoint);

    try {
      final response = await _client
          .patch(
            url,
            headers: ApiConstants.authHeaders(accessToken),
            body: jsonEncode(patchData),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response);
      if (response.statusCode == 200) {
        return ProviderProfile.fromJson(data);
      }
      throw _parseApiError(response.statusCode, data);
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

  Future<String> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _ensureToken(accessToken);
    final url = Uri.parse(ApiConstants.providerChangePasswordEndpoint);
    final payload = {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_new_password': confirmNewPassword,
    };

    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.authHeaders(accessToken),
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response);
      if (response.statusCode == 200) {
        return (data['message'] as String?) ?? 'Password changed successfully';
      }
      throw _parseApiError(response.statusCode, data);
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

  void _ensureToken(String accessToken) {
    if (accessToken.trim().isEmpty) {
      throw const ApiError(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'Your provider session has expired. Please sign in again.',
      );
    }
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.trim().isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Parses both standard CeylonGo `error` envelopes and FastAPI `detail`
  /// responses (string or Pydantic validation error list).
  ApiError _parseApiError(int statusCode, Map<String, dynamic> json) {
    if (json['error'] is Map<String, dynamic>) {
      return ApiError.fromJson(statusCode, json);
    }

    final detail = json['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return ApiError(
        statusCode: statusCode,
        code: _codeForStatus(statusCode),
        message: detail.trim(),
      );
    }

    if (detail is List && detail.isNotEmpty) {
      final fields = <String, String>{};
      final messages = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final msg = item['msg']?.toString() ?? 'Validation error';
          messages.add(msg);
          final loc = item['loc'];
          if (loc is List && loc.isNotEmpty) {
            fields[loc.last.toString()] = msg;
          }
        }
      }
      return ApiError(
        statusCode: statusCode,
        code: 'VALIDATION_ERROR',
        message: messages.isNotEmpty
            ? messages.first
            : 'Please check the submitted values.',
        fields: fields,
      );
    }

    return ApiError(
      statusCode: statusCode,
      code: _codeForStatus(statusCode),
      message: _defaultMessageForStatus(statusCode),
    );
  }

  String _codeForStatus(int status) {
    switch (status) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 422:
        return 'VALIDATION_ERROR';
      case 429:
        return 'RATE_LIMITED';
      default:
        return status >= 500 ? 'INTERNAL_ERROR' : 'API_ERROR';
    }
  }

  String _defaultMessageForStatus(int status) {
    switch (status) {
      case 400:
      case 422:
        return 'Please check the submitted values and try again.';
      case 401:
        return 'Session expired or invalid credentials. Please sign in again.';
      case 403:
        return 'Access restricted to approved provider accounts.';
      case 404:
        return 'Requested provider resource was not found.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Server error ($status). Please try again later.';
    }
  }
}

