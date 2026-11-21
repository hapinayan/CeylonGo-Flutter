import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/artisan/screens/artisan_business_detail_screen.dart';
import 'package:ceylongo/features/artisan/services/artisan_service.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';

class MockTestStorage extends SecureStorageService {
  @override
  Future<bool> hasToken() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<UserModel?> getUser() async => null;
}

void main() {
  group('ArtisanBusinessDetailScreen Widget Tests', () {
    late http.Client mockClient;
    late ArtisanService artisanService;
    late MockTestStorage mockStorage;

    setUp(() {
      mockStorage = MockTestStorage();
      mockClient = MockClient((request) async {
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
              'address': 'Main Street, Ambalangoda',
              'latitude': 6.2355,
              'longitude': 80.0543,
              'phone': '+94912258000',
              'email': 'artisan@ambalangoda.lk',
              'description': 'Master traditional woodcarving using indigenous Kaduru wood.',
              'is_active': true,
              'is_verified': true,
              'is_featured': true,
              'provider_business_name': 'Ariyapala Heritage Crafts',
              'images': [
                {
                  'id': 1,
                  'artisan_listing_id': 1,
                  'image_url': 'https://example.com/mask1.jpg',
                  'caption': 'Peacock Mask',
                  'display_order': 0,
                  'is_primary': true,
                }
              ],
              'business_hours': [
                {
                  'id': 1,
                  'artisan_listing_id': 1,
                  'day_of_week': 0,
                  'open_time': '09:00',
                  'close_time': '17:00',
                  'is_closed': false,
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/showcase-items') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 50,
                  'artisan_listing_id': 1,
                  'title': 'Carved Peacock Mask',
                  'item_type': 'product',
                  'price': 7500.0,
                  'currency': 'LKR',
                  'stock_quantity': 3,
                  'is_available': true,
                  'is_active': true,
                  'approval_status': 'approved',
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

        if (path == '/api/v1/artisan-listings/1/wishlist/check') {
          return http.Response(
            jsonEncode({'listing_id': 1, 'is_saved': false, 'wishlist_id': null}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/promotions') {
          return http.Response(
            jsonEncode({'items': [], 'total': 0, 'page': 1, 'page_size': 10, 'total_pages': 0}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/reviews/summary') {
          return http.Response(
            jsonEncode({
              'listing_id': 1,
              'listing_title': 'Ambalangoda Mask Workshop',
              'average_rating': 0.0,
              'total_reviews': 0,
              'rating_breakdown': {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0},
              'verified_reviews_count': 0,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/1/reviews') {
          return http.Response(
            jsonEncode({'items': [], 'total': 0, 'page': 1, 'page_size': 10, 'total_pages': 0}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{}', 404);
      });

      artisanService = ArtisanService(client: mockClient, storageService: mockStorage);
    });

    testWidgets('renders business profile, story, address, and hours', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanBusinessDetailScreen(
            listingId: 1,
            artisanService: artisanService,
            storageService: mockStorage,
          ),
        ),
      );

      // Wait for async load
      await tester.pumpAndSettle();

      expect(find.text('Ambalangoda Mask Workshop'), findsWidgets);
      expect(find.text('Woodcarving & Masks'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Featured Spotlight'), findsOneWidget);
      expect(find.textContaining('Kaduru wood'), findsOneWidget);
      expect(find.textContaining('Ambalangoda, Galle District'), findsOneWidget);
      expect(find.text('Opening Hours'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('09:00 - 17:00'), findsOneWidget);
      expect(find.text('Carved Peacock Mask'), findsOneWidget);
    });

    testWidgets('opens contact modal on Contact Seller button click', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanBusinessDetailScreen(
            listingId: 1,
            artisanService: artisanService,
            storageService: mockStorage,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Contact Seller'));
      await tester.pumpAndSettle();

      expect(find.text('Contact Ambalangoda Mask Workshop'), findsOneWidget);
      expect(find.text('+94912258000'), findsWidgets);
      expect(find.text('artisan@ambalangoda.lk'), findsOneWidget);
    });
  });
}
