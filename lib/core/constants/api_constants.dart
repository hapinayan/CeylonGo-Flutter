/// CeylonGo API Configuration and Endpoints
/// Grounded in CeylonGo Academic MVP OpenAPI v1.1.0 (/api/v1)
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

  /// Resolve relative backend paths (e.g. /api/v1/listings/1/photos/2) to full URLs.
  static String resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
  }

  // Authentication & Traveler Account Endpoints
  static String get registerEndpoint => '$apiV1/auth/register';
  static String get verifyEmailEndpoint => '$apiV1/auth/verify-email';
  static String get resendEmailOtpEndpoint => '$apiV1/auth/resend-email-otp';
  static String get loginEndpoint => '$apiV1/auth/login';
  static String get logoutEndpoint => '$apiV1/auth/logout';
  static String get meEndpoint => '$apiV1/auth/me';
  static String get avatarEndpoint => '$apiV1/auth/me/avatar';
  static String get changePasswordEndpoint => '$apiV1/auth/change-password';
  static String get checkEmailEndpoint => '$apiV1/auth/check-email';
  static String get forgotPasswordEndpoint => '$apiV1/auth/forgot-password';
  static String get verifyResetTokenEndpoint => '$apiV1/auth/verify-reset-token';
  static String get resetPasswordEndpoint => '$apiV1/auth/reset-password';

  static String userAvatarEndpoint(int userId) => '$apiV1/users/$userId/avatar';
  static String get travelerPreferencesEndpoint => '$apiV1/traveler/preferences';
  static String get travelerNotificationSettingsEndpoint =>
      '$apiV1/traveler/settings/notifications';
  static String get notificationsEndpoint => '$apiV1/notifications';
  static String get notificationsUnreadCountEndpoint =>
      '$apiV1/notifications/unread-count';
  static String get notificationsReadAllEndpoint =>
      '$apiV1/notifications/read-all';
  static String notificationReadEndpoint(int id) =>
      '$apiV1/notifications/$id/read';

  // Discovery Endpoints
  static String get homestaysEndpoint => '$apiV1/homestays';
  static String get homestaysWishlistEndpoint => '$apiV1/homestays/wishlist';
  static String get activitiesEndpoint => '$apiV1/activities';
  static String get activitiesWishlistEndpoint => '$apiV1/activities/wishlist';
  static String get tourGuidesEndpoint => '$apiV1/tour-guides';
  static String get tourGuidesCategoriesEndpoint =>
      '$apiV1/tour-guides/categories';
  static String get tourGuidesWishlistEndpoint => '$apiV1/tour-guides/wishlist';
  static String get rentalVehiclesEndpoint => '$apiV1/rental-vehicles';
  static String get rentalCategoriesEndpoint =>
      '$apiV1/rental-vehicles/categories';
  static String get rentalValidateDatesEndpoint =>
      '$apiV1/rental-bookings/validate-dates';
  static String get rentalWishlistEndpoint => '$apiV1/rental-wishlist';

  // Bookings & Payments Endpoints
  static String get bookingsEndpoint => '$apiV1/bookings';
  static String get myBookingsEndpoint => '$apiV1/bookings/my';
  static String get simulatedPaymentEndpoint => '$apiV1/payments/simulate';
  static String get atLocationPaymentEndpoint => '$apiV1/payments/at-location';

  // Community Endpoints
  static String get communityFeedEndpoint => '$apiV1/community/feed';
  static String get communityPostsEndpoint => '$apiV1/community/posts';
  static String get myCommunityPostsEndpoint => '$apiV1/community/posts/me';
  static String get savedCommunityPostsEndpoint => '$apiV1/community/saved';
  static String get communityReportsEndpoint => '$apiV1/community/reports';

  // AI Planner Endpoints
  static String get aiPlannerConversationsEndpoint =>
      '$apiV1/ai/planner/conversations';
  static String get aiPlannerTripsEndpoint => '$apiV1/ai/planner/trips';
  static String get aiPlannerBookingQuotesEndpoint =>
      '$apiV1/ai/planner/booking-quotes';
  static String get aiPlannerBookingsConfirmEndpoint =>
      '$apiV1/ai/planner/bookings/confirm';
  static String get itineraryGenerateEndpoint => '$apiV1/itinerary/generate';

  // Provider Endpoints
  static String get providerOtpSendEndpoint => '$apiV1/providers/otp/send';
  static String get providerOtpVerifyEndpoint => '$apiV1/providers/otp/verify';
  static String get providerDraftEndpoint =>
      '$apiV1/providers/registration/draft';
  static String get providerChangePasswordEndpoint =>
      '$apiV1/providers/me/change-password';
  static String get providerIdentityUploadEndpoint => providerIdentityEndpoint;
  static String get providerPersonalEndpoint =>
      '$apiV1/providers/registration/personal';
  static String get providerBusinessEndpoint =>
      '$apiV1/providers/registration/business';
  static String get providerIdentityEndpoint =>
      '$apiV1/providers/registration/identity';
  static String get providerSubmitEndpoint =>
      '$apiV1/providers/registration/submit';
  static String get providerPasswordSetupEndpoint =>
      '$apiV1/providers/password/setup';
  static String get providerLoginEndpoint => '$apiV1/providers/login';
  static String get providerLogoutEndpoint => '$apiV1/providers/logout';
  static String get providerMeEndpoint => '$apiV1/providers/me';
  static String get providerRegisterEndpoint => '$apiV1/providers/register';
  static String get providerListingsEndpoint => '$apiV1/provider/listings';
  static String get providerBookingsEndpoint => '$apiV1/provider/bookings';
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

  // Travel Community Endpoints (FastAPI /api/v1/community)
  static String communityPostEndpoint(int postId) =>
      '$apiV1/community/posts/$postId';
  static String communityPostMediaEndpoint(int postId) =>
      '$apiV1/community/posts/$postId/media';
  static String communityPostMediaItemEndpoint(int postId, int mediaId) =>
      '$apiV1/community/posts/$postId/media/$mediaId';

  // Provider Financial & Settlement Endpoints (Read-Only FastAPI contracts)
  static String get providerEarningsSummaryEndpoint =>
      '$apiV1/providers/me/earnings/summary';
  static String get providerSettlementsEndpoint =>
      '$apiV1/providers/me/settlements';
  static String get paymentsProviderEarningsEndpoint =>
      '$apiV1/payments/provider/earnings';
  static String get paymentsProviderSettlementsEndpoint =>
      '$apiV1/payments/provider/settlements';
  static String get tourGuideProviderEarningsEndpoint =>
      '$apiV1/provider/tour-guides/earnings';

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
