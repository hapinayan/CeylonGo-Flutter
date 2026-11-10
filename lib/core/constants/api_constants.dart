/// CeylonGo API Configuration and Endpoints
/// Strictly conforms to Section 4 & Section 7 of Specification v1.0
class ApiConstants {
  /// Base API URL configured via --dart-define=API_BASE_URL=...
  /// Defaults to http://10.0.2.2:8000 for Android emulator communicating with host PC backend.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';

  static String customBaseUrl = '';

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    return defaultBaseUrl;
  }

  static String get apiV1 => '$baseUrl/api/v1';

  // Section 4 Shared Endpoints
  static String get registerEndpoint => '$apiV1/auth/register';
  static String get loginEndpoint => '$apiV1/auth/login';
  static String get meEndpoint => '$apiV1/auth/me';

  // Standard JSON Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
