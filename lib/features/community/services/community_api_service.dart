import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../auth/models/api_error.dart';
import '../models/community_api_models.dart';

/// Injectable HTTP client for CeylonGo Travel Community FastAPI endpoints:
/// - `GET /api/v1/community/feed`
/// - `POST /api/v1/community/posts`
/// - `GET /api/v1/community/posts/{post_id}`
/// - `POST /api/v1/community/posts/{post_id}/media` (`file`)
/// - `DELETE /api/v1/community/posts/{post_id}/media/{media_id}`
///
/// Security: Never logs JWT tokens, image bytes, or local file paths.
class CommunityApiService {
  final http.Client _client;
  final Duration timeoutDuration;

  CommunityApiService({
    http.Client? client,
    this.timeoutDuration = const Duration(seconds: 25),
  }) : _client = client ?? http.Client();

  Future<CommunityApiFeedResponse> getFeed({
    String? authToken,
    int page = 1,
    int pageSize = 20,
    String? hashtag,
    bool followingOnly = false,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (followingOnly) 'following_only': 'true',
      if (hashtag != null && hashtag.trim().isNotEmpty && hashtag != '#All')
        'hashtag': hashtag.trim().replaceFirst(RegExp(r'^#'), ''),
    };

    final uri = Uri.parse(ApiConstants.communityFeedEndpoint).replace(
      queryParameters: params,
    );
    final headers = (authToken != null && authToken.trim().isNotEmpty)
        ? ApiConstants.authHeaders(authToken.trim())
        : ApiConstants.defaultHeaders;

    final data = await _sendJsonRequest(
      () => _client.get(uri, headers: headers).timeout(timeoutDuration),
      expectedStatuses: const {200},
    );
    try {
      return CommunityApiFeedResponse.fromJson(data);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<CommunityApiPost> createPost({
    required String authToken,
    required String content,
    String? locationTag,
    String? district,
    List<String>? hashtags,
  }) async {
    _ensureAuthToken(authToken);
    final uri = Uri.parse(ApiConstants.communityPostsEndpoint);
    final caption = content.trim();
    final tags = (hashtags ?? const <String>[])
        .map((tag) => tag.trim().replaceFirst(RegExp(r'^#'), ''))
        .where((tag) =>
            tag.isNotEmpty && !caption.toLowerCase().contains('#${tag.toLowerCase()}'))
        .map((tag) => '#$tag');
    final location = locationTag?.trim();
    final body = [
      caption,
      if (location != null && location.isNotEmpty) location,
      if (tags.isNotEmpty) tags.join(' '),
    ].join('\n');
    if (body.runes.length > 2000) {
      throw const ApiError(
        statusCode: 422,
        code: 'INVALID_POST_BODY',
        message: 'Caption, location, and hashtags together cannot exceed 2000 characters.',
      );
    }
    final payload = {'body': body};

    final data = await _sendJsonRequest(
      () => _client
          .post(
            uri,
            headers: ApiConstants.authHeaders(authToken.trim()),
            body: jsonEncode(payload),
          )
          .timeout(timeoutDuration),
      expectedStatuses: const {200, 201},
    );
    try {
      return CommunityApiPost.fromJson(data);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  Future<CommunityApiPost> getPost({
    required int postId,
    String? authToken,
  }) async {
    final uri = Uri.parse(ApiConstants.communityPostEndpoint(postId));
    final headers = (authToken != null && authToken.trim().isNotEmpty)
        ? ApiConstants.authHeaders(authToken.trim())
        : ApiConstants.defaultHeaders;

    final data = await _sendJsonRequest(
      () => _client.get(uri, headers: headers).timeout(timeoutDuration),
      expectedStatuses: const {200},
    );
    try {
      return CommunityApiPost.fromJson(data);
    } on FormatException {
      throw _invalidResponseError();
    }
  }

  /// Uploads a single validated photo to `POST /api/v1/community/posts/{post_id}/media`
  /// using multipart field `file`.
  Future<CommunityApiMedia> uploadPostMedia({
    required String authToken,
    required int postId,
    required SelectedCommunityPhoto photo,
  }) async {
    _ensureAuthToken(authToken);
    final format = CommunityMediaValidator.validate(
      bytes: photo.bytes,
      filename: photo.safeFilename,
      mimeType: photo.mimeType,
    );

    final uri = Uri.parse(ApiConstants.communityPostMediaEndpoint(postId));
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${authToken.trim()}'
      ..headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        photo.bytes,
        filename: photo.safeFilename,
        contentType: http.MediaType.parse(format.mimeType),
      ),
    );

    try {
      final streamed = await _client.send(request).timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decodeJsonMap(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded == null) throw _invalidResponseError();
        return CommunityApiMedia.fromJson(decoded);
      }
      throw _parseApiError(response.statusCode, decoded ?? const {});
    } on ApiError {
      rethrow;
    } on CommunityMediaValidationException catch (e) {
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

  Future<void> deletePostMedia({
    required String authToken,
    required int postId,
    required int mediaId,
  }) async {
    _ensureAuthToken(authToken);
    final uri = Uri.parse(
      ApiConstants.communityPostMediaItemEndpoint(postId, mediaId),
    );
    await _sendJsonRequest(
      () => _client
          .delete(
            uri,
            headers: ApiConstants.authHeaders(authToken.trim()),
          )
          .timeout(timeoutDuration),
      expectedStatuses: const {200, 204},
    );
  }

  Future<Map<String, dynamic>> _sendJsonRequest(
    Future<http.Response> Function() send, {
    required Set<int> expectedStatuses,
  }) async {
    try {
      final response = await send();
      final decoded = _decodeJsonMap(response.body);
      if (expectedStatuses.contains(response.statusCode)) {
        return decoded ?? const <String, dynamic>{};
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

  void _ensureAuthToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty || trimmed.startsWith('demo-')) {
      throw const ApiError(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'Sign in with a real Traveler account to post to Community.',
      );
    }
  }

  Map<String, dynamic>? _decodeJsonMap(String body) {
    if (body.trim().isEmpty) return {};
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
      message: 'Received an unexpected server response. Please try again.',
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
      case 404:
        return 'NOT_FOUND';
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
      case 401:
        return 'Your session has expired. Please sign in again to post.';
      case 403:
        return 'You do not have permission for this community action, or your account is restricted.';
      case 404:
        return 'Community post or photo was not found.';
      case 409:
        return 'This media cannot be modified because moderation reports exist.';
      case 413:
        return 'Image exceeds the 5 MB upload limit.';
      case 415:
        return 'Unsupported image format. Use JPEG, PNG, or WEBP.';
      case 429:
        return 'Too many community requests. Please wait before trying again.';
      default:
        return 'Unable to complete community request ($status). Please try again.';
    }
  }
}
