import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/features/artisan/models/artisan_listing_model.dart';
import 'package:ceylongo/features/artisan/models/showcase_item_model.dart';
import 'package:ceylongo/features/artisan/widgets/artisan_listing_card.dart';
import 'package:ceylongo/features/artisan/widgets/artisan_product_card.dart';
import 'package:ceylongo/features/artisan/widgets/featured_badge.dart';
import 'package:ceylongo/features/artisan/widgets/stock_badge.dart';
import 'package:ceylongo/features/artisan/widgets/verification_badge.dart';

void main() {
  group('Artisan Widget Component Tests', () {
    testWidgets('VerificationBadge renders verified label only when isVerified is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VerificationBadge(isVerified: true),
                VerificationBadge(isVerified: false),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('FeaturedBadge renders "Featured Spotlight" without any paid ad wording', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeaturedBadge(),
          ),
        ),
      );

      expect(find.text('Featured Spotlight'), findsOneWidget);
      expect(find.textContaining('Ad'), findsNothing);
      expect(find.textContaining('Sponsored'), findsNothing);
    });

    testWidgets('StockBadge renders In Stock, Low Stock, Out of Stock, and Unavailable correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StockBadge(stockQuantity: 10, isAvailable: true, isActive: true, approvalStatus: 'approved'),
                StockBadge(stockQuantity: 2, isAvailable: true, isActive: true, approvalStatus: 'approved'),
                StockBadge(stockQuantity: 0, isAvailable: true, isActive: true, approvalStatus: 'approved'),
                StockBadge(stockQuantity: 5, isAvailable: false, isActive: true, approvalStatus: 'approved'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('10 In Stock'), findsOneWidget);
      expect(find.text('Only 2 left'), findsOneWidget);
      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('ArtisanListingCard renders business information and responds to tap', (tester) async {
      bool tapped = false;
      const listing = ArtisanListingSummary(
        id: 1,
        providerProfileId: 10,
        title: 'Kandy Brass Workshop',
        craftCategory: 'Brass & Metalware',
        district: 'Kandy',
        city: 'Pilimathalawa',
        isVerified: true,
        isFeatured: true,
        averageRating: 4.9,
        totalReviews: 8,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtisanListingCard(
              listing: listing,
              distanceKm: 5.2,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Kandy Brass Workshop'), findsOneWidget);
      expect(find.text('Brass & Metalware'), findsOneWidget);
      expect(find.text('Pilimathalawa, Kandy'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Featured Spotlight'), findsOneWidget);
      expect(find.text('5.2 km'), findsOneWidget);
      expect(find.text('(8 reviews)'), findsOneWidget);

      await tester.tap(find.text('Kandy Brass Workshop'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('ArtisanProductCard renders item details, price in LKR and stock', (tester) async {
      bool tapped = false;
      const product = ShowcaseItemSummary(
        id: 20,
        artisanListingId: 1,
        title: 'Hand-Hammered Brass Oil Lamp',
        itemType: 'product',
        price: 8500.0,
        currency: 'LKR',
        stockQuantity: 4,
        isCustomOrderAvailable: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 250,
              child: ArtisanProductCard(
                product: product,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hand-Hammered Brass Oil Lamp'), findsOneWidget);
      expect(find.text('Product'), findsOneWidget);
      expect(find.text('LKR 8500'), findsOneWidget);
      expect(find.text('4 In Stock'), findsOneWidget);

      await tester.tap(find.text('Hand-Hammered Brass Oil Lamp'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}

