import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/features/artisan/models/artisan_promotion_model.dart';
import 'package:ceylongo/features/artisan/models/artisan_reservation_model.dart';
import 'package:ceylongo/features/artisan/models/artisan_review_model.dart';
import 'package:ceylongo/features/artisan/models/artisan_wishlist_model.dart';

void main() {
  group('ArtisanReservationModel Tests', () {
    test('ReservationStatus enum mappings and visual properties', () {
      expect(ReservationStatus.fromString('pending'), ReservationStatus.pending);
      expect(ReservationStatus.fromString('confirmed'), ReservationStatus.confirmed);
      expect(ReservationStatus.fromString('ready_for_pickup'), ReservationStatus.readyForPickup);
      expect(ReservationStatus.fromString('completed'), ReservationStatus.completed);
      expect(ReservationStatus.fromString('cancelled'), ReservationStatus.cancelled);
      expect(ReservationStatus.fromString('expired'), ReservationStatus.expired);
      expect(ReservationStatus.fromString('unknown_status'), ReservationStatus.pending);

      expect(ReservationStatus.pending.code, 'pending');
      expect(ReservationStatus.pending.label, 'Pending Approval');
      expect(ReservationStatus.readyForPickup.label, 'Ready for Pickup');
      expect(ReservationStatus.completed.label, 'Completed');
      expect(ReservationStatus.cancelled.label, 'Cancelled');
      expect(ReservationStatus.expired.label, 'Expired');

      expect(ReservationStatus.pending.icon, Icons.hourglass_top_outlined);
      expect(ReservationStatus.confirmed.icon, Icons.check_circle_outline);
      expect(ReservationStatus.readyForPickup.icon, Icons.shopping_bag_outlined);
      expect(ReservationStatus.completed.icon, Icons.task_alt);
      expect(ReservationStatus.cancelled.icon, Icons.cancel_outlined);
    });

    test('ArtisanReservationModel parses valid JSON and computes flags correctly', () {
      final json = {
        'id': 10,
        'showcase_item_id': 50,
        'artisan_listing_id': 1,
        'traveler_id': 20,
        'quantity': 2,
        'total_price': 15000.0,
        'currency': 'LKR',
        'reservation_status': 'confirmed',
        'pickup_date': '2026-11-25',
        'special_notes': 'Please pack in eco-friendly banana leaf paper',
        'expires_at': '2026-11-26T18:00:00Z',
        'cancelled_by': null,
        'cancellation_reason': null,
        'created_at': '2026-11-19T10:00:00Z',
        'updated_at': '2026-11-19T10:30:00Z',
        'item_title': 'Carved Peacock Mask',
        'item_image_url': '/static/uploads/mask1.jpg',
        'listing_title': 'Ambalangoda Mask Workshop',
        'provider_business_name': 'Ariyapala Crafts',
        'traveler_name': 'John Traveler',
        'traveler_email': 'john@example.com',
      };

      final model = ArtisanReservationModel.fromJson(json);

      expect(model.id, 10);
      expect(model.showcaseItemId, 50);
      expect(model.artisanListingId, 1);
      expect(model.travelerId, 20);
      expect(model.quantity, 2);
      expect(model.totalPrice, 15000.0);
      expect(model.currency, 'LKR');
      expect(model.status, ReservationStatus.confirmed);
      expect(model.pickupDate, '2026-11-25');
      expect(model.specialNotes, 'Please pack in eco-friendly banana leaf paper');
      expect(model.itemTitle, 'Carved Peacock Mask');
      expect(model.isCancellable, isTrue);
      expect(model.isEligibleForReview, isFalse);
      expect(model.fullItemImageUrl, contains('/static/uploads/mask1.jpg'));
    });

    test('isCancellable is true for pending/confirmed/ready, false for completed/cancelled/expired', () {
      final baseJson = {
        'id': 1,
        'showcase_item_id': 1,
        'artisan_listing_id': 1,
        'traveler_id': 1,
        'quantity': 1,
        'total_price': 1000.0,
        'currency': 'LKR',
        'created_at': '2026-11-19T10:00:00Z',
        'updated_at': '2026-11-19T10:00:00Z',
      };

      expect(
        ArtisanReservationModel.fromJson({...baseJson, 'reservation_status': 'pending'}).isCancellable,
        isTrue,
      );
      expect(
        ArtisanReservationModel.fromJson({...baseJson, 'reservation_status': 'confirmed'}).isCancellable,
        isTrue,
      );
      expect(
        ArtisanReservationModel.fromJson({...baseJson, 'reservation_status': 'ready_for_pickup'}).isCancellable,
        isTrue,
      );
      expect(
        ArtisanReservationModel.fromJson({...baseJson, 'reservation_status': 'completed'}).isCancellable,
        isFalse,
      );
      expect(
        ArtisanReservationModel.fromJson({...baseJson, 'reservation_status': 'completed'}).isEligibleForReview,
        isTrue,
      );
      expect(
        ArtisanReservationModel.fromJson({...baseJson, 'reservation_status': 'cancelled'}).isCancellable,
        isFalse,
      );
      expect(
        ArtisanReservationModel.fromJson({...baseJson, 'reservation_status': 'expired'}).isCancellable,
        isFalse,
      );
    });

    test('Payload serializes correctly', () {
      const createPayload = ArtisanReservationCreatePayload(
        showcaseItemId: 5,
        quantity: 3,
        pickupDate: '2026-12-01',
        specialNotes: ' Urgent pickup ',
      );
      final json = createPayload.toJson();
      expect(json['showcase_item_id'], 5);
      expect(json['quantity'], 3);
      expect(json['pickup_date'], '2026-12-01');
      expect(json['special_notes'], 'Urgent pickup');

      const cancelPayload = ArtisanReservationCancelPayload(
        cancellationReason: ' Travel plan changed ',
      );
      final cancelJson = cancelPayload.toJson();
      expect(cancelJson['cancellation_reason'], 'Travel plan changed');
    });
  });

  group('ArtisanReviewModel Tests', () {
    test('Review models parse JSON and handle star breakdown', () {
      final reviewJson = {
        'id': 101,
        'listing_reference_id': 1,
        'booking_reference_id': 10,
        'user_id': 20,
        'user_name': 'Sarah Traveler',
        'rating': 4.8,
        'title': 'Masterpiece craftsmanship',
        'comment': 'Met the artisan master and saw the Kaduru woodcarving process.',
        'is_verified_booking': true,
        'is_published': true,
        'created_at': '2026-11-19T12:00:00Z',
      };

      final review = ArtisanReviewModel.fromJson(reviewJson);
      expect(review.id, 101);
      expect(review.rating, 4.8);
      expect(review.isVerifiedBooking, isTrue);
      expect(review.userName, 'Sarah Traveler');

      final summaryJson = {
        'listing_id': 1,
        'listing_title': 'Ambalangoda Masks',
        'average_rating': 4.75,
        'total_reviews': 12,
        'rating_breakdown': {'5': 9, '4': 2, '3': 1, '2': 0, '1': 0},
        'verified_reviews_count': 10,
      };

      final summary = ArtisanReviewSummaryModel.fromJson(summaryJson);
      expect(summary.listingId, 1);
      expect(summary.averageRating, 4.75);
      expect(summary.totalReviews, 12);
      expect(summary.ratingBreakdown['5'], 9);
      expect(summary.ratingBreakdown['4'], 2);
      expect(summary.verifiedReviewsCount, 10);
    });

    test('Review payloads serialize correctly', () {
      const createPayload = ArtisanReviewCreatePayload(
        reservationId: 15,
        rating: 5.0,
        title: ' Excellent workshop ',
        comment: ' Loved the experience ',
      );
      final json = createPayload.toJson();
      expect(json['reservation_id'], 15);
      expect(json['rating'], 5.0);
      expect(json['title'], 'Excellent workshop');
      expect(json['comment'], 'Loved the experience');

      const updatePayload = ArtisanReviewUpdatePayload(
        rating: 4.5,
        title: ' Updated Title ',
      );
      final updateJson = updatePayload.toJson();
      expect(updateJson['rating'], 4.5);
      expect(updateJson['title'], 'Updated Title');
      expect(updateJson.containsKey('comment'), isFalse);
    });
  });

  group('ArtisanWishlistModel Tests', () {
    test('Wishlist models parse JSON and calculate cover URLs', () {
      final json = {
        'id': 1,
        'user_id': 5,
        'listing_reference_id': 2,
        'artisan_listing_id': 10,
        'notes': 'Visit on Galle southern trip',
        'created_at': '2026-11-19T08:00:00Z',
        'is_available': true,
        'listing': {
          'id': 10,
          'provider_profile_id': 3,
          'title': 'Kandy Brassware Studio',
          'craft_category': 'Brassware & Metalwork',
          'district': 'Kandy',
          'city': 'Pilimathalawa',
          'cover_image_url': '/static/brass.jpg',
          'approval_status': 'approved',
          'is_active': true,
          'average_rating': 4.9,
          'total_reviews': 8,
        },
      };

      final item = ArtisanWishlistItemModel.fromJson(json);
      expect(item.id, 1);
      expect(item.artisanListingId, 10);
      expect(item.isAvailable, isTrue);
      expect(item.listing?.title, 'Kandy Brassware Studio');
      expect(item.listing?.fullCoverImageUrl, contains('/static/brass.jpg'));

      final checkJson = {'listing_id': 10, 'is_saved': true, 'wishlist_id': 1};
      final check = ArtisanWishlistCheckModel.fromJson(checkJson);
      expect(check.listingId, 10);
      expect(check.isSaved, isTrue);
      expect(check.wishlistId, 1);
    });
  });

  group('ArtisanPromotionModel Tests', () {
    test('Promotion models compute discountBadge correctly', () {
      final promoPercentage = ArtisanPromotionModel(
        id: 1,
        artisanListingId: 10,
        title: 'Southern Mask Festival Special',
        promoCode: 'MASK20',
        discountPercentage: 20.0,
        currency: 'LKR',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
        isActive: true,
      );
      expect(promoPercentage.discountBadge, '20% OFF');

      final promoFixed = ArtisanPromotionModel(
        id: 2,
        artisanListingId: 10,
        title: 'Fixed Craft Discount',
        promoCode: 'SAVE500',
        discountFixedAmount: 500.0,
        currency: 'LKR',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
        isActive: true,
      );
      expect(promoFixed.discountBadge, 'LKR 500 OFF');
    });
  });
}

