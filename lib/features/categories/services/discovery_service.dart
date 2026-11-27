import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/discovery_models.dart';

/// Service connecting Homestays, Activities, Tour Guides, and Bike/Bicycle Rentals
/// directly to the CeylonGo Academic MVP FastAPI backend.
class DiscoveryService {
  final ApiClient _api;

  DiscoveryService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // ==========================================================================
  // Homestays
  // ==========================================================================

  Future<List<HomestayListingModel>> searchHomestays({
    String? destination,
    String? minPrice,
    String? maxPrice,
    String? propertyType,
    int? guests,
    int limit = 20,
    int? beforeId,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (destination != null && destination.trim().isNotEmpty)
        'destination': destination.trim(),
      if (minPrice != null && minPrice.isNotEmpty) 'min_price': minPrice,
      if (maxPrice != null && maxPrice.isNotEmpty) 'max_price': maxPrice,
      if (propertyType != null && propertyType.isNotEmpty)
        'property_type': propertyType,
      if (guests != null) 'guests': guests.toString(),
      if (beforeId != null) 'before_id': beforeId.toString(),
    };

    final data = await _api.get(
      ApiConstants.homestaysEndpoint,
      queryParameters: params,
      auth: false,
    );
    return _parseItems(data, HomestayListingModel.fromJson);
  }

  Future<HomestayListingModel> getHomestayDetail(int listingId) async {
    final data = await _api.get(
      '${ApiConstants.homestaysEndpoint}/$listingId',
      auth: false,
    );
    return HomestayListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<HomestayQuoteModel> checkHomestayAvailability({
    required int listingId,
    required String checkIn,
    required String checkOut,
    int guests = 1,
    int? roomId,
  }) async {
    final params = <String, String>{
      'check_in': checkIn,
      'check_out': checkOut,
      'guests': guests.toString(),
      if (roomId != null) 'room_id': roomId.toString(),
    };
    final data = await _api.get(
      '${ApiConstants.homestaysEndpoint}/$listingId/availability',
      queryParameters: params,
      auth: false,
    );
    return HomestayQuoteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<HomestayListingModel>> getHomestayWishlist() async {
    final data = await _api.get(ApiConstants.homestaysWishlistEndpoint);
    return _parseItems(data, HomestayListingModel.fromJson);
  }

  Future<bool> setHomestayWishlist(int listingId, {required bool save}) async {
    final url = '${ApiConstants.homestaysEndpoint}/$listingId/wishlist';
    if (save) {
      await _api.put(url);
      return true;
    } else {
      await _api.delete(url);
      return false;
    }
  }

  // ==========================================================================
  // Adventure Activities
  // ==========================================================================

  Future<List<ActivityListingModel>> searchActivities({
    String? destination,
    String? category,
    String? date,
    int? participants,
    String sort = 'newest',
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (destination != null && destination.trim().isNotEmpty)
        'destination': destination.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (date != null && date.isNotEmpty) 'date': date,
      if (participants != null) 'participants': participants.toString(),
    };

    final data = await _api.get(
      ApiConstants.activitiesEndpoint,
      queryParameters: params,
      auth: false,
    );
    return _parseItems(data, ActivityListingModel.fromJson);
  }

  Future<ActivityListingModel> getActivityDetail(int listingId) async {
    final data = await _api.get(
      '${ApiConstants.activitiesEndpoint}/$listingId',
      auth: false,
    );
    return ActivityListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ActivitySlotModel>> getActivityAvailability({
    required int listingId,
    String? date,
    int? participants,
  }) async {
    final params = <String, String>{
      if (date != null && date.isNotEmpty) 'date': date,
      if (participants != null) 'participants': participants.toString(),
    };
    final data = await _api.get(
      '${ApiConstants.activitiesEndpoint}/$listingId/availability',
      queryParameters: params,
      auth: false,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ActivitySlotModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<ActivityListingModel>> getActivityWishlist() async {
    final data = await _api.get(ApiConstants.activitiesWishlistEndpoint);
    return _parseItems(data, ActivityListingModel.fromJson);
  }

  Future<bool> setActivityWishlist(int listingId, {required bool save}) async {
    final url = '${ApiConstants.activitiesEndpoint}/$listingId/wishlist';
    if (save) {
      await _api.put(url);
      return true;
    } else {
      await _api.delete(url);
      return false;
    }
  }

  // ==========================================================================
  // Tour Guides
  // ==========================================================================

  Future<List<TourGuideListingModel>> searchTourGuides({
    String? destination,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (destination != null && destination.trim().isNotEmpty)
        'destination': destination.trim(),
    };
    final data = await _api.get(
      ApiConstants.tourGuidesEndpoint,
      queryParameters: params,
      auth: false,
    );
    return _parseItems(data, TourGuideListingModel.fromJson);
  }

  Future<TourGuideListingModel> getTourGuideDetail(int listingId) async {
    final data = await _api.get(
      '${ApiConstants.tourGuidesEndpoint}/$listingId',
      auth: false,
    );
    return TourGuideListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<GuideSlotModel>> getTourGuideAvailability({
    required int listingId,
    required int packageId,
    String? date,
    int participants = 1,
  }) async {
    final params = <String, String>{
      'package_id': packageId.toString(),
      'participants': participants.toString(),
      if (date != null && date.isNotEmpty) 'date': date,
    };
    final data = await _api.get(
      '${ApiConstants.tourGuidesEndpoint}/$listingId/availability',
      queryParameters: params,
      auth: false,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(GuideSlotModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<TourGuideListingModel>> getTourGuideWishlist() async {
    final data = await _api.get(ApiConstants.tourGuidesWishlistEndpoint);
    return _parseItems(data, TourGuideListingModel.fromJson);
  }

  Future<bool> setTourGuideWishlist(int listingId, {required bool save}) async {
    final url = '${ApiConstants.tourGuidesEndpoint}/$listingId/wishlist';
    if (save) {
      await _api.put(url);
      return true;
    } else {
      await _api.delete(url);
      return false;
    }
  }

  // ==========================================================================
  // Bike & Bicycle Rentals
  // ==========================================================================

  Future<List<RentalVehicleModel>> searchRentals({
    String? district,
    String? city,
    String? vehicleType, // 'bike' | 'bicycle'
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (district != null && district.trim().isNotEmpty)
        'district': district.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (vehicleType != null && vehicleType.isNotEmpty)
        'vehicle_type': vehicleType,
    };
    final data = await _api.get(
      ApiConstants.rentalVehiclesEndpoint,
      queryParameters: params,
      auth: false,
    );
    return _parseItems(data, RentalVehicleModel.fromJson);
  }

  Future<RentalVehicleModel> getRentalDetail(int vehicleId) async {
    final data = await _api.get(
      '${ApiConstants.rentalVehiclesEndpoint}/$vehicleId',
      auth: false,
    );
    return RentalVehicleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RentalQuoteModel> calculateRentalQuote({
    required int vehicleId,
    required DateTime pickupAt,
    required DateTime returnAt,
    int quantity = 1,
  }) async {
    final data = await _api.post(
      '${ApiConstants.rentalVehiclesEndpoint}/$vehicleId/calculate-quote',
      body: {
        'pickup_at': pickupAt.toUtc().toIso8601String(),
        'return_at': returnAt.toUtc().toIso8601String(),
        'quantity': quantity,
      },
      auth: false,
    );
    return RentalQuoteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<RentalVehicleModel>> getRentalWishlist() async {
    final data = await _api.get(ApiConstants.rentalWishlistEndpoint);
    return _parseItems(data, RentalVehicleModel.fromJson);
  }

  Future<bool> setRentalWishlist(int vehicleId, {required bool save}) async {
    final url = '${ApiConstants.rentalWishlistEndpoint}/$vehicleId';
    if (save) {
      await _api.post(url);
      return true;
    } else {
      await _api.delete(url);
      return false;
    }
  }

  List<T> _parseItems<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    }
    return [];
  }
}
