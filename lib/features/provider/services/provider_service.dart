import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/models/api_error.dart';
import '../../auth/models/user_model.dart';
import '../../bookings/models/booking_models.dart';
import '../models/provider_models.dart';

/// Service connecting Service Provider Onboarding, Verification Status,
/// Listings, Availability/Packages/Products, and Bookings to the FastAPI backend.
class ProviderService {
  final ApiClient _api;
  final SecureStorageService _storage;
  final http.Client _client;

  ProviderService({
    ApiClient? apiClient,
    SecureStorageService? storageService,
    http.Client? client,
  })  : _api = apiClient ?? ApiClient(),
        _storage = storageService ?? SecureStorageService(),
        _client = client ?? http.Client();

  // ==========================================================================
  // Provider Auth & Onboarding
  // ==========================================================================

  Future<String> sendOtp(String email) async {
    final data = await _api.post(
      ApiConstants.providerOtpSendEndpoint,
      body: {'email': email.trim()},
      auth: false,
    );
    return (data as Map<String, dynamic>)['message']?.toString() ??
        'Verification code sent.';
  }

  Future<ProviderOtpVerifyResult> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _api.post(
      ApiConstants.providerOtpVerifyEndpoint,
      body: {'email': email.trim(), 'otp': otp.trim()},
      auth: false,
    );
    return ProviderOtpVerifyResult.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _authWithToken({
    required String method,
    required String url,
    required String authToken,
    Object? body,
  }) async {
    final uri = Uri.parse(url);
    final headers = ApiConstants.authHeaders(authToken);
    late http.Response res;
    if (method == 'GET') {
      res = await _client.get(uri, headers: headers);
    } else if (method == 'PUT') {
      res = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } else {
      res = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.trim().isEmpty ? null : jsonDecode(res.body);
    }
    throw ApiError.fromJson(
      res.statusCode,
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<ProviderRegistrationDraft> getRegistrationDraft(
    String authorizationToken,
  ) async {
    final data = await _authWithToken(
      method: 'GET',
      url: ApiConstants.providerDraftEndpoint,
      authToken: authorizationToken,
    );
    return ProviderRegistrationDraft.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderRegistrationDraft> savePersonalDetails(
    String authorizationToken,
    Map<String, dynamic> body,
  ) async {
    final data = await _authWithToken(
      method: 'PUT',
      url: ApiConstants.providerPersonalEndpoint,
      authToken: authorizationToken,
      body: body,
    );
    return ProviderRegistrationDraft.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderRegistrationDraft> saveBusinessDetails(
    String authorizationToken,
    Map<String, dynamic> body,
  ) async {
    final data = await _authWithToken(
      method: 'PUT',
      url: ApiConstants.providerBusinessEndpoint,
      authToken: authorizationToken,
      body: body,
    );
    return ProviderRegistrationDraft.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderRegistrationDraft> uploadIdentityDocuments(
    String authorizationToken, {
    String? selfiePath,
    String? nicFrontPath,
    String? nicBackPath,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.providerIdentityEndpoint),
    );
    req.headers['Authorization'] = 'Bearer $authorizationToken';

    if (selfiePath != null && selfiePath.isNotEmpty && File(selfiePath).existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('selfie', selfiePath));
    }
    if (nicFrontPath != null &&
        nicFrontPath.isNotEmpty &&
        File(nicFrontPath).existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('nic_front', nicFrontPath));
    }
    if (nicBackPath != null &&
        nicBackPath.isNotEmpty &&
        File(nicBackPath).existsSync()) {
      req.files.add(await http.MultipartFile.fromPath('nic_back', nicBackPath));
    }

    final streamed = await _client.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ProviderRegistrationDraft.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw ApiError.fromJson(
      res.statusCode,
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> setupPassword(
    String authorizationToken, {
    required String password,
    required String confirmPassword,
  }) async {
    await _authWithToken(
      method: 'POST',
      url: ApiConstants.providerPasswordSetupEndpoint,
      authToken: authorizationToken,
      body: {'password': password, 'confirm_password': confirmPassword},
    );
  }

  Future<String> submitRegistration(String authorizationToken) async {
    final data = await _authWithToken(
      method: 'POST',
      url: ApiConstants.providerSubmitEndpoint,
      authToken: authorizationToken,
    );
    return (data as Map<String, dynamic>)['message']?.toString() ??
        'Registration submitted for verification.';
  }

  Future<UserModel> loginProvider({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      ApiConstants.providerLoginEndpoint,
      body: {'email': email.trim(), 'password': password},
      auth: false,
    );
    final map = data as Map<String, dynamic>;
    final token = map['access_token']?.toString() ?? '';
    final userJson = (map['user'] as Map<String, dynamic>?) ?? {};
    final user = UserModel.fromJson({
      ...userJson,
      'role': userJson['role'] ?? 'provider',
    });
    if (token.isNotEmpty) {
      await _storage.saveToken(token);
      await _storage.saveUser(user);
    }
    return user;
  }

  Future<void> logoutProvider() async {
    try {
      await _api.post(ApiConstants.providerLogoutEndpoint);
    } catch (_) {}
    await _storage.clear();
  }

  Future<ProviderProfileModel> getMyProviderProfile() async {
    final data = await _api.get(ApiConstants.providerMeEndpoint);
    return ProviderProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderProfileModel> registerBasicProfile({
    required String businessName,
    required String phone,
    required String district,
  }) async {
    final data = await _api.post(
      ApiConstants.providerRegisterEndpoint,
      body: {
        'business_name': businessName.trim(),
        'phone': phone.trim(),
        'district': district.trim(),
      },
    );
    return ProviderProfileModel.fromJson(data as Map<String, dynamic>);
  }

  // ==========================================================================
  // Provider Listings Management
  // ==========================================================================

  Future<List<ProviderListingModel>> getMyListings() async {
    final data = await _api.get(ApiConstants.providerListingsEndpoint);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProviderListingModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<ProviderListingModel> createListing({
    required String category,
    required String title,
    required String description,
    required String district,
    required String locality,
    required String price,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _api.post(
      ApiConstants.providerListingsEndpoint,
      body: {
        'category': category,
        'title': title.trim(),
        'description': description.trim(),
        'district': district.trim(),
        'locality': locality.trim(),
        'price': price.trim(),
        'currency': 'LKR',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return ProviderListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderListingModel> submitListingForReview(int listingId) async {
    final data = await _api.post(
      '${ApiConstants.providerListingsEndpoint}/$listingId/submit',
    );
    return ProviderListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderListingModel> setListingPublished(
    int listingId, {
    required bool publish,
  }) async {
    final action = publish ? 'publish' : 'unpublish';
    final data = await _api.post(
      '${ApiConstants.providerListingsEndpoint}/$listingId/$action',
    );
    return ProviderListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderUnitModel> addRoom(
    int listingId, {
    required String label,
    int capacity = 2,
    String? roomType,
    String? nightlyPrice,
  }) async {
    final data = await _api.post(
      '${ApiConstants.providerListingsEndpoint}/$listingId/rooms',
      body: {
        'label': label.trim(),
        'capacity': capacity,
        if (roomType != null && roomType.isNotEmpty) 'room_type': roomType,
        if (nightlyPrice != null && nightlyPrice.isNotEmpty)
          'nightly_price': nightlyPrice,
      },
    );
    return ProviderUnitModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ProviderUnitModel> addInventoryUnit(
    int listingId, {
    required String label,
    int capacity = 1,
  }) async {
    final data = await _api.post(
      '${ApiConstants.providerListingsEndpoint}/$listingId/units',
      body: {'label': label.trim(), 'capacity': capacity},
    );
    return ProviderUnitModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ProviderAvailabilitySlot>> getAvailabilitySlots(int listingId) async {
    final data = await _api.get(
      '${ApiConstants.providerListingsEndpoint}/$listingId/availability',
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProviderAvailabilitySlot.fromJson)
          .toList();
    }
    return [];
  }

  Future<ProviderAvailabilitySlot> createAvailabilitySlot(
    int listingId, {
    required int unitId,
    required DateTime startsAt,
    required DateTime endsAt,
    int capacity = 1,
    bool isOpen = true,
  }) async {
    final data = await _api.post(
      '${ApiConstants.providerListingsEndpoint}/$listingId/availability',
      body: {
        'unit_id': unitId,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'capacity': capacity,
        'is_open': isOpen,
      },
    );
    return ProviderAvailabilitySlot.fromJson(data as Map<String, dynamic>);
  }

  // ==========================================================================
  // Provider Bookings
  // ==========================================================================

  Future<List<BookingRecord>> getProviderBookings({
    String? status,
    String? category,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final data = await _api.get(
      ApiConstants.providerBookingsEndpoint,
      queryParameters: params,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(BookingRecord.fromJson)
          .toList();
    }
    return [];
  }

  Future<BookingRecord> getProviderBookingDetails(int bookingId) async {
    final data =
        await _api.get('${ApiConstants.providerBookingsEndpoint}/$bookingId');
    return BookingRecord.fromJson(data as Map<String, dynamic>);
  }

  Future<BookingRecord> updateBookingStatus(
    int bookingId, {
    required String toStatus, // 'confirmed' | 'rejected' | 'completed' | 'cancelled'
    String? reason,
  }) async {
    final data = await _api.patch(
      '${ApiConstants.bookingsEndpoint}/$bookingId/status',
      body: {
        'to_status': toStatus,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return BookingRecord.fromJson(data as Map<String, dynamic>);
  }
}
