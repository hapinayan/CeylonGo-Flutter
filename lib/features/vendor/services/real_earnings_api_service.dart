import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../auth/models/api_error.dart';
import '../models/wallet_commission_models.dart';

/// Read-only HTTP client for verified CeylonGo FastAPI provider earnings &
/// settlement endpoints:
/// - `GET /api/v1/providers/me/earnings/summary`
/// - `GET /api/v1/providers/me/settlements`
/// - `GET /api/v1/payments/provider/earnings`
///
/// Security: Never logs JWT tokens or financial figures.
class RealEarningsApiService {
  final http.Client _client;
  final Duration timeoutDuration;

  RealEarningsApiService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  Future<RealProviderEarningsSummary> getProviderEarningsSummary(
    String accessToken,
  ) async {
    _ensureToken(accessToken);
    final uri = Uri.parse(ApiConstants.providerEarningsSummaryEndpoint);
    final data = await _getJson(uri, accessToken);
    try {
      return RealProviderEarningsSummary.fromProviderDashboardJson(data);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<RealProviderEarningsSummary> getHomestayPaymentsEarnings(
    String accessToken,
  ) async {
    _ensureToken(accessToken);
    final uri = Uri.parse(ApiConstants.paymentsProviderEarningsEndpoint);
    final data = await _getJson(uri, accessToken);
    try {
      return RealProviderEarningsSummary.fromPaymentsProviderJson(data);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<RealProviderSettlementPage> getProviderSettlements(
    String accessToken, {
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    _ensureToken(accessToken);
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };
    final uri = Uri.parse(ApiConstants.providerSettlementsEndpoint).replace(
      queryParameters: params,
    );
    final data = await _getJson(uri, accessToken);
    try {
      return RealProviderSettlementPage.fromJson(data);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, String accessToken) async {
    try {
      final response = await _client
          .get(uri, headers: ApiConstants.authHeaders(accessToken.trim()))
          .timeout(timeoutDuration);
      final decoded = _decodeJsonMap(response.body);
      if (response.statusCode == 200) {
        if (decoded == null) throw _invalidResponseError();
        return decoded;
      }
      throw _parseApiError(response.statusCode, decoded ?? const {});
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

  void _ensureToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty || trimmed.startsWith('demo-')) {
      throw const ApiError(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'Sign in with a verified Provider account to view real earnings.',
      );
    }
  }

  Map<String, dynamic>? _decodeJsonMap(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  ApiError _invalidResponseError() {
    return const ApiError(
      statusCode: 502,
      code: 'INVALID_RESPONSE',
      message: 'Received an unexpected earnings response. Please try again.',
    );
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
    return ApiError(
      statusCode: statusCode,
      code: _codeForStatus(statusCode),
      message: _defaultMessageForStatus(statusCode),
    );
  }

  String _codeForStatus(int status) {
    switch (status) {
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
      case 401:
        return 'Session expired. Please sign in again.';
      case 403:
        return 'Your provider account is not authorized to view earnings yet.';
      case 404:
        return 'Earnings or settlement data was not found.';
      case 422:
        return 'Invalid earnings query parameters.';
      case 429:
        return 'Too many requests. Please wait before retrying.';
      default:
        return 'Unable to load earnings right now ($status).';
    }
  }
}

