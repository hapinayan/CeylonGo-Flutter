import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../auth/models/api_error.dart';
import '../models/weather_models.dart';

/// Dependency-injectable HTTP client for CeylonGo Live Weather FastAPI endpoints:
/// - `GET /api/v1/weather/locations?q=...`
/// - `GET /api/v1/weather/current?lat=...&lon=...`
/// - `GET /api/v1/weather/forecast?lat=...&lon=...`
///
/// Security: Never embeds OpenWeather API keys or logs internal server errors.
class WeatherApiService {
  final http.Client _client;
  final Duration timeoutDuration;

  WeatherApiService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  /// Searches Sri Lankan destinations via `GET /api/v1/weather/locations?q=...`.
  Future<WeatherLocationsResponse> searchLocations(String query) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2 || normalized.length > 80) {
      throw const ApiError(
        statusCode: 422,
        code: 'invalid_location_query',
        message: 'Enter at least 2 characters to search Sri Lankan destinations.',
      );
    }

    final uri = Uri.parse(ApiConstants.weatherLocationsEndpoint).replace(
      queryParameters: {'q': normalized},
    );
    final json = await _getJson(uri);
    try {
      return WeatherLocationsResponse.fromJson(json);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  /// Fetches live current weather via `GET /api/v1/weather/current?lat=...&lon=...`.
  Future<CurrentWeatherData> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(ApiConstants.weatherCurrentEndpoint).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      },
    );
    final json = await _getJson(uri);
    try {
      return CurrentWeatherData.fromJson(json);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  /// Fetches 5-day / 3-hour forecast via `GET /api/v1/weather/forecast?lat=...&lon=...`.
  Future<ForecastResponse> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(ApiConstants.weatherForecastEndpoint).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      },
    );
    final json = await _getJson(uri);
    try {
      return ForecastResponse.fromJson(json);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      final decoded = _decodeJsonMap(response.body);
      if (response.statusCode == 200) {
        if (decoded == null) {
          throw _invalidResponseError();
        }
        return decoded;
      }
      throw _parseError(
        response.statusCode,
        decoded ?? const <String, dynamic>{},
        retryAfterHeader: response.headers['retry-after'],
      );
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
      code: 'weather_invalid_response',
      message: 'Received an unexpected weather response. Please try again.',
    );
  }

  ApiError _parseError(
    int statusCode,
    Map<String, dynamic> json, {
    String? retryAfterHeader,
  }) {
    if (json['error'] is Map<String, dynamic>) {
      return ApiError.fromJson(statusCode, json);
    }

    String? code;
    final detail = json['detail'];
    if (detail is Map && detail['code'] is String) {
      code = (detail['code'] as String).trim();
    } else if (detail is String && detail.trim().isNotEmpty) {
      return ApiError(
        statusCode: statusCode,
        code: _fallbackCode(statusCode),
        message: detail.trim(),
      );
    } else if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        return ApiError(
          statusCode: statusCode,
          code: 'VALIDATION_ERROR',
          message: first['msg'].toString(),
        );
      }
    }

    final resolvedCode =
        (code != null && code.isNotEmpty) ? code : _fallbackCode(statusCode);
    return ApiError(
      statusCode: statusCode,
      code: resolvedCode,
      message: _userMessageForWeatherError(
        statusCode: statusCode,
        code: resolvedCode,
        retryAfterHeader: retryAfterHeader,
      ),
    );
  }

  String _fallbackCode(int status) {
    switch (status) {
      case 400:
        return 'BAD_REQUEST';
      case 404:
        return 'NOT_FOUND';
      case 422:
        return 'VALIDATION_ERROR';
      case 429:
        return 'weather_quota_exceeded';
      case 502:
        return 'weather_upstream_error';
      case 503:
        return 'weather_upstream_unavailable';
      case 504:
        return 'weather_upstream_timeout';
      default:
        return status >= 500 ? 'INTERNAL_ERROR' : 'API_ERROR';
    }
  }

  String _userMessageForWeatherError({
    required int statusCode,
    required String code,
    String? retryAfterHeader,
  }) {
    final retrySeconds = int.tryParse((retryAfterHeader ?? '').trim());
    final retrySuffix = (retrySeconds != null && retrySeconds > 0)
        ? ' Try again in $retrySeconds seconds.'
        : ' Please wait a moment and try again.';

    switch (code) {
      case 'weather_not_configured':
        return 'Live weather service is currently unconfigured on the server (missing API key).';
      case 'weather_upstream_rate_limited':
      case 'weather_quota_exceeded':
        return 'Weather service is temporarily rate-limited.$retrySuffix';
      case 'weather_busy':
      case 'weather_upstream_unavailable':
        return 'Live weather service is temporarily unavailable. Please try again later.';
      case 'weather_upstream_timeout':
        return 'The weather provider timed out. Please try again.';
      case 'weather_upstream_authentication':
      case 'weather_upstream_error':
      case 'weather_invalid_response':
        return 'Unable to retrieve valid weather data right now. Please try again later.';
      case 'invalid_location_query':
        return 'Enter a valid Sri Lankan destination name (letters and spaces only).';
    }

    switch (statusCode) {
      case 400:
      case 422:
        return 'Invalid destination or coordinates. Please check your search.';
      case 404:
        return 'Weather data for this destination was not found.';
      case 429:
        return 'Too many weather requests.$retrySuffix';
      case 503:
        return 'Live weather service is temporarily unavailable.';
      case 504:
        return 'Weather request timed out. Please try again.';
      default:
        return 'Weather service error. Please try again later.';
    }
  }
}

