import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/features/artisan/services/artisan_service.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';

void main() {
  group('ArtisanService API Client Tests', () {
    test('getListings calls GET /api/v1/artisan-listings with filters and returns pagination', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/artisan-listings');
        expect(request.url.queryParameters['district'], 'Kandy');
        expect(request.url.queryParameters['category'], 'Woodcarving & Masks');
        expect(request.url.queryParameters['search'], 'mask');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['page_size'], '12');

        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 1,
                'provider_profile_id': 2,
                'title': 'Kandy Mask Studio',
                'craft_category': 'Woodcarving & Masks',
                'district': 'Kandy',
                'city': 'Pilimathalawa',
                'is_active': true,
                'is_verified': true,
                'is_featured': true,
                'approval_status': 'approved',
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

      final service = ArtisanService(client: client);
      final res = await service.getListings(
        search: 'mask',
        district: 'Kandy',
        category: 'Woodcarving & Masks',
      );

      expect(res.items.length, equals(1));
      expect(res.items.first.title, equals('Kandy Mask Studio'));
      expect(res.total, equals(1));
    });

    test('getCategories calls GET /api/v1/artisan-listings/categories and returns strings', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/artisan-listings/categories');
        return http.Response(
          jsonEncode(['Batik & Textiles', 'Handloom & Weaving', 'Pottery & Ceramics']),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: client);
      final categories = await service.getCategories();
      expect(categories, equals(['Batik & Textiles', 'Handloom & Weaving', 'Pottery & Ceramics']));
    });

    test('getDistricts calls GET /api/v1/artisan-listings/districts', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/artisan-listings/districts');
        return http.Response(
          jsonEncode(['Colombo', 'Galle', 'Kandy', 'Matara']),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: client);
      final districts = await service.getDistricts();
      expect(districts.length, equals(4));
      expect(districts, contains('Kandy'));
    });

    test('getFeaturedListings calls GET /api/v1/artisan-listings/featured', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/artisan-listings/featured');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 99,
                'provider_profile_id': 10,
                'title': 'Featured Master Carver',
                'craft_category': 'Woodcarving & Masks',
                'district': 'Galle',
                'city': 'Ambalangoda',
                'is_featured': true,
                'is_active': true,
                'is_verified': true,
              }
            ],
            'total': 1,
            'page': 1,
            'page_size': 6,
            'total_pages': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: client);
      final res = await service.getFeaturedListings(pageSize: 6);
      expect(res.items.first.isFeatured, isTrue);
    });

    test('getNearbyListings calls GET /api/v1/artisan-listings/nearby with coordinate params', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/artisan-listings/nearby');
        expect(request.url.queryParameters['latitude'], '7.2906');
        expect(request.url.queryParameters['longitude'], '80.6337');
        expect(request.url.queryParameters['radius_km'], '25.0');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 1,
                'provider_profile_id': 2,
                'title': 'Kandy Nearby Carver',
                'craft_category': 'Woodcarving',
                'district': 'Kandy',
                'city': 'Kandy',
                'is_active': true,
                'is_verified': true,
                'is_featured': false,
                'approval_status': 'approved',
                'distance_km': 1.25,
              }
            ],
            'total': 1,
            'page': 1,
            'page_size': 12,
            'total_pages': 1,
            'origin_latitude': 7.2906,
            'origin_longitude': 80.6337,
            'radius_km': 25.0,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: client);
      final res = await service.getNearbyListings(
        latitude: 7.2906,
        longitude: 80.6337,
        radiusKm: 25.0,
      );
      expect(res.items.length, equals(1));
      expect(res.items.first.title, equals('Kandy Nearby Carver'));
      expect(res.items.first.distanceKm, equals(1.25));
      expect(res.originLatitude, equals(7.2906));
      expect(res.radiusKm, equals(25.0));
    });

    test('getListingDetails calls GET /api/v1/artisan-listings/:id and handles 404', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/artisan-listings/1') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'provider_profile_id': 5,
              'title': 'Galle Fort Lace Works',
              'craft_category': 'Batik & Textiles',
              'district': 'Galle',
              'city': 'Galle Fort',
              'description': 'Handmade bobbin lace crafting.',
              'is_active': true,
              'is_verified': true,
              'is_featured': false,
              'verification_status': 'verified',
              'images': [],
              'business_hours': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'detail': 'Artisan listing not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: client);
      final listing = await service.getListingDetails(1);
      expect(listing.title, equals('Galle Fort Lace Works'));

      expect(
        () => service.getListingDetails(999),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('getShowcaseItems calls GET /api/v1/showcase-items with itemType and listing filter', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/showcase-items');
        expect(request.url.queryParameters['item_type'], 'product');
        expect(request.url.queryParameters['artisan_listing_id'], '1');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 101,
                'artisan_listing_id': 1,
                'title': 'Handloom Table Runner',
                'item_type': 'product',
                'price': 4200.0,
                'currency': 'LKR',
                'stock_quantity': 8,
                'is_available': true,
                'is_active': true,
                'is_featured': false,
                'approval_status': 'approved',
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

      final service = ArtisanService(client: client);
      final res = await service.getShowcaseItems(
        itemType: 'product',
        artisanListingId: 1,
      );
      expect(res.items.first.title, equals('Handloom Table Runner'));
      expect(res.items.first.price, equals(4200.0));
    });

    test('getShowcaseItemDetails calls GET /api/v1/showcase-items/:id', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/showcase-items/101');
        return http.Response(
          jsonEncode({
            'id': 101,
            'artisan_listing_id': 1,
            'title': 'Handloom Table Runner',
            'item_type': 'product',
            'price': 4200.0,
            'currency': 'LKR',
            'materials': 'Organic Sri Lankan cotton, natural plant dye',
            'stock_quantity': 8,
            'is_available': true,
            'is_active': true,
            'is_featured': false,
            'approval_status': 'approved',
            'listing_title': 'Galle Fort Lace Works',
            'images': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = ArtisanService(client: client);
      final item = await service.getShowcaseItemDetails(101);
      expect(item.id, equals(101));
      expect(item.materials, contains('cotton'));
      expect(item.listingTitle, equals('Galle Fort Lace Works'));
    });
  });
}

