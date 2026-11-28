import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/constants/api_constants.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/artisan/services/artisan_location_service.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/map/models/map_models.dart';
import 'package:ceylongo/features/map/screens/interactive_map_screen.dart';
import 'package:ceylongo/features/map/services/map_api_service.dart';
import 'package:ceylongo/features/vendor/screens/vendor_more_screen.dart';
import 'package:ceylongo/main.dart';

class _FakeLocationService extends ArtisanLocationService {
  final ArtisanLocationResult result;
  _FakeLocationService(this.result);

  @override
  Future<ArtisanLocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async =>
      result;
}

List<Map<String, dynamic>> _sampleCategoriesJson() => [
      {'id': 'homestay', 'label': 'Homestays', 'available': true, 'reason': null},
      {'id': 'artisan', 'label': 'Artisan shops', 'available': true, 'reason': null},
      {
        'id': 'tourist_attraction',
        'label': 'Tourist attractions',
        'available': false,
        'reason': 'There is no standalone tourist-attraction catalog.',
      },
    ];

Map<String, dynamic> _sampleMapPageJson({
  bool empty = false,
  bool hasMore = false,
  int page = 1,
  String? distanceType,
  bool includeInvalidCoord = false,
}) {
  final items = <Map<String, dynamic>>[];
  if (!empty) {
    items.addAll([
      {
        'listing_id': 11,
        'module_type': 'homestay',
        'name': 'Kandy Heritage Villa',
        'category': 'homestay',
        'latitude': 7.2906,
        'longitude': 80.6337,
        'address': '12 Peradeniya Rd',
        'city': 'Kandy',
        'district': 'Kandy',
        'image_url': null,
        'rating': 4.7,
        'price': 8500.0,
        'currency': 'LKR',
        'detail_path': '/api/v1/homestays/11',
        'distance_km': distanceType != null ? 2.4 : null,
      },
      {
        'listing_id': 25,
        'module_type': 'artisan',
        'name': 'Galle Mask Craft',
        'category': 'artisan',
        'latitude': 6.0535,
        'longitude': 80.2210,
        'address': null,
        'city': 'Galle',
        'district': 'Galle',
        'image_url': null,
        'rating': null,
        'price': null,
        'currency': null,
        'detail_path': '/api/v1/artisan-listings/25',
        'distance_km': distanceType != null ? 6.8 : null,
      },
    ]);
  }
  if (includeInvalidCoord) {
    items.add({
      'listing_id': 99,
      'module_type': 'homestay',
      'name': 'Broken Coord Villa',
      'category': 'homestay',
      'latitude': 95.0,
      'longitude': null,
    });
  }
  return {
    'items': items,
    'page': page,
    'page_size': 25,
    'has_more': hasMore,
    'distance_type': distanceType,
  };
}

Map<String, dynamic> _sampleRouteJson() => {
      'mode': 'driving',
      'geometry': {
        'type': 'MultiLineString',
        'coordinates': [
          [
            [79.8612, 6.9271],
            [80.6337, 7.2906],
          ],
        ],
      },
      'distance_m': 115000.0,
      'distance_km': 115.0,
      'duration_seconds': 9600.0,
      'duration_minutes': 160.0,
      'instructions': [
        {'text': 'Head east toward Kandy', 'distance_m': 115000.0, 'duration_seconds': 9600.0},
      ],
      'attribution': [
        {'label': 'Powered by Geoapify', 'url': 'https://www.geoapify.com/'},
      ],
    };

void main() {
  group('Map Models & Directions URL Tests', () {
    test('parses MapPageResponse, skips invalid coords, and handles missing optionals', () {
      final page = MapPageResponse.fromJson(
        _sampleMapPageJson(includeInvalidCoord: true, hasMore: true),
      );
      expect(page.items, hasLength(2));
      expect(page.skippedInvalidCount, 1);
      expect(page.hasMore, isTrue);

      // Homestay has no Flutter detail route; Artisan maps to /artisan/business?id=25
      expect(page.items[0].supportedFlutterDetailRoute, isNull);
      expect(page.items[1].supportedFlutterDetailRoute, '/artisan/business?id=25');
      expect(page.items[1].rating, isNull);
      expect(page.items[1].price, isNull);
    });

    test('parses MapCategoryItem including unavailable reason', () {
      final cats = _sampleCategoriesJson()
          .map((e) => MapCategoryItem.fromJson(e))
          .toList();
      expect(cats, hasLength(3));
      expect(cats[0].available, isTrue);
      expect(cats[2].available, isFalse);
      expect(cats[2].reason, contains('standalone'));
    });

    test('constructs Google Maps directions URL with validated coordinates', () {
      final uri = buildGoogleMapsDirectionsUri(
        destinationLat: 7.2906,
        destinationLon: 80.6337,
        originLat: 6.9271,
        originLon: 79.8612,
      );
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['destination'], '7.290600,80.633700');
      expect(uri.queryParameters['origin'], '6.927100,79.861200');
      expect(uri.queryParameters['travelmode'], 'driving');

      expect(
        () => buildGoogleMapsDirectionsUri(
          destinationLat: 120.0,
          destinationLon: 80.0,
        ),
        throwsFormatException,
      );
    });
  });

  group('MapApiService HTTP & Error Handling Tests', () {
    test('sends exact query parameters for locations, search, and nearby', () async {
      final captured = <Uri>[];
      final client = MockClient((request) async {
        captured.add(request.url);
        return http.Response(jsonEncode(_sampleMapPageJson(distanceType: 'straight_line')), 200);
      });

      final service = MapApiService(client: client);
      await service.getLocations(category: 'homestay', page: 2, pageSize: 10);
      await service.searchLocations(query: '  Kandy  ', category: 'homestay');
      await service.getNearby(latitude: 7.29, longitude: 80.63, radiusKm: 25);

      expect(captured[0].toString(), startsWith(ApiConstants.mapLocationsEndpoint));
      expect(captured[0].queryParameters['category'], 'homestay');
      expect(captured[0].queryParameters['page'], '2');
      expect(captured[0].queryParameters['page_size'], '10');

      expect(captured[1].toString(), startsWith(ApiConstants.mapSearchEndpoint));
      expect(captured[1].queryParameters['q'], 'Kandy');

      expect(captured[2].toString(), startsWith(ApiConstants.mapNearbyEndpoint));
      expect(captured[2].queryParameters['lat'], '7.29');
      expect(captured[2].queryParameters['lon'], '80.63');
      expect(captured[2].queryParameters['radius_km'], '25');
    });

    test('handles malformed JSON, TimeoutException, and SocketException', () async {
      final badJsonService = MapApiService(
        client: MockClient((_) async => http.Response('{bad', 200)),
      );
      expect(
        () => badJsonService.getLocations(),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'map_invalid_response')),
      );

      final timeoutService = MapApiService(
        client: MockClient((_) async => throw TimeoutException('timeout')),
      );
      expect(
        () => timeoutService.getCategories(),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );

      final offlineService = MapApiService(
        client: MockClient((_) async => throw const SocketException('no host')),
      );
      expect(
        () => offlineService.searchLocations(query: 'Galle'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    });

    test('handles HTTP 400, 404, 422, 429, 503 (map_routing_not_configured), and 504', () async {
      for (final status in [400, 404, 422, 429, 503, 504]) {
        final body = status == 503
            ? {'detail': {'code': 'map_routing_not_configured'}}
            : {'detail': {'code': 'ERR_$status'}};
        final service = MapApiService(
          client: MockClient((_) async => http.Response(jsonEncode(body), status)),
        );
        expect(
          () => service.getRoute(
            origin: const MapCoordinates(latitude: 6.92, longitude: 79.86),
            destination: const MapCoordinates(latitude: 7.29, longitude: 80.63),
          ),
          throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', status)),
        );
      }
    });
  });

  group('InteractiveMapScreen Widget & Navigation Tests', () {
    testWidgets(
      'Renders Sri Lanka map, markers, filters, search, detail card, directions, and in-app route on 360x800',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        Uri? launchedUri;
        final client = MockClient((request) async {
          if (request.url.path.endsWith('/categories')) {
            return http.Response(jsonEncode(_sampleCategoriesJson()), 200);
          }
          if (request.url.path.endsWith('/route')) {
            return http.Response(jsonEncode(_sampleRouteJson()), 200);
          }
          return http.Response(jsonEncode(_sampleMapPageJson(hasMore: true)), 200);
        });

        final service = MapApiService(client: client);
        final fakeLoc = _FakeLocationService(
          ArtisanLocationResult.success(6.9271, 79.8612),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: InteractiveMapScreen(
              mapService: service,
              locationService: fakeLoc,
              showMapTiles: false,
              searchDebounceDuration: const Duration(milliseconds: 50),
              externalUrlLauncher: (uri) async {
                launchedUri = uri;
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Centered on Sri Lanka & renders both markers
        final mapWidget = tester.widget<FlutterMap>(
          find.byKey(const Key('sri_lanka_flutter_map')),
        );
        expect(mapWidget.options.initialCenter.latitude, closeTo(7.8731, 0.01));
        expect(find.byKey(const Key('map_marker_homestay_11')), findsOneWidget);
        expect(find.byKey(const Key('map_marker_artisan_25')), findsOneWidget);

        // Tap homestay marker -> detail card without View Details button
        await tester.tap(find.byKey(const Key('map_marker_homestay_11')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('map_detail_card')), findsOneWidget);
        expect(find.text('Kandy Heritage Villa'), findsOneWidget);
        expect(find.byKey(const Key('map_view_details_btn')), findsNothing);

        // Open Google Maps directions
        await tester.tap(find.byKey(const Key('map_google_directions_btn')));
        await tester.pumpAndSettle();
        expect(launchedUri?.host, 'www.google.com');
        expect(launchedUri?.queryParameters['destination'], '7.290600,80.633700');

        // Request in-app route
        await tester.tap(find.byKey(const Key('map_in_app_route_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('map_route_summary')), findsOneWidget);
        expect(find.textContaining('115.0 km'), findsOneWidget);

        // Close Kandy detail card, recenter to Sri Lanka, then tap Galle artisan marker -> shows View Details button
        await tester.tap(find.byKey(const Key('map_detail_close_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('map_recenter_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('map_marker_artisan_25')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('map_view_details_btn')), findsOneWidget);

        // District filter shows partial page note when has_more is true
        await tester.tap(find.byKey(const Key('map_detail_close_btn')));
        await tester.pumpAndSettle();
        final districtBtn = find.byKey(const Key('map_district_filter_btn'));
        await tester.ensureVisible(districtBtn);
        await tester.pumpAndSettle();
        await tester.tap(districtBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kandy').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('map_zoom_fit_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('map_partial_filter_note')), findsOneWidget);
        expect(find.byKey(const Key('map_marker_homestay_11')), findsOneWidget);
        expect(find.byKey(const Key('map_marker_artisan_25')), findsNothing);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Handles error/retry, empty state, and denied location permission gracefully',
        (tester) async {
      var failLocations = true;
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/categories')) {
          return http.Response(jsonEncode(_sampleCategoriesJson()), 200);
        }
        if (failLocations) {
          return http.Response(jsonEncode({'detail': {'code': 'ERR'}}), 500);
        }
        return http.Response(jsonEncode(_sampleMapPageJson(empty: true)), 200);
      });

      final service = MapApiService(client: client);
      final deniedLoc = _FakeLocationService(
        ArtisanLocationResult.fromStatus(
          LocationPermissionStatus.denied,
          'Location permission denied.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: InteractiveMapScreen(
            mapService: service,
            locationService: deniedLoc,
            showMapTiles: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error banner & Retry -> Empty state
      expect(find.byKey(const Key('map_error_banner')), findsOneWidget);
      failLocations = false;
      await tester.tap(find.byKey(const Key('map_retry_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_empty_state')), findsOneWidget);

      // Nearby with denied permission shows snackbar without crashing
      await tester.tap(find.byKey(const Key('map_nearby_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_nearby_consent_dialog')), findsOneWidget);
      await tester.tap(find.byKey(const Key('map_nearby_allow_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_location_error_snackbar')), findsOneWidget);
    });

    testWidgets('Navigates from Vendor More -> Interactive Map cleanly on 360x800',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/categories')) {
          return http.Response(jsonEncode(_sampleCategoriesJson()), 200);
        }
        return http.Response(jsonEncode(_sampleMapPageJson()), 200);
      });

      final service = MapApiService(client: client);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            ...CeylonGoApp.getRoutes(mapService: service),
            '/map': (_) => InteractiveMapScreen(
                  mapService: service,
                  showMapTiles: false,
                ),
          },
          home: const VendorMoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final mapTile = find.byKey(const Key('vendor_more_map_tile'));
      await tester.scrollUntilVisible(
        mapTile,
        200.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      await tester.tap(mapTile);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveMapScreen), findsOneWidget);
      expect(find.byKey(const Key('sri_lanka_flutter_map')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
