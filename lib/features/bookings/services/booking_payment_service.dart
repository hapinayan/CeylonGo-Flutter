import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/booking_models.dart';

/// Service handling Traveler Bookings and Idempotent Payment Selection.
class BookingPaymentService {
  final ApiClient _api;

  BookingPaymentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// POST /api/v1/homestays/{listing_id}/bookings
  Future<BookingRecord> createHomestayBooking({
    required int listingId,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int roomId,
    required String requestKey,
    String? expectedTotal,
  }) async {
    final payload = <String, dynamic>{
      'check_in': checkIn,
      'check_out': checkOut,
      'guests': guests,
      'room_id': roomId,
      'request_key': requestKey,
      if (expectedTotal != null) 'expected_total': expectedTotal,
    };

    final data = await _api.post(
      '${ApiConstants.homestaysEndpoint}/$listingId/bookings',
      body: payload,
    );
    return BookingRecord.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/v1/bookings (Adventure, Guide, Bike/Bicycle Rental)
  Future<BookingRecord> createBooking({
    required int listingId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int quantity,
    required String requestKey,
    int? slotId,
    String? expectedTotal,
    bool motorcycleLicenseConfirmed = false,
    String? licenseValidUntil,
  }) async {
    final payload = <String, dynamic>{
      'listing_id': listingId,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
      'quantity': quantity,
      'request_key': requestKey,
      if (slotId != null) 'slot_id': slotId,
      if (expectedTotal != null) 'expected_total': expectedTotal,
      'motorcycle_license_confirmed': motorcycleLicenseConfirmed,
      if (licenseValidUntil != null) 'license_valid_until': licenseValidUntil,
    };

    final data = await _api.post(ApiConstants.bookingsEndpoint, body: payload);
    return BookingRecord.fromJson(data as Map<String, dynamic>);
  }

  /// GET /api/v1/bookings/my
  Future<List<BookingRecord>> getMyBookings({
    int limit = 50,
    int? beforeId,
    String? category,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      if (beforeId != null) 'before_id': beforeId.toString(),
      if (category != null && category.isNotEmpty) 'category': category,
    };

    final data = await _api.get(
      ApiConstants.myBookingsEndpoint,
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

  /// GET /api/v1/bookings/{booking_id}
  Future<BookingRecord> getBookingDetails(int bookingId) async {
    final data = await _api.get('${ApiConstants.bookingsEndpoint}/$bookingId');
    return BookingRecord.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /api/v1/bookings/{booking_id}/status
  Future<BookingRecord> updateBookingStatus(
    int bookingId, {
    required String toStatus,
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

  /// POST /api/v1/payments/simulate
  /// Preserves request_key and attempt_no across retries for idempotency.
  Future<PaymentRecord> processSimulatedPayment({
    required int bookingId,
    required String requestKey,
    required int attemptNo,
    required String simulateOutcome, // 'success' | 'failure'
  }) async {
    final data = await _api.post(
      ApiConstants.simulatedPaymentEndpoint,
      body: {
        'booking_id': bookingId,
        'request_key': requestKey,
        'attempt_no': attemptNo,
        'simulate_outcome': simulateOutcome,
      },
    );
    return PaymentRecord.fromJson(data as Map<String, dynamic>);
  }

  /// POST /api/v1/payments/at-location
  /// Preserves request_key across retries for idempotency.
  Future<PaymentRecord> processAtLocationPayment({
    required int bookingId,
    required String requestKey,
  }) async {
    final data = await _api.post(
      ApiConstants.atLocationPaymentEndpoint,
      body: {
        'booking_id': bookingId,
        'request_key': requestKey,
      },
    );
    return PaymentRecord.fromJson(data as Map<String, dynamic>);
  }
}
