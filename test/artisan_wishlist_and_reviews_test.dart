import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/artisan/models/artisan_promotion_model.dart';
import 'package:ceylongo/features/artisan/models/artisan_review_model.dart';
import 'package:ceylongo/features/artisan/screens/artisan_business_detail_screen.dart';
import 'package:ceylongo/features/artisan/screens/artisan_wishlist_screen.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/artisan/services/artisan_service.dart';
import 'package:ceylongo/features/artisan/widgets/promotion_banner_card.dart';
import 'package:ceylongo/features/artisan/widgets/review_breakdown_widget.dart';
import 'package:ceylongo/features/artisan/widgets/star_rating_bar.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';

class MockLoggedInStorage extends SecureStorageService {
  @override
  Future<bool> hasToken() async => true;

  @override
  Future<String?> getToken() async => 'valid_token_xyz';

  @override
  Future<UserModel?> getUser() async => const UserModel(
        id: '10',
        fullName: 'Test Traveler',
        email: 'traveler@ceylongo.lk',
        role: 'traveler',
      );
}

void main() {
  group('Artisan Phase 2 Widgets Tests', () {
    testWidgets('StarRatingBar interactive mode fires onRatingChanged callback', (tester) async {
      double currentRating = 3.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StarRatingBar(
                  rating: currentRating,
                  isInteractive: true,
                  onRatingChanged: (val) {
                    setState(() {
                      currentRating = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify 5 star icons
      expect(find.byType(Icon), findsNWidgets(5));

      // Tap on 5th star
      await tester.tap(find.byType(Icon).last);
      await tester.pumpAndSettle();

      expect(currentRating, 5.0);
    });

    testWidgets('ReviewBreakdownWidget displays rating, review counts, and verified count', (tester) async {
      const summary = ArtisanReviewSummaryModel(
        listingId: 1,
        listingTitle: 'Mask Workshop',
        averageRating: 4.8,
        totalReviews: 24,
        ratingBreakdown: {'5': 18, '4': 4, '3': 2, '2': 0, '1': 0},
        verifiedReviewsCount: 20,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReviewBreakdownWidget(summary: summary),
          ),
        ),
      );

      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('24 reviews'), findsOneWidget);
      expect(find.textContaining('20 verified in-store pickup booking reviews'), findsOneWidget);
    });

    testWidgets('PromotionBannerCard displays promo code and discount badge', (tester) async {
      final promotion = ArtisanPromotionModel(
        id: 1,
        artisanListingId: 1,
        title: 'Southern Craft Festival',
        description: 'Get 20% off all hand-carved Raksha masks',
        promoCode: 'RAKSHA20',
        discountPercentage: 20.0,
        currency: 'LKR',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromotionBannerCard(promotion: promotion),
          ),
        ),
      );

      expect(find.text('20% OFF'), findsOneWidget);
      expect(find.text('Southern Craft Festival'), findsOneWidget);
      expect(find.text('RAKSHA20'), findsOneWidget);
    });
  });

  group('ArtisanWishlistScreen Widget Tests', () {
    testWidgets('renders saved workshops, schema notice, and removes item on heart tap', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/artisan-wishlists/me') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 1,
                  'user_id': 10,
                  'listing_reference_id': 1,
                  'artisan_listing_id': 1,
                  'created_at': '2026-11-19T08:00:00Z',
                  'is_available': true,
                  'listing': {
                    'id': 1,
                    'provider_profile_id': 10,
                    'title': 'Ambalangoda Heritage Masks',
                    'craft_category': 'Woodcarving & Masks',
                    'district': 'Galle',
                    'city': 'Ambalangoda',
                    'approval_status': 'approved',
                    'is_active': true,
                  },
                }
              ],
              'total': 1,
              'page': 1,
              'page_size': 20,
              'total_pages': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/v1/artisan-listings/1/wishlist' && request.method == 'DELETE') {
          return http.Response('', 204);
        }

        return http.Response('{}', 404);
      });

      final storage = MockLoggedInStorage();
      final service = ArtisanService(client: mockClient, storageService: storage);

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanWishlistScreen(
            artisanService: service,
            storageService: storage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify architectural notice
      expect(
        find.textContaining('Wishlists save your favorite verified workshops'),
        findsOneWidget,
      );

      // Verify saved item
      expect(find.text('Ambalangoda Heritage Masks'), findsOneWidget);
      expect(find.text('Woodcarving & Masks'), findsOneWidget);

      // Tap remove heart icon
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('No Saved Workshops Yet'), findsOneWidget);
    });
  });

  group('ArtisanBusinessDetailScreen Phase 2 Integrations', () {
    setUp(() {
      ArtisanDemoService.isDemoMode = true;
    });

    tearDown(() {
      ArtisanDemoService.isDemoMode = false;
    });

    testWidgets('renders wishlist toggle, active promotions, and reviews breakdown in demo mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/v1/artisan-listings/1') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'provider_profile_id': 10,
              'title': 'Ambalangoda Mask Workshop',
              'craft_category': 'Woodcarving & Masks',
              'district': 'Galle',
              'city': 'Ambalangoda',
              'phone': '+94912258000',
              'is_active': true,
              'is_verified': true,
              'is_featured': true,
              'images': [],
              'business_hours': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/showcase-items') {
          return http.Response(
            jsonEncode({'items': [], 'total': 0, 'page': 1, 'page_size': 20, 'total_pages': 0}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/wishlist/check') {
          return http.Response(
            jsonEncode({'listing_id': 1, 'is_saved': false, 'wishlist_id': null}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/promotions') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 1,
                  'artisan_listing_id': 1,
                  'title': 'Grand Opening Special',
                  'promo_code': 'WELCOME10',
                  'discount_percentage': 10.0,
                  'currency': 'LKR',
                  'start_date': '2026-11-01T00:00:00Z',
                  'end_date': '2026-11-30T00:00:00Z',
                  'is_active': true,
                }
              ],
              'total': 1,
              'page': 1,
              'page_size': 10,
              'total_pages': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/reviews/summary') {
          return http.Response(
            jsonEncode({
              'listing_id': 1,
              'listing_title': 'Ambalangoda Mask Workshop',
              'average_rating': 4.9,
              'total_reviews': 8,
              'rating_breakdown': {'5': 7, '4': 1, '3': 0, '2': 0, '1': 0},
              'verified_reviews_count': 8,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/reviews') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 1,
                  'listing_reference_id': 1,
                  'booking_reference_id': 10,
                  'user_id': 55,
                  'user_name': 'Nimal Perera',
                  'rating': 5.0,
                  'title': 'Spectacular Traditional Craft',
                  'comment': 'The master demonstrated the carving techniques.',
                  'is_verified_booking': true,
                  'is_published': true,
                  'created_at': '2026-11-18T10:00:00Z',
                }
              ],
              'total': 1,
              'page': 1,
              'page_size': 10,
              'total_pages': 1,
              'average_rating': 4.9,
              'total_reviews': 8,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/wishlist' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'user_id': 10,
              'listing_reference_id': 1,
              'artisan_listing_id': 1,
              'created_at': '2026-11-19T10:00:00Z',
              'is_available': true,
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{}', 404);
      });

      final storage = MockLoggedInStorage();
      final service = ArtisanService(client: mockClient, storageService: storage);

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanBusinessDetailScreen(
            listingId: 1,
            artisanService: service,
            storageService: storage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Wishlist Toggle Button
      expect(find.byKey(const Key('wishlist_toggle_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('wishlist_toggle_btn')));
      await tester.pumpAndSettle();

      // Verify Active Promotion Card
      expect(find.text('Special Offers & Discounts'), findsOneWidget);
      expect(find.text('Grand Opening Special'), findsOneWidget);
      expect(find.text('WELCOME10'), findsOneWidget);

      // Verify Reviews & Ratings Section
      expect(find.text('Traveler Reviews & Ratings'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Spectacular Traditional Craft'), findsOneWidget);
      expect(find.text('Nimal Perera'), findsOneWidget);
    });
  });
}

