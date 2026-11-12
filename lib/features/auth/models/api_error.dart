/// CeylonGo Standard Error Envelope
/// Strictly conforms to Section 4.4 of Specification v1.0
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

    final code =
        errorObj?['code'] as String? ?? _defaultCodeForStatus(statusCode);
    final message =
        errorObj?['message'] as String? ?? _defaultMessageForStatus(statusCode);

    final rawFields = errorObj?['fields'] as Map<String, dynamic>?;
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
        return 'VALIDATION_ERROR';
      case 401:
        return 'INVALID_CREDENTIALS';
      case 409:
        return 'EMAIL_ALREADY_EXISTS';
      case 429:
        return 'RATE_LIMITED';
      case 500:
      default:
        return 'INTERNAL_ERROR';
    }
  }

  static String _defaultMessageForStatus(int status) {
    switch (status) {
      case 400:
        return 'Invalid submitted values.';
      case 401:
        return 'Invalid email or password.';
      case 409:
        return 'An account with this email already exists.';
      case 429:
        return 'Too many attempts. Please try again later.';
      case 500:
      default:
        return 'An unexpected server error occurred. Please try again.';
    }
  }

  @override
  String toString() =>
      'ApiError($statusCode, $code, $message, fields: $fields)';
}
