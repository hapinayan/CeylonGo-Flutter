import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../auth/models/api_error.dart';
import '../models/map_models.dart';

/// Injectable HTTP client for CeylonGo Interactive Map FastAPI endpoints:
/// - `GET /api/v1/map/locations`
/// - `GET /api/v1/map/nearby`
/// - `GET /api/v1/map/search`
/// - `GET /api/v1/map/categories`
/// - `POST /api/v1/map/route`
class MapApiService {
  final http.Client _client;
  final Duration timeoutDuration;

  MapApiService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  Future<MapPageResponse> getLocations({
    MapBounds bounds = MapBounds.sriLanka,
    String? category,
    int page = 1,
    int pageSize = 25,
  }) async {
    if (!bounds.isValid) {
      throw const ApiError(
        statusCode: 422,
        code: 'map_invalid_bounds',
        message: 'Invalid map viewport bounds.',
      );
    }

    final params = <String, String>{
      'west': bounds.west.toString(),
      'south': bounds.south.toString(),
      'east': bounds.east.toString(),
      'north': bounds.north.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }

    final uri = Uri.parse(ApiConstants.mapLocationsEndpoint).replace(
      queryParameters: params,
    );
    final decoded = await _getJson(uri);
    if (decoded is! Map) {
      throw _invalidResponseError();
    }
    try {
      return MapPageResponse.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<MapPageResponse> getNearby({
    required double latitude,
    required double longitude,
    int radiusKm = 10,
    String? category,
    int page = 1,
    int pageSize = 25,
  }) async {
    if (!MapCoordinates.isValidLatLon(latitude, longitude)) {
      throw const ApiError(
        statusCode: 422,
        code: 'VALIDATION_ERROR',
        message: 'Valid coordinates are required for nearby discovery.',
      );
    }
    if (!const [5, 10, 25, 50].contains(radiusKm)) {
      throw const ApiError(
        statusCode: 422,
        code: 'map_invalid_radius',
        message: 'Nearby radius must be 5, 10, 25, or 50 km.',
      );
    }

    final params = <String, String>{
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'radius_km': radiusKm.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }

    final uri = Uri.parse(ApiConstants.mapNearbyEndpoint).replace(
      queryParameters: params,
    );
    final decoded = await _getJson(uri);
    if (decoded is! Map) {
      throw _invalidResponseError();
    }
    try {
      return MapPageResponse.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<MapPageResponse> searchLocations({
    required String query,
    String? category,
    int page = 1,
    int pageSize = 25,
  }) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2 || normalized.length > 80) {
      throw const ApiError(
        statusCode: 422,
        code: 'map_invalid_search',
        message: 'Enter at least 2 characters to search places or services.',
      );
    }

    final params = <String, String>{
      'q': normalized,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }

    final uri = Uri.parse(ApiConstants.mapSearchEndpoint).replace(
      queryParameters: params,
    );
    final decoded = await _getJson(uri);
    if (decoded is! Map) {
      throw _invalidResponseError();
    }
    try {
      return MapPageResponse.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<List<MapCategoryItem>> getCategories() async {
    final uri = Uri.parse(ApiConstants.mapCategoriesEndpoint);
    final decoded = await _getJson(uri);
    if (decoded is! List) {
      throw _invalidResponseError();
    }
    try {
      return decoded
          .whereType<Map>()
          .map((e) => MapCategoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<MapRouteResponse> getRoute({
    required MapCoordinates origin,
    required MapCoordinates destination,
    RouteTravelMode mode = RouteTravelMode.driving,
  }) async {
    final uri = Uri.parse(ApiConstants.mapRouteEndpoint);
    try {
      final response = await _client
          .post(
            uri,
            headers: ApiConstants.defaultHeaders,
            body: jsonEncode({
              'origin': origin.toJson(),
              'destination': destination.toJson(),
              'mode': mode.apiValue,
            }),
          )
          .timeout(timeoutDuration);

      final decoded = _decodeJson(response.body);
      if (response.statusCode == 200) {
        if (decoded is! Map) {
          throw _invalidResponseError();
        }
        try {
          return MapRouteResponse.fromJson(Map<String, dynamic>.from(decoded));
        } on FormatException {
          throw _invalidResponseError();
        }
      }

      throw _parseError(
        response.statusCode,
        decoded is Map ? Map<String, dynamic>.from(decoded) : const {},
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

  Future<dynamic> _getJson(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeoutDuration);

      final decoded = _decodeJson(response.body);
      if (response.statusCode == 200) {
        if (decoded == null) {
          throw _invalidResponseError();
        }
        return decoded;
      }

      throw _parseError(
        response.statusCode,
        decoded is Map ? Map<String, dynamic>.from(decoded) : const {},
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

  dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  ApiError _invalidResponseError() {
    return const ApiError(
      statusCode: 502,
      code: 'map_invalid_response',
      message: 'Received an unexpected map response. Please try again.',
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
      message: _userMessageForError(
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
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 422:
        return 'VALIDATION_ERROR';
      case 429:
        return 'map_quota_exceeded';
      case 502:
        return 'map_upstream_error';
      case 503:
        return 'map_upstream_unavailable';
      case 504:
        return 'map_upstream_timeout';
      default:
        return status >= 500 ? 'INTERNAL_ERROR' : 'API_ERROR';
    }
  }

  String _userMessageForError({
    required int statusCode,
    required String code,
    String? retryAfterHeader,
  }) {
    final retrySeconds = int.tryParse((retryAfterHeader ?? '').trim());
    final retrySuffix = (retrySeconds != null && retrySeconds > 0)
        ? ' Try again in $retrySeconds seconds.'
        : ' Please try again shortly.';

    switch (code) {
      case 'map_routing_not_configured':
        return 'In-app route guidance is unconfigured on the server. Use Open Directions in Google Maps instead.';
      case 'map_identical_waypoints':
        return 'Origin and destination are the same location.';
      case 'map_no_route':
        return 'No route could be found between these two locations.';
      case 'map_quota_exceeded':
      case 'map_upstream_rate_limited':
        return 'Map routing is temporarily rate-limited.$retrySuffix';
      case 'map_routing_busy':
      case 'map_upstream_unavailable':
        return 'Map routing service is temporarily unavailable. Please try again later.';
      case 'map_upstream_timeout':
        return 'Route calculation timed out. Please try again.';
      case 'map_invalid_bounds':
        return 'Invalid map area selected. Please recenter on Sri Lanka.';
      case 'map_invalid_radius':
        return 'Invalid nearby radius. Choose 5, 10, 25, or 50 km.';
      case 'map_invalid_search':
        return 'Enter at least 2 valid characters to search map locations.';
      case 'map_invalid_route_response':
      case 'map_upstream_authentication':
      case 'map_upstream_error':
        return 'Unable to calculate route right now. Use Google Maps directions instead.';
    }

    switch (statusCode) {
      case 400:
      case 422:
        return 'Invalid map request. Please check your filters or search query.';
      case 404:
        return 'No matching map data or route was found.';
      case 429:
        return 'Too many map requests.$retrySuffix';
      case 503:
        return 'Map service is temporarily unavailable.';
      case 504:
        return 'Map request timed out. Please try again.';
      default:
        return 'Unable to load map data right now. Please try again.';
    }
  }
}

