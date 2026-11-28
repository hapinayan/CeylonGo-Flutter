import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../auth/models/api_error.dart';
import '../models/provider_identity_models.dart';

/// HTTP client for Provider Onboarding OTP, Draft, Personal/Business Details,
/// Identity Document Multipart Upload (`POST /api/v1/providers/registration/identity`),
/// and Final Submission (`POST /api/v1/providers/registration/submit`).
///
/// Security: Never logs authorization tokens, NIC numbers, filenames, or image bytes.
class ProviderIdentityService {
  final http.Client _client;
  final Duration timeoutDuration;

  ProviderIdentityService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  Future<String> sendRegistrationOtp(String email) async {
    final url = Uri.parse(ApiConstants.providerOtpSendEndpoint);
    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({'email': email.trim().toLowerCase()}),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response.body);
      if (response.statusCode == 200) {
        return (data['message'] as String?) ??
            'Verification code sent successfully.';
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
    }
  }

  Future<ProviderOtpVerifyResult> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse(ApiConstants.providerOtpVerifyEndpoint);
    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'otp': otp.trim(),
            }),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response.body);
      if (response.statusCode == 200) {
        return ProviderOtpVerifyResult.fromJson(data);
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
    }
  }

  Future<ProviderDraftStatus> getDraft(String registrationAuthToken) async {
    _ensureAuthToken(registrationAuthToken);
    final url = Uri.parse(ApiConstants.providerDraftEndpoint);
    try {
      final response = await _client
          .get(url, headers: ApiConstants.authHeaders(registrationAuthToken))
          .timeout(timeoutDuration);

      final data = _decodeJson(response.body);
      if (response.statusCode == 200) {
        return ProviderDraftStatus.fromJson(data);
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
    }
  }

  Future<ProviderDraftStatus> savePersonalDetails({
    required String registrationAuthToken,
    required PersonalDetailsPayload payload,
  }) async {
    _ensureAuthToken(registrationAuthToken);
    final url = Uri.parse(ApiConstants.providerPersonalEndpoint);
    try {
      final response = await _client
          .put(
            url,
            headers: ApiConstants.authHeaders(registrationAuthToken),
            body: jsonEncode(payload.toJson()),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response.body);
      if (response.statusCode == 200) {
        return ProviderDraftStatus.fromJson(data);
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
    }
  }

  Future<ProviderDraftStatus> saveBusinessDetails({
    required String registrationAuthToken,
    required BusinessDetailsPayload payload,
  }) async {
    _ensureAuthToken(registrationAuthToken);
    final url = Uri.parse(ApiConstants.providerBusinessEndpoint);
    try {
      final response = await _client
          .put(
            url,
            headers: ApiConstants.authHeaders(registrationAuthToken),
            body: jsonEncode(payload.toJson()),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response.body);
      if (response.statusCode == 200) {
        return ProviderDraftStatus.fromJson(data);
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
    }
  }

  Future<ProviderRegistrationSubmitResult> submitRegistration(
    String registrationAuthToken,
  ) async {
    _ensureAuthToken(registrationAuthToken);
    final url = Uri.parse(ApiConstants.providerSubmitEndpoint);
    try {
      final response = await _client
          .post(
            url,
            headers: ApiConstants.authHeaders(registrationAuthToken),
          )
          .timeout(timeoutDuration);

      final data = _decodeJson(response.body);
      if (response.statusCode == 200) {
        return ProviderRegistrationSubmitResult.fromJson(data);
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
    }
  }

  /// Uploads one or more validated identity documents (`selfie`, `nic_front`,
  /// `nic_back`) to `POST /api/v1/providers/registration/identity`.
  Future<ProviderDraftStatus> uploadIdentityDocuments({
    required String registrationAuthToken,
    IdentityDocumentFile? selfie,
    IdentityDocumentFile? nicFront,
    IdentityDocumentFile? nicBack,
  }) async {
    _ensureAuthToken(registrationAuthToken);

    if (selfie == null && nicFront == null && nicBack == null) {
      throw const ApiError(
        statusCode: 400,
        code: 'NO_DOCUMENTS_SELECTED',
        message: 'Select at least one identity document before uploading.',
      );
    }

    final url = Uri.parse(ApiConstants.providerIdentityUploadEndpoint);
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $registrationAuthToken'
      ..headers['Accept'] = 'application/json';

    final docs = [selfie, nicFront, nicBack].whereType<IdentityDocumentFile>();
    for (final doc in docs) {
      IdentityDocumentValidator.validate(
        kind: doc.kind,
        bytes: doc.bytes,
        filename: doc.safeFilename,
        mimeType: doc.mimeType,
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          doc.kind.fieldName,
          doc.bytes,
          filename: doc.safeFilename,
        ),
      );
    }

    try {
      final streamed = await _client.send(request).timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamed);
      final data = _decodeJson(response.body);

      if (response.statusCode == 200) {
        return ProviderDraftStatus.fromJson(data);
      }
      throw _parseApiError(response.statusCode, data);
    } on ApiError {
      rethrow;
    } on IdentityValidationException catch (e) {
      throw ApiError(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: e.message,
      );
    } on SocketException {
      throw ApiError.network();
    } on TimeoutException {
      throw ApiError.timeout();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  void _ensureAuthToken(String token) {
    if (token.trim().isEmpty) {
      throw const ApiError(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'Registration authorization token is required.',
      );
    }
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

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
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        return ApiError(
          statusCode: statusCode,
          code: 'VALIDATION_ERROR',
          message: first['msg'].toString(),
        );
      }
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
      case 409:
        return 'CONFLICT';
      case 413:
        return 'PAYLOAD_TOO_LARGE';
      case 415:
        return 'UNSUPPORTED_MEDIA_TYPE';
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
        return 'Invalid document or registration state. Please check your files.';
      case 401:
        return 'Registration authorization expired or missing. Please verify your email again.';
      case 403:
        return 'This account is not authorized for provider identity upload.';
      case 409:
        return 'This email or identity document is already registered.';
      case 413:
        return 'Uploaded image exceeds the 5 MB server limit.';
      case 415:
        return 'Unsupported image format. Use JPEG, PNG, or WEBP.';
      case 429:
        return 'Too many upload attempts. Please wait a moment before retrying.';
      default:
        return 'Server error ($status). Please try again later.';
    }
  }
}
