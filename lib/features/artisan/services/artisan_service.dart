import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/models/api_error.dart';
import '../models/artisan_listing_model.dart';
import '../models/artisan_promotion_model.dart';
import '../models/artisan_reservation_model.dart';
import '../models/artisan_review_model.dart';
import '../models/artisan_wishlist_model.dart';
import '../models/showcase_item_model.dart';
import 'artisan_launcher_service.dart';

/// Service connecting directly to CeylonGo Artisan Backend REST APIs.
/// Grounded in FastAPI routers:
/// - app/routers/artisan_listings.py
/// - app/routers/showcase_items.py
/// - app/routers/artisan_reservations.py
/// - app/routers/artisan_reviews.py
/// - app/routers/artisan_wishlists.py
/// - app/routers/promotions.py
class ArtisanService {
  final http.Client _client;
  final SecureStorageService _storage;

  ArtisanService({
    http.Client? client,
    SecureStorageService? storageService,
  })  : _client = client ?? http.Client(),
        _storage = storageService ?? SecureStorageService();

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      return ApiConstants.authHeaders(token);
    }
    return ApiConstants.defaultHeaders;
  }

  /// Parse response error with support for both CeylonGo and FastAPI error bodies.
  ApiError _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body.containsKey('error') && body['error'] is Map) {
          return ApiError.fromJson(response.statusCode, body);
        }
        if (body.containsKey('detail')) {
          final detail = body['detail'];
          if (detail is String) {
            return ApiError(
              statusCode: response.statusCode,
              code: 'API_ERROR',
              message: detail,
            );
          } else if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            if (first is Map && first.containsKey('msg')) {
              return ApiError(
                statusCode: response.statusCode,
                code: 'VALIDATION_ERROR',
                message: first['msg'].toString(),
              );
            }
          }
        }
      }
    } catch (_) {}

    return ApiError.generic(
      response.statusCode,
      'Request failed with status ${response.statusCode}.',
    );
  }

  // ============================================================================
  // 1. Artisan Business Listings
  // ============================================================================

  /// Browse active, approved artisan listings with search, category, district, and pagination.
  Future<ArtisanListingPagination> getListings({
    String? search,
    String? district,
    String? category,
    bool? isFeatured,
    int page = 1,
    int pageSize = 12,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (district != null && district.trim().isNotEmpty && district.toLowerCase() != 'all') {
      queryParams['district'] = district.trim();
    }
    if (category != null && category.trim().isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category.trim();
    }
    if (isFeatured != null) {
      queryParams['is_featured'] = isFeatured.toString();
    }

    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-listings').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanListingPagination.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Get list of available craft categories.
  Future<List<String>> getCategories() async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-listings/categories');
    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        if (list is List) {
          return list.map((e) => e.toString()).toList();
        }
        return [];
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Get list of districts with active artisan listings.
  Future<List<String>> getDistricts() async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-listings/districts');
    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        if (list is List) {
          return list.map((e) => e.toString()).toList();
        }
        return [];
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Discover featured and spotlighted artisan businesses via GET /api/v1/artisan-listings?is_featured=true.
  Future<ArtisanListingPagination> getFeaturedListings({
    String? search,
    String? district,
    String? category,
    int page = 1,
    int pageSize = 12,
  }) {
    return getListings(
      search: search,
      district: district,
      category: category,
      isFeatured: true,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Discover nearby artisan listings sorted by client-side Haversine distance
  /// over GET /api/v1/artisan-listings coordinates.
  Future<ArtisanNearbyListingPagination> getNearbyListings({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    String? category,
    String? search,
    int page = 1,
    int pageSize = 12,
  }) async {
    final res = await getListings(
      search: search,
      category: category,
      page: 1,
      pageSize: 50,
    );

    final enriched = <ArtisanListingSummary>[];
    for (final item in res.items) {
      if (item.latitude != null && item.longitude != null) {
        final dist = ArtisanLauncherService.calculateDistanceKm(
          latitude,
          longitude,
          item.latitude!,
          item.longitude!,
        );
        if (dist <= radiusKm) {
          enriched.add(
            ArtisanListingSummary(
              id: item.id,
              providerProfileId: item.providerProfileId,
              title: item.title,
              craftCategory: item.craftCategory,
              district: item.district,
              city: item.city,
              latitude: item.latitude,
              longitude: item.longitude,
              coverImageUrl: item.coverImageUrl,
              isActive: item.isActive,
              isVerified: item.isVerified,
              isFeatured: item.isFeatured,
              approvalStatus: item.approvalStatus,
              averageRating: item.averageRating,
              totalReviews: item.totalReviews,
              distanceKm: dist,
            ),
          );
        }
      }
    }

    enriched.sort(
      (a, b) => (a.distanceKm ?? 999999).compareTo(b.distanceKm ?? 999999),
    );

    final start = (page - 1) * pageSize;
    final paged = start >= enriched.length
        ? <ArtisanListingSummary>[]
        : enriched.skip(start).take(pageSize).toList();
    final totalPages = enriched.isEmpty ? 0 : (enriched.length / pageSize).ceil();

    return ArtisanNearbyListingPagination(
      items: paged,
      total: enriched.length,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      originLatitude: latitude,
      originLongitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Get full public details of an active, approved artisan listing.
  Future<ArtisanListingResponse> getListingDetails(int id) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-listings/$id');
    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanListingResponse.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  // ============================================================================
  // 2. Showcase Products & Services
  // ============================================================================

  /// Browse active showcase products and services across all artisan businesses.
  Future<ShowcaseItemPagination> getShowcaseItems({
    String? search,
    String? itemType,
    bool? isFeatured,
    int? artisanListingId,
    int page = 1,
    int pageSize = 12,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (itemType != null && itemType.trim().isNotEmpty && itemType.toLowerCase() != 'all') {
      queryParams['item_type'] = itemType.trim().toLowerCase();
    }
    if (isFeatured != null) {
      queryParams['is_featured'] = isFeatured.toString();
    }
    if (artisanListingId != null) {
      queryParams['artisan_listing_id'] = artisanListingId.toString();
    }

    final uri = Uri.parse('${ApiConstants.apiV1}/showcase-items').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ShowcaseItemPagination.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Get details of an active, approved showcase product or service.
  Future<ShowcaseItemResponse> getShowcaseItemDetails(int id) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/showcase-items/$id');
    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ShowcaseItemResponse.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Get all showcase products and services offered by a specific artisan business.
  Future<ShowcaseItemPagination> getListingShowcaseItems(
    int listingId, {
    String? itemType,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (itemType != null && itemType.trim().isNotEmpty && itemType.toLowerCase() != 'all') {
      queryParams['item_type'] = itemType.trim().toLowerCase();
    }

    final uri = Uri.parse(
      '${ApiConstants.apiV1}/artisan-listings/$listingId/showcase-items',
    ).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ShowcaseItemPagination.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  // ============================================================================
  // 3. Artisan Product Pickup Reservations (Phase P0 Step 3 / Phase P2 Step 13)
  // ============================================================================

  /// Reserve a handcrafted product for in-store pickup and in-person payment.
  /// POST /api/v1/artisan-reservations
  Future<ArtisanReservationModel> createReservation(
    ArtisanReservationCreatePayload payload,
  ) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-reservations');
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(payload.toJson()),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanReservationModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// View all product reservations created by the authenticated traveler.
  /// GET /api/v1/artisan-reservations/me
  Future<List<ArtisanReservationModel>> getMyReservations({
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.trim().toLowerCase();
    }

    final uri = Uri.parse(
      '${ApiConstants.apiV1}/artisan-reservations/me',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        if (list is List) {
          return list
              .map((e) => ArtisanReservationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Get details of a single reservation.
  /// GET /api/v1/artisan-reservations/{id}
  Future<ArtisanReservationModel> getReservation(int id) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-reservations/$id');
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanReservationModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Cancel an active reservation and release allocated stock.
  /// POST /api/v1/artisan-reservations/{id}/cancel
  Future<ArtisanReservationModel> cancelReservation(
    int id, {
    String? reason,
  }) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-reservations/$id/cancel');
    final headers = await _getAuthHeaders();
    final payload = ArtisanReservationCancelPayload(cancellationReason: reason);

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(payload.toJson()),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanReservationModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  // ============================================================================
  // 4. Artisan Reviews & Ratings (Phase P1 Step 10 / Phase P2 Step 13)
  // ============================================================================

  /// Get public published reviews for an approved artisan business.
  /// GET /api/v1/artisan-listings/{listing_id}/reviews
  Future<ArtisanReviewPaginationModel> getListingReviews(
    int listingId, {
    int page = 1,
    int pageSize = 10,
    double? rating,
    String sortBy = 'newest',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy,
    };
    if (rating != null) {
      queryParams['rating'] = rating.toString();
    }

    final uri = Uri.parse(
      '${ApiConstants.apiV1}/artisan-listings/$listingId/reviews',
    ).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanReviewPaginationModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Get aggregated review metrics and rating distribution breakdown for an artisan listing.
  /// GET /api/v1/artisan-listings/{listing_id}/reviews/summary
  Future<ArtisanReviewSummaryModel> getListingReviewSummary(int listingId) async {
    final uri = Uri.parse(
      '${ApiConstants.apiV1}/artisan-listings/$listingId/reviews/summary',
    );

    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanReviewSummaryModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Submit a verified traveler review for an artisan business.
  /// Requires an authenticated traveler and a completed reservation.
  /// POST /api/v1/artisan-listings/{listing_id}/reviews
  Future<ArtisanReviewModel> createReview(
    int listingId,
    ArtisanReviewCreatePayload payload,
  ) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-listings/$listingId/reviews');
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(payload.toJson()),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanReviewModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Get all artisan reviews submitted by the authenticated traveler.
  /// GET /api/v1/artisan-reviews/me
  Future<List<ArtisanReviewModel>> getMyReviews({
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    final uri = Uri.parse(
      '${ApiConstants.apiV1}/artisan-reviews/me',
    ).replace(queryParameters: queryParams);
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        if (list is List) {
          return list
              .map((e) => ArtisanReviewModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Update a review previously submitted by the authenticated traveler.
  /// PUT /api/v1/artisan-reviews/{review_id}
  Future<ArtisanReviewModel> updateReview(
    int reviewId,
    ArtisanReviewUpdatePayload payload,
  ) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-reviews/$reviewId');
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: jsonEncode(payload.toJson()),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanReviewModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Delete a review submitted by the authenticated traveler.
  /// DELETE /api/v1/artisan-reviews/{review_id}
  Future<void> deleteReview(int reviewId) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-reviews/$reviewId');
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.delete(uri, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  // ============================================================================
  // 5. Artisan Wishlist & Favorites (Phase P1 Step 11 / Phase P2 Step 13)
  // ============================================================================

  /// Check whether an artisan business is saved in traveler's personal wishlist.
  /// GET /api/v1/artisan-listings/{listing_id}/wishlist/check
  Future<ArtisanWishlistCheckModel> checkWishlistStatus(int listingId) async {
    final uri = Uri.parse(
      '${ApiConstants.apiV1}/artisan-listings/$listingId/wishlist/check',
    );
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanWishlistCheckModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Add an approved, active artisan business to traveler's personal wishlist.
  /// POST /api/v1/artisan-listings/{listing_id}/wishlist
  Future<ArtisanWishlistItemModel> addToWishlist(
    int listingId, {
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-listings/$listingId/wishlist');
    final headers = await _getAuthHeaders();
    final body = notes != null && notes.trim().isNotEmpty ? {'notes': notes.trim()} : {};

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanWishlistItemModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// Remove an artisan business from traveler's personal wishlist.
  /// Correctly handles HTTP 204 No Content.
  /// DELETE /api/v1/artisan-listings/{listing_id}/wishlist
  Future<void> removeFromWishlist(int listingId) async {
    final uri = Uri.parse('${ApiConstants.apiV1}/artisan-listings/$listingId/wishlist');
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.delete(uri, headers: headers);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  /// List authenticated traveler's saved artisan businesses.
  /// GET /api/v1/artisan-wishlists/me
  Future<ArtisanWishlistPaginationModel> getMyWishlist({
    int page = 1,
    int pageSize = 20,
    bool availableOnly = false,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (availableOnly) 'available_only': 'true',
    };
    final uri = Uri.parse(
      '${ApiConstants.apiV1}/artisan-wishlists/me',
    ).replace(queryParameters: queryParams);
    final headers = await _getAuthHeaders();

    try {
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanWishlistPaginationModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }

  // ============================================================================
  // 6. Active Promotions (Phase P1 Step 12 / Phase P2 Step 13)
  // ============================================================================

  /// Browse active, non-expired promotions for workshops and products.
  /// GET /api/v1/promotions
  Future<ArtisanPromotionPaginationModel> getActivePromotions({
    int? listingId,
    int? showcaseItemId,
    int page = 1,
    int pageSize = 12,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (listingId != null) {
      queryParams['artisan_listing_id'] = listingId.toString();
    }
    if (showcaseItemId != null) {
      queryParams['showcase_item_id'] = showcaseItemId.toString();
    }

    final uri = Uri.parse(
      '${ApiConstants.apiV1}/promotions',
    ).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri, headers: ApiConstants.defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ArtisanPromotionPaginationModel.fromJson(data);
      }
      throw _parseError(response);
    } on SocketException {
      throw ApiError.network();
    } on http.ClientException {
      throw ApiError.network();
    }
  }
}

