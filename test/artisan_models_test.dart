import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/features/artisan/models/artisan_listing_model.dart';
import 'package:ceylongo/features/artisan/models/showcase_item_model.dart';

void main() {
  group('ArtisanListingModel Tests', () {
    test('resolveImageUrl correctly resolves relative and full URLs', () {
      expect(resolveImageUrl(null), equals(''));
      expect(resolveImageUrl('   '), equals(''));
      expect(resolveImageUrl('https://example.com/photo.jpg'), equals('https://example.com/photo.jpg'));
      expect(resolveImageUrl('http://example.com/photo.jpg'), equals('http://example.com/photo.jpg'));
      expect(resolveImageUrl('/static/uploads/artisan.jpg'), contains('/static/uploads/artisan.jpg'));
    });

    test('dayOfWeekToString converts day numbers correctly', () {
      expect(dayOfWeekToString(0), equals('Monday'));
      expect(dayOfWeekToString(5), equals('Saturday'));
      expect(dayOfWeekToString(6), equals('Sunday'));
      expect(dayOfWeekToString(9), equals('Day 9'));
    });

    test('ArtisanListingSummary parses JSON correctly with full and null fields', () {
      final json = {
        'id': 10,
        'provider_profile_id': 5,
        'title': 'Kandy Brass Works',
        'craft_category': 'Brass & Metalware',
        'district': 'Kandy',
        'city': 'Pilimathalawa',
        'latitude': 7.2581,
        'longitude': 80.5692,
        'cover_image_url': '/images/kandy_brass.jpg',
        'is_active': true,
        'is_verified': true,
        'is_featured': true,
        'approval_status': 'approved',
        'average_rating': 4.8,
        'total_reviews': 12,
      };

      final model = ArtisanListingSummary.fromJson(json);
      expect(model.id, equals(10));
      expect(model.providerProfileId, equals(5));
      expect(model.title, equals('Kandy Brass Works'));
      expect(model.craftCategory, equals('Brass & Metalware'));
      expect(model.district, equals('Kandy'));
      expect(model.city, equals('Pilimathalawa'));
      expect(model.latitude, equals(7.2581));
      expect(model.longitude, equals(80.5692));
      expect(model.hasCoordinates, isTrue);
      expect(model.isVerified, isTrue);
      expect(model.isFeatured, isTrue);
      expect(model.averageRating, equals(4.8));
      expect(model.totalReviews, equals(12));
    });

    test('ArtisanListingResponse parses gallery images and weekly hours', () {
      final json = {
        'id': 1,
        'provider_profile_id': 1,
        'title': 'Ambalangoda Traditional Mask Workshop',
        'craft_category': 'Woodcarving & Masks',
        'district': 'Galle',
        'city': 'Ambalangoda',
        'description': 'Master mask carving studio using Kaduru wood.',
        'address': '124 Galle Road, Ambalangoda',
        'phone': '+94912258000',
        'email': 'masks@ambalangoda.lk',
        'is_active': true,
        'is_verified': true,
        'is_featured': false,
        'approval_status': 'approved',
        'verification_status': 'verified',
        'provider_business_name': 'Ariyapala Mask Museum & Crafts',
        'images': [
          {
            'id': 101,
            'artisan_listing_id': 1,
            'image_url': '/uploads/mask1.jpg',
            'caption': 'Peacock Mask Carving',
            'display_order': 0,
            'is_primary': true,
          }
        ],
        'business_hours': [
          {
            'id': 201,
            'artisan_listing_id': 1,
            'day_of_week': 0,
            'open_time': '09:00',
            'close_time': '17:00',
            'is_closed': false,
          },
          {
            'id': 202,
            'artisan_listing_id': 1,
            'day_of_week': 6,
            'open_time': null,
            'close_time': null,
            'is_closed': true,
          }
        ],
      };

      final response = ArtisanListingResponse.fromJson(json);
      expect(response.id, equals(1));
      expect(response.description, contains('Kaduru wood'));
      expect(response.phone, equals('+94912258000'));
      expect(response.images.length, equals(1));
      expect(response.images.first.caption, equals('Peacock Mask Carving'));
      expect(response.businessHours.length, equals(2));
      expect(response.businessHours[0].dayName, equals('Monday'));
      expect(response.businessHours[0].formattedHours, equals('09:00 - 17:00'));
      expect(response.businessHours[1].dayName, equals('Sunday'));
      expect(response.businessHours[1].formattedHours, equals('Closed'));
    });

    test('ArtisanListingPagination parses page metadata and list items', () {
      final json = {
        'items': [
          {
            'id': 1,
            'provider_profile_id': 1,
            'title': 'Dumbara Mat Weaving',
            'craft_category': 'Handloom & Weaving',
            'district': 'Kandy',
            'city': 'Kundasale',
          }
        ],
        'total': 1,
        'page': 1,
        'page_size': 12,
        'total_pages': 1,
      };

      final pagination = ArtisanListingPagination.fromJson(json);
      expect(pagination.items.length, equals(1));
      expect(pagination.total, equals(1));
      expect(pagination.page, equals(1));
      expect(pagination.pageSize, equals(12));
    });

    test('ArtisanNearbyListingPagination parses origin and distance correctly', () {
      final json = {
        'items': [
          {
            'id': 1,
            'provider_profile_id': 1,
            'title': 'Dumbara Mat Weaving',
            'craft_category': 'Handloom & Weaving',
            'district': 'Kandy',
            'city': 'Kundasale',
            'distance_km': 3.45,
          }
        ],
        'total': 1,
        'page': 1,
        'page_size': 12,
        'total_pages': 1,
        'origin_latitude': 7.2906,
        'origin_longitude': 80.6337,
        'radius_km': 25.0,
      };

      final nearby = ArtisanNearbyListingPagination.fromJson(json);
      expect(nearby.items.length, equals(1));
      expect(nearby.items.first.distanceKm, equals(3.45));
      expect(nearby.originLatitude, equals(7.2906));
      expect(nearby.originLongitude, equals(80.6337));
      expect(nearby.radiusKm, equals(25.0));
    });
  });

  group('ShowcaseItemModel Tests', () {
    test('ShowcaseItemSummary parses price and purchasable status correctly', () {
      final inStockJson = {
        'id': 50,
        'artisan_listing_id': 1,
        'title': 'Carved Gurulu Raksha Mask',
        'item_type': 'product',
        'price': 6500.0,
        'currency': 'LKR',
        'is_available': true,
        'is_active': true,
        'stock_quantity': 5,
        'is_featured': true,
        'approval_status': 'approved',
      };

      final inStock = ShowcaseItemSummary.fromJson(inStockJson);
      expect(inStock.formattedPrice, equals('LKR 6500'));
      expect(inStock.isPurchasable, isTrue);
      expect(inStock.isProduct, isTrue);
      expect(inStock.isService, isFalse);

      final outOfStockJson = {
        ...inStockJson,
        'stock_quantity': 0,
      };
      final outOfStock = ShowcaseItemSummary.fromJson(outOfStockJson);
      expect(outOfStock.isPurchasable, isFalse);

      final unapprovedJson = {
        ...inStockJson,
        'approval_status': 'pending',
      };
      final unapproved = ShowcaseItemSummary.fromJson(unapprovedJson);
      expect(unapproved.isPurchasable, isFalse);
    });

    test('ShowcaseItemResponse parses full details and materials', () {
      final json = {
        'id': 75,
        'artisan_listing_id': 3,
        'title': 'Pottery Wheel Demonstration & Workshop',
        'item_type': 'service',
        'price': 3500.0,
        'currency': 'LKR',
        'description': 'Hands-on 90-minute traditional Sri Lankan clay sculpting.',
        'materials': 'Natural Kelani river clay, traditional wooden wheel',
        'duration_minutes': 90,
        'is_available': true,
        'is_active': true,
        'stock_quantity': 10,
        'is_custom_order_available': true,
        'approval_status': 'approved',
        'listing_title': 'Molagoda Traditional Pottery Village',
        'images': [
          {
            'id': 301,
            'showcase_item_id': 75,
            'image_url': '/uploads/pottery_workshop.jpg',
            'caption': 'Clay turning on wheel',
            'display_order': 0,
            'is_primary': true,
          }
        ],
      };

      final response = ShowcaseItemResponse.fromJson(json);
      expect(response.id, equals(75));
      expect(response.isService, isTrue);
      expect(response.durationMinutes, equals(90));
      expect(response.materials, contains('Kelani river clay'));
      expect(response.isCustomOrderAvailable, isTrue);
      expect(response.listingTitle, equals('Molagoda Traditional Pottery Village'));
      expect(response.images.length, equals(1));
    });
  });
}

