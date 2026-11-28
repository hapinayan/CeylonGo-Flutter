import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../models/api_error.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// CeylonGo Authentication API Service
/// Connects to FastAPI /api/v1/auth endpoints.
class AuthService {
  final http.Client _client;
  final Duration timeoutDuration;

  AuthService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// POST /api/v1/auth/register
  /// Preserves 3-parameter signature for backward test compatibility.
  /// Handles both 202 Accepted (Email OTP challenge) and 201 Created.
  Future<RegisterResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _postRegister(
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  /// POST /api/v1/auth/register with optional phone number for traveler registration.
  Future<RegisterResponse> registerTraveler({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) {
    return _postRegister(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
    );
  }

  Future<RegisterResponse> _postRegister({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final url = Uri.parse(ApiConstants.registerEndpoint);

    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password, // Password must never be trimmed
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
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

      if (response.statusCode == 202) {
        final challenge = TravelerChallengeResponse.fromJson(data);
        return RegisterResponse.fromChallenge(
          challenge,
          fullName: fullName.trim(),
        );
      } else if (response.statusCode == 201) {
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

  /// POST /api/v1/auth/verify-email
  Future<String> verifyEmailOtp({
    required String email,
    required String registrationId,
    required String otp,
  }) async {
    final url = Uri.parse(ApiConstants.verifyEmailEndpoint);
    final payload = {
      'email': email.trim().toLowerCase(),
      'registration_id': registrationId.trim(),
      'otp': otp.trim(),
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
        return data['message'] as String? ?? 'Email verified successfully.';
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

  /// POST /api/v1/auth/resend-email-otp
  Future<TravelerChallengeResponse> resendEmailOtp({
    required String email,
    required String registrationId,
  }) async {
    final url = Uri.parse(ApiConstants.resendEmailOtpEndpoint);
    final payload = {
      'email': email.trim().toLowerCase(),
      'registration_id': registrationId.trim(),
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

      if (response.statusCode == 202 || response.statusCode == 200) {
        return TravelerChallengeResponse.fromJson(data);
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

  /// POST /api/v1/auth/login
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.loginEndpoint);

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

  /// POST /api/v1/auth/logout
  /// Invalidates existing JWTs server-side by incrementing auth_version.
  Future<void> logout(String accessToken) async {
    if (accessToken.trim().isEmpty) return;
    final url = Uri.parse(ApiConstants.logoutEndpoint);

    try {
      final response = await _client
          .post(url, headers: ApiConstants.authHeaders(accessToken))
          .timeout(timeoutDuration);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      if (response.statusCode == 401) {
        return; // Session already invalid/expired
      }
      throw ApiError.fromJson(
        response.statusCode,
        _decodeResponseBody(response),
      );
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// GET /api/v1/auth/me
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

  /// POST /api/v1/auth/check-email
  Future<bool> checkEmail(String email) async {
    final url = Uri.parse(ApiConstants.checkEmailEndpoint);
    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({'email': email.trim().toLowerCase()}),
          )
          .timeout(timeoutDuration);

      final data = _decodeResponseBody(response);
      if (response.statusCode == 200) {
        return data['is_registered'] == true;
      }
      throw ApiError.fromJson(response.statusCode, data);
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// POST /api/v1/auth/forgot-password
  Future<Map<String, dynamic>> requestPasswordReset({required String email}) async {
    final url = Uri.parse(ApiConstants.forgotPasswordEndpoint);
    final payload = {'email': email.trim().toLowerCase()};

    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> data = _decodeResponseBody(response);

      if (response.statusCode == 200 || response.statusCode == 202) {
        return data;
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        throw const ApiError(
          statusCode: 501,
          code: 'BACKEND_NOT_CONFIGURED',
          message: 'Password reset is not yet supported by the CeylonGo backend server.',
        );
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

  /// GET /api/v1/auth/verify-reset-token
  Future<Map<String, dynamic>> verifyResetToken(String token) async {
    final url = Uri.parse(ApiConstants.verifyResetTokenEndpoint).replace(
      queryParameters: {'token': token.trim()},
    );

    try {
      final response = await _client
          .get(url, headers: ApiConstants.defaultHeaders)
          .timeout(timeoutDuration);
      final data = _decodeResponseBody(response);
      if (response.statusCode == 200) {
        return data;
      }
      throw ApiError.fromJson(response.statusCode, data);
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// POST /api/v1/auth/reset-password
  /// Matches backend PasswordResetConfirm schema: {token, new_password}
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse(ApiConstants.resetPasswordEndpoint);
    final payload = {
      'token': token.trim(),
      'new_password': newPassword,
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
        return data;
      } else if (response.statusCode == 404 || response.statusCode == 405) {
        throw const ApiError(
          statusCode: 501,
          code: 'BACKEND_NOT_CONFIGURED',
          message: 'Password reset update is not yet supported by the CeylonGo backend server.',
        );
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
