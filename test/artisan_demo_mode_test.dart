import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/features/artisan/models/artisan_reservation_model.dart';
import 'package:ceylongo/features/artisan/models/artisan_review_model.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/artisan/widgets/artisan_demo_banner.dart';

void main() {
  group('ArtisanDemoService Offline Unit Tests', () {
    late ArtisanDemoService service;

    setUp(() {
      ArtisanDemoService.isDemoMode = true;
      service = ArtisanDemoService.instance;
      service.resetToDefaults();
    });

    tearDown(() {
      ArtisanDemoService.isDemoMode = false;
      service.resetToDefaults();
    });

    test('getCategories and getDistricts return verified mock collections', () async {
      final categories = await service.getCategories();
      expect(categories, contains('Woodcarving & Masks'));
      expect(categories, contains('Jewelry & Metalcraft'));

      final districts = await service.getDistricts();
      expect(districts, contains('Galle'));
      expect(districts, contains('Kandy'));
    });

    test('getListings filters dynamically by category, district, and search query', () async {
      final all = await service.getListings();
      expect(all.total, greaterThanOrEqualTo(3));

      final galleListings = await service.getListings(district: 'Galle');
      expect(galleListings.total, equals(1));
      expect(galleListings.items.first.title, contains('Ambalangoda'));

      final maskListings = await service.getListings(category: 'Woodcarving & Masks');
      expect(maskListings.total, equals(1));

      final searchListings = await service.getListings(search: 'brass');
      expect(searchListings.total, equals(1));
      expect(searchListings.items.first.title, contains('Brass'));
    });

    test('getFeaturedListings returns only featured studios', () async {
      final featured = await service.getFeaturedListings();
      expect(featured.items.every((l) => l.isFeatured), isTrue);
    });

    test('createReservation decrements item stock in memory and creates reservation', () async {
      final initialItem = await service.getShowcaseItemDetails(50);
      final initialStock = initialItem.stockQuantity;
      expect(initialStock, equals(5));

      final reservation = await service.createReservation(
        const ArtisanReservationCreatePayload(
          showcaseItemId: 50,
          quantity: 2,
          pickupDate: '2026-11-26T10:00:00Z',
          specialNotes: 'Please hold for noon pickup',
        ),
      );

      expect(reservation.status, equals(ReservationStatus.pending));
      expect(reservation.quantity, equals(2));
      expect(reservation.totalPrice, equals(17000.0));

      final updatedItem = await service.getShowcaseItemDetails(50);
      expect(updatedItem.stockQuantity, equals(3)); // 5 - 2 = 3
    });

    test('cancelReservation transitions status to cancelled and restores stock quantity', () async {
      // First create reservation of 2 items
      final res = await service.createReservation(
        const ArtisanReservationCreatePayload(
          showcaseItemId: 50,
          quantity: 2,
          pickupDate: '2026-11-26T10:00:00Z',
        ),
      );
      final midItem = await service.getShowcaseItemDetails(50);
      expect(midItem.stockQuantity, equals(3));

      // Cancel reservation
      final cancelled = await service.cancelReservation(
        res.id,
        reason: 'Change of travel plans',
      );
      expect(cancelled.status, equals(ReservationStatus.cancelled));

      // Check stock restored
      final finalItem = await service.getShowcaseItemDetails(50);
      expect(finalItem.stockQuantity, equals(5)); // Restored back to 5
    });

    test('reviews and rating summary recalculate dynamically in memory', () async {
      final initialSummary = await service.getListingReviewSummary(1);
      final initialCount = initialSummary.totalReviews;

      final newReview = await service.createReview(
        1,
        const ArtisanReviewCreatePayload(
          reservationId: 101,
          rating: 5.0,
          comment: 'Outstanding authentic experience!',
        ),
      );
      expect(newReview.rating, equals(5.0));

      final updatedSummary = await service.getListingReviewSummary(1);
      expect(updatedSummary.totalReviews, equals(initialCount + 1));
      expect(updatedSummary.averageRating, greaterThan(4.0));
    });

    test('wishlist additions and removals update in-memory state', () async {
      // Listing 1 is initially in wishlist
      final check1 = await service.checkWishlistStatus(1);
      expect(check1.isSaved, isTrue);

      // Remove from wishlist
      await service.removeFromWishlist(1);
      final checkAfterRemove = await service.checkWishlistStatus(1);
      expect(checkAfterRemove.isSaved, isFalse);

      // Add Listing 2 to wishlist
      await service.addToWishlist(2);
      final check2 = await service.checkWishlistStatus(2);
      expect(check2.isSaved, isTrue);
    });
  });

  group('ArtisanDemoBanner Widget Tests', () {
    testWidgets('renders demo banner when isDemoMode is true', (tester) async {
      ArtisanDemoService.isDemoMode = true;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtisanDemoBanner(),
          ),
        ),
      );

      expect(find.text('DEMO MODE'), findsOneWidget);
      expect(find.text('In-Memory Offline Simulation • Zero Database Calls'), findsOneWidget);
      ArtisanDemoService.isDemoMode = false;
    });

    testWidgets('does not render banner when isDemoMode is false', (tester) async {
      ArtisanDemoService.isDemoMode = false;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtisanDemoBanner(),
          ),
        ),
      );

      expect(find.text('DEMO MODE'), findsNothing);
    });
  });
}
