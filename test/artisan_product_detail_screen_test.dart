import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/artisan/screens/artisan_product_detail_screen.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/artisan/services/artisan_service.dart';

class _FakeStorageService extends SecureStorageService {
  final bool loggedIn;
  _FakeStorageService({this.loggedIn = false});

  @override
  Future<bool> hasToken() async => loggedIn;

  @override
  Future<String?> getToken() async => loggedIn ? 'test-token' : null;
}

void main() {
  group('ArtisanProductDetailScreen Widget Tests', () {
    late http.Client mockClient;
    late ArtisanService artisanService;
    late _FakeStorageService storageService;

    tearDown(() {
      ArtisanDemoService.isDemoMode = false;
    });

    setUp(() {
      ArtisanDemoService.isDemoMode = false;
      storageService = _FakeStorageService(loggedIn: false);
      mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/artisan-listings/1') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'provider_profile_id': 2,
              'title': 'Ambalangoda Mask Workshop',
              'craft_category': 'Woodcarving & Masks',
              'district': 'Galle',
              'city': 'Ambalangoda',
              'phone': '+94912258000',
              'email': 'masks@ceylongo.lk',
              'is_active': true,
              'is_verified': true,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/showcase-items/50') {
          return http.Response(
            jsonEncode({
              'id': 50,
              'artisan_listing_id': 1,
              'title': 'Hand-Carved Peacock Raksha Mask',
              'item_type': 'product',
              'price': 9500.0,
              'currency': 'LKR',
              'sku': 'MASK-PEA-001',
              'stock_quantity': 4,
              'is_available': true,
              'is_active': true,
              'is_custom_order_available': true,
              'approval_status': 'approved',
              'materials': 'Seasoned Kaduru wood, natural herbal lacquers',
              'description': 'Traditional protective peacock mask symbolizing prosperity.',
              'listing_title': 'Ambalangoda Mask Workshop',
              'images': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/v1/showcase-items/51') {
          return http.Response(
            jsonEncode({
              'id': 51,
              'artisan_listing_id': 1,
              'title': 'Traditional Brass Lamp',
              'item_type': 'product',
              'price': 18000.0,
              'currency': 'LKR',
              'sku': 'BRASS-001',
              'stock_quantity': 0,
              'is_available': true,
              'is_active': true,
              'is_custom_order_available': false,
              'approval_status': 'approved',
              'materials': 'Solid cast brass',
              'description': 'Handcrafted traditional oil lamp.',
              'listing_title': 'Ambalangoda Brass Works',
              'images': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{}', 404);
      });

      artisanService = ArtisanService(client: mockClient, storageService: storageService);
    });

    testWidgets('renders product details, price in LKR, stock, and materials', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanProductDetailScreen(
            productId: 50,
            artisanService: artisanService,
            storageService: storageService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hand-Carved Peacock Raksha Mask'), findsWidgets);
      expect(find.text('LKR 9500'), findsOneWidget);
      expect(find.text('4 In Stock'), findsOneWidget);
      expect(find.text('Handcrafted Product'), findsOneWidget);
      expect(find.textContaining('Kaduru wood'), findsOneWidget);
      expect(find.text('Ambalangoda Mask Workshop'), findsOneWidget);
      expect(find.text('Inquire with Artisan'), findsOneWidget);
      // Showcase & contact only in normal Academic MVP mode (no reservation button)
      expect(find.byKey(const Key('reserve_for_pickup_btn')), findsNothing);
    });

    testWidgets('opens inquiry contact modal on Inquire button tap', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanProductDetailScreen(
            productId: 50,
            artisanService: artisanService,
            storageService: storageService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Inquire with Artisan'));
      await tester.pumpAndSettle();

      expect(find.text('Contact Hand-Carved Peacock Raksha Mask'), findsOneWidget);
    });

    testWidgets('shows pending approval message on tapping product favorite button without network mutation', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanProductDetailScreen(
            productId: 50,
            artisanService: artisanService,
            storageService: storageService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final favBtn = find.byKey(const Key('product_favorite_btn'));
      expect(favBtn, findsOneWidget);

      await tester.tap(favBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please sign in to save this artisan workshop.'), findsOneWidget);
    });

    testWidgets('does not show reservation button in MVP showcase mode when product is out of stock', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanProductDetailScreen(
            productId: 51,
            artisanService: artisanService,
            storageService: storageService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reserve_out_of_stock_btn')), findsNothing);
      expect(find.byKey(const Key('reserve_for_pickup_btn')), findsNothing);
      expect(find.text('Inquire with Artisan'), findsOneWidget);
    });
  });
}
