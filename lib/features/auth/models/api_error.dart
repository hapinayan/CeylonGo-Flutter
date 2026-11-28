/// CeylonGo Standard Error Envelope
/// Supports both legacy `error` envelopes and FastAPI `detail` responses.
class ApiError implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, String> fields;

  const ApiError({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fields = const {},
  });

  factory ApiError.fromJson(int statusCode, Map<String, dynamic> json) {
    final errorObj = json['error'] as Map<String, dynamic>?;
    if (errorObj != null) {
      final code =
          errorObj['code'] as String? ?? _defaultCodeForStatus(statusCode);
      final message =
          errorObj['message'] as String? ?? _defaultMessageForStatus(statusCode);

      final rawFields = errorObj['fields'] as Map<String, dynamic>?;
      final Map<String, String> parsedFields = {};
      if (rawFields != null) {
        rawFields.forEach((key, val) {
          if (val != null) {
            parsedFields[key] = val.toString();
          }
        });
      }

      return ApiError(
        statusCode: statusCode,
        code: code,
        message: message,
        fields: parsedFields,
      );
    }

    // FastAPI `detail` error shape
    final detail = json['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return ApiError(
        statusCode: statusCode,
        code: _defaultCodeForStatus(statusCode),
        message: detail.trim(),
      );
    }
    if (detail is List && detail.isNotEmpty) {
      final parsedFields = <String, String>{};
      final messages = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final msg = item['msg']?.toString();
          final loc = item['loc'];
          if (msg != null && msg.isNotEmpty) {
            messages.add(msg);
          }
          if (loc is List && loc.isNotEmpty) {
            final fieldKey = loc.last.toString();
            if (msg != null && msg.isNotEmpty) {
              parsedFields[fieldKey] = msg;
            }
          }
        }
      }
      return ApiError(
        statusCode: statusCode,
        code: 'VALIDATION_ERROR',
        message: messages.isNotEmpty
            ? messages.first
            : _defaultMessageForStatus(statusCode),
        fields: parsedFields,
      );
    }

    final topMsg = json['message'] as String?;
    return ApiError(
      statusCode: statusCode,
      code: _defaultCodeForStatus(statusCode),
      message: (topMsg != null && topMsg.trim().isNotEmpty)
          ? topMsg.trim()
          : _defaultMessageForStatus(statusCode),
    );
  }

  factory ApiError.network([String? customMessage]) {
    return ApiError(
      statusCode: 0,
      code: 'NETWORK_ERROR',
      message:
          customMessage ??
          'Unable to connect to CeylonGo server. Please check your connection.',
    );
  }

  factory ApiError.timeout() {
    return const ApiError(
      statusCode: 0,
      code: 'TIMEOUT',
      message: 'Connection timed out. The server took too long to respond.',
    );
  }

  factory ApiError.generic(int statusCode, [String? customMessage]) {
    return ApiError(
      statusCode: statusCode,
      code: _defaultCodeForStatus(statusCode),
      message: customMessage ?? _defaultMessageForStatus(statusCode),
    );
  }

  static String _defaultCodeForStatus(int status) {
    switch (status) {
      case 400:
      case 422:
        return 'VALIDATION_ERROR';
      case 401:
        return 'INVALID_CREDENTIALS';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 409:
        return 'EMAIL_ALREADY_EXISTS';
      case 429:
        return 'RATE_LIMITED';
      case 503:
        return 'SERVICE_UNAVAILABLE';
      case 500:
      default:
        return 'INTERNAL_ERROR';
    }
  }

  static String _defaultMessageForStatus(int status) {
    switch (status) {
      case 400:
      case 422:
        return 'Invalid submitted values.';
      case 401:
        return 'Invalid email or password.';
      case 403:
        return 'You do not have permission for this action.';
      case 404:
        return 'Requested resource was not found.';
      case 409:
        return 'This request conflicts with existing data.';
      case 429:
        return 'Too many attempts. Please try again later.';
      case 503:
        return 'Service is temporarily unavailable. Please try again.';
      case 500:
      default:
        return 'An unexpected server error occurred. Please try again.';
    }
  }

  @override
  String toString() =>
      'ApiError($statusCode, $code, $message, fields: $fields)';
}
