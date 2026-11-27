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
  static String get forgotPasswordEndpoint => '$apiV1/auth/forgot-password';
  static String get resetPasswordEndpoint => '$apiV1/auth/reset-password';

  // Provider Endpoints (FastAPI /api/v1/providers)
  static String get providerLoginEndpoint => '$apiV1/providers/login';
  static String get providerMeEndpoint => '$apiV1/providers/me';
  static String get providerChangePasswordEndpoint =>
      '$apiV1/providers/me/change-password';
  static String get providerOtpSendEndpoint => '$apiV1/providers/otp/send';
  static String get providerOtpVerifyEndpoint => '$apiV1/providers/otp/verify';
  static String get providerIdentityUploadEndpoint =>
      '$apiV1/providers/registration/identity';
  static String get providerPersonalEndpoint =>
      '$apiV1/providers/registration/personal';
  static String get providerBusinessEndpoint =>
      '$apiV1/providers/registration/business';
  static String get providerDraftEndpoint =>
      '$apiV1/providers/registration/draft';
  static String get providerSubmitEndpoint =>
      '$apiV1/providers/registration/submit';

  // Weather Endpoints (FastAPI /api/v1/weather)
  static String get weatherLocationsEndpoint => '$apiV1/weather/locations';
  static String get weatherCurrentEndpoint => '$apiV1/weather/current';
  static String get weatherForecastEndpoint => '$apiV1/weather/forecast';

  // Interactive Map Endpoints (FastAPI /api/v1/map)
  static String get mapLocationsEndpoint => '$apiV1/map/locations';
  static String get mapNearbyEndpoint => '$apiV1/map/nearby';
  static String get mapSearchEndpoint => '$apiV1/map/search';
  static String get mapCategoriesEndpoint => '$apiV1/map/categories';
  static String get mapRouteEndpoint => '$apiV1/map/route';

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
