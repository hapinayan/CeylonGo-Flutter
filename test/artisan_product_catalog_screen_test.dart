import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/features/artisan/screens/artisan_product_catalog_screen.dart';
import 'package:ceylongo/features/artisan/services/artisan_service.dart';

void main() {
  group('ArtisanProductCatalogScreen Widget Tests', () {
    late http.Client mockClient;
    late ArtisanService artisanService;

    setUp(() {
      mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/v1/showcase-items') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 101,
                  'artisan_listing_id': 1,
                  'title': 'Traditional Ceramic Vase',
                  'item_type': 'product',
                  'price': 4200.0,
                  'currency': 'LKR',
                  'stock_quantity': 5,
                  'is_available': true,
                  'is_active': true,
                  'approval_status': 'approved',
                  'listing_title': 'Kelani Pottery Works',
                },
                {
                  'id': 102,
                  'artisan_listing_id': 2,
                  'title': 'Carved Elephant Figurine',
                  'item_type': 'product',
                  'price': 6500.0,
                  'currency': 'LKR',
                  'stock_quantity': 0,
                  'is_available': true,
                  'is_active': true,
                  'approval_status': 'approved',
                  'listing_title': 'Kandy Woodcrafts',
                }
              ],
              'total': 2,
              'page': 1,
              'page_size': 12,
              'total_pages': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{}', 404);
      });

      artisanService = ArtisanService(client: mockClient);
    });

    testWidgets('renders products catalog with items and stock badges', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanProductCatalogScreen(artisanService: artisanService),
        ),
      );

      // Loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Artisan Products & Crafts'), findsOneWidget);
      expect(find.text('Traditional Ceramic Vase'), findsOneWidget);
      expect(find.text('Carved Elephant Figurine'), findsOneWidget);
      expect(find.text('LKR 4200'), findsOneWidget);
      expect(find.text('LKR 6500'), findsOneWidget);
      expect(find.text('5 In Stock'), findsOneWidget);
      expect(find.text('Out of Stock'), findsOneWidget);
    });

    testWidgets('shows empty state when no products found', (tester) async {
      final emptyClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'items': [], 'total': 0, 'page': 1, 'page_size': 12, 'total_pages': 0}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final emptyService = ArtisanService(client: emptyClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanProductCatalogScreen(artisanService: emptyService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);
    });
  });
}

