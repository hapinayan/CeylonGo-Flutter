import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/artisan/models/artisan_reservation_model.dart';
import 'package:ceylongo/features/artisan/models/artisan_review_model.dart';
import 'package:ceylongo/features/artisan/services/artisan_service.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';

class InMemorySecureStorage extends SecureStorageService {
  String? _token = 'mock_jwt_token_12345';

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;
}

void main() {
  group('ArtisanService Phase 2 API Tests', () {
    late InMemorySecureStorage storage;

    setUp(() {
      storage = InMemorySecureStorage();
    });

    test('createReservation sends POST with Auth header and returns parsed model', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/artisan-reservations');
        expect(request.headers['Authorization'], 'Bearer mock_jwt_token_12345');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['showcase_item_id'], 50);
        expect(body['quantity'], 2);
        expect(body['pickup_date'], '2026-12-05');

        return http.Response(
          jsonEncode({
            'id': 77,
            'showcase_item_id': 50,
            'artisan_listing_id': 1,
            'traveler_id': 10,
            'quantity': 2,
            'total_price': 16000.0,
            'currency': 'LKR',
            'reservation_status': 'pending',
            'pickup_date': '2026-12-05',
            'created_at': '2026-11-19T10:00:00Z',
            'updated_at': '2026-11-19T10:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      const payload = ArtisanReservationCreatePayload(
        showcaseItemId: 50,
        quantity: 2,
        pickupDate: '2026-12-05',
      );

      final result = await service.createReservation(payload);
      expect(result.id, 77);
      expect(result.status, ReservationStatus.pending);
      expect(result.totalPrice, 16000.0);
    });

    test('getMyReservations sends GET and filters by status', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/artisan-reservations/me');
        expect(request.url.queryParameters['status'], 'confirmed');
        expect(request.headers['Authorization'], 'Bearer mock_jwt_token_12345');

        return http.Response(
          jsonEncode([
            {
              'id': 88,
              'showcase_item_id': 51,
              'artisan_listing_id': 1,
              'traveler_id': 10,
              'quantity': 1,
              'total_price': 8000.0,
              'currency': 'LKR',
              'reservation_status': 'confirmed',
              'created_at': '2026-11-19T10:00:00Z',
              'updated_at': '2026-11-19T10:00:00Z',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      final list = await service.getMyReservations(status: 'confirmed');
      expect(list.length, 1);
      expect(list.first.id, 88);
      expect(list.first.status, ReservationStatus.confirmed);
    });

    test('cancelReservation sends POST /cancel with cancellation reason', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/artisan-reservations/88/cancel');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['cancellation_reason'], 'Flight rescheduled');

        return http.Response(
          jsonEncode({
            'id': 88,
            'showcase_item_id': 51,
            'artisan_listing_id': 1,
            'traveler_id': 10,
            'quantity': 1,
            'total_price': 8000.0,
            'currency': 'LKR',
            'reservation_status': 'cancelled',
            'cancellation_reason': 'Flight rescheduled',
            'created_at': '2026-11-19T10:00:00Z',
            'updated_at': '2026-11-19T10:05:00Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      final updated = await service.cancelReservation(88, reason: 'Flight rescheduled');
      expect(updated.status, ReservationStatus.cancelled);
      expect(updated.cancellationReason, 'Flight rescheduled');
    });

    test('createReview sends POST with reservation ID and rating', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/artisan-listings/1/reviews');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['reservation_id'], 88);
        expect(body['rating'], 5.0);

        return http.Response(
          jsonEncode({
            'id': 100,
            'listing_reference_id': 1,
            'booking_reference_id': 88,
            'user_id': 10,
            'rating': 5.0,
            'title': 'Masterpiece',
            'is_verified_booking': true,
            'is_published': true,
            'created_at': '2026-11-19T11:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      const payload = ArtisanReviewCreatePayload(
        reservationId: 88,
        rating: 5.0,
        title: 'Masterpiece',
      );

      final review = await service.createReview(1, payload);
      expect(review.id, 100);
      expect(review.rating, 5.0);
      expect(review.isVerifiedBooking, isTrue);
    });

    test('createReview handles 409 Conflict when already reviewed', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'A review has already been submitted for this reservation'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      const payload = ArtisanReviewCreatePayload(
        reservationId: 88,
        rating: 4.0,
      );

      expect(
        () async => await service.createReview(1, payload),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });

    test('removeFromWishlist handles HTTP 204 No Content without error', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/artisan-listings/1/wishlist');
        return http.Response('', 204);
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      await expectLater(service.removeFromWishlist(1), completes);
    });

    test('addToWishlist sends POST and returns parsed WishlistItem', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/artisan-listings/1/wishlist');

        return http.Response(
          jsonEncode({
            'id': 5,
            'user_id': 10,
            'listing_reference_id': 1,
            'artisan_listing_id': 1,
            'created_at': '2026-11-19T10:00:00Z',
            'is_available': true,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      final item = await service.addToWishlist(1);
      expect(item.id, 5);
      expect(item.artisanListingId, 1);
    });

    test('checkWishlistStatus returns boolean is_saved', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/artisan-listings/1/wishlist/check');
        return http.Response(
          jsonEncode({'listing_id': 1, 'is_saved': true, 'wishlist_id': 5}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      final check = await service.checkWishlistStatus(1);
      expect(check.isSaved, isTrue);
      expect(check.wishlistId, 5);
    });

    test('getActivePromotions retrieves active promotions list', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/promotions');
        expect(request.url.queryParameters['artisan_listing_id'], '1');

        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 10,
                'artisan_listing_id': 1,
                'title': 'Heritage Week 15%',
                'promo_code': 'HERITAGE15',
                'discount_percentage': 15.0,
                'currency': 'LKR',
                'start_date': '2026-11-01T00:00:00Z',
                'end_date': '2026-11-30T00:00:00Z',
                'is_active': true,
              }
            ],
            'total': 1,
            'page': 1,
            'page_size': 12,
            'total_pages': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: mockClient, storageService: storage);
      final promoPagination = await service.getActivePromotions(listingId: 1);
      expect(promoPagination.items.length, 1);
      expect(promoPagination.items.first.promoCode, 'HERITAGE15');
      expect(promoPagination.items.first.discountBadge, '15% OFF');
    });
  });
}

