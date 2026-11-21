import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/features/artisan/screens/artisan_discovery_screen.dart';
import 'package:ceylongo/features/artisan/services/artisan_location_service.dart';
import 'package:ceylongo/features/artisan/services/artisan_service.dart';

class MockArtisanLocationService extends ArtisanLocationService {
  final ArtisanLocationResult resultToReturn;

  MockArtisanLocationService({
    this.resultToReturn = const ArtisanLocationResult(
      latitude: 7.2906,
      longitude: 80.6337,
      status: LocationPermissionStatus.granted,
    ),
  });

  @override
  Future<ArtisanLocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return resultToReturn;
  }
}

void main() {
  group('ArtisanDiscoveryScreen Widget Tests', () {
    late http.Client mockClient;
    late ArtisanService artisanService;

    setUp(() {
      mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/v1/artisan-listings/categories') {
          return http.Response(
            jsonEncode(['Woodcarving & Masks', 'Pottery & Ceramics']),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/districts') {
          return http.Response(
            jsonEncode(['Galle', 'Kandy']),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/v1/artisan-listings/featured') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 1,
                  'provider_profile_id': 1,
                  'title': 'Ambalangoda Mask Studio',
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
        }

        if (path == '/api/v1/artisan-listings') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 1,
                  'provider_profile_id': 1,
                  'title': 'Ambalangoda Mask Studio',
                  'craft_category': 'Woodcarving & Masks',
                  'district': 'Galle',
                  'city': 'Ambalangoda',
                  'is_featured': true,
                  'is_active': true,
                  'is_verified': true,
                },
                {
                  'id': 2,
                  'provider_profile_id': 2,
                  'title': 'Kelani Pottery Works',
                  'craft_category': 'Pottery & Ceramics',
                  'district': 'Gampaha',
                  'city': 'Kelaniya',
                  'is_featured': false,
                  'is_active': true,
                  'is_verified': false,
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

    testWidgets('renders search bar, category chips, and listing cards', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanDiscoveryScreen(artisanService: artisanService),
        ),
      );

      // Initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify header and search input
      expect(find.text('Artisan Discovery'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify category chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Woodcarving & Masks'), findsWidgets);
      expect(find.text('Pottery & Ceramics'), findsWidgets);

      // Verify listing cards
      expect(find.text('Ambalangoda Mask Studio'), findsWidgets);
      expect(find.text('Kelani Pottery Works'), findsOneWidget);
    });

    testWidgets('shows empty state when no listings match search', (tester) async {
      final emptyClient = MockClient((request) async {
        if (request.url.path == '/api/v1/artisan-listings/categories' ||
            request.url.path == '/api/v1/artisan-listings/districts') {
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response(
          jsonEncode({'items': [], 'total': 0, 'page': 1, 'page_size': 12, 'total_pages': 0}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final emptyService = ArtisanService(client: emptyClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanDiscoveryScreen(artisanService: emptyService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Artisan Workshops Found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
    });

    testWidgets('tapping Nearby chip triggers location consent dialog and allows discovery with GPS', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockLocation = MockArtisanLocationService(
        resultToReturn: const ArtisanLocationResult(
          latitude: 7.2906,
          longitude: 80.6337,
          status: LocationPermissionStatus.granted,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanDiscoveryScreen(
            artisanService: artisanService,
            locationService: mockLocation,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nearbyChip = find.byKey(const Key('nearby_filter_chip'));
      expect(nearbyChip, findsOneWidget);

      // Tap Nearby chip to open location consent dialog
      await tester.tap(nearbyChip);
      await tester.pumpAndSettle();

      // Verify consent dialog appeared
      expect(find.text('Find Nearby Artisans'), findsOneWidget);
      expect(find.text('Allow Location'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);

      // Tap Allow Location
      await tester.tap(find.text('Allow Location'));
      await tester.pumpAndSettle();

      // Consent dialog dismissed
      expect(find.text('Find Nearby Artisans'), findsNothing);
    });

    testWidgets('shows snackbar and falls back gracefully when location service is disabled', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final disabledLocation = MockArtisanLocationService(
        resultToReturn: ArtisanLocationResult.fromStatus(
          LocationPermissionStatus.serviceDisabled,
          'Location services are disabled on your device. Please enable GPS in device settings.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanDiscoveryScreen(
            artisanService: artisanService,
            locationService: disabledLocation,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nearbyChip = find.byKey(const Key('nearby_filter_chip'));
      expect(nearbyChip, findsOneWidget);

      // Tap Nearby chip to open location consent dialog
      await tester.tap(nearbyChip);
      await tester.pumpAndSettle();

      // Tap Allow Location
      await tester.tap(find.text('Allow Location'));
      await tester.pumpAndSettle();

      // Verify fallback snackbar message is displayed
      expect(find.text('Location services are disabled on your device. Please enable GPS in device settings.'), findsOneWidget);
    });
  });
}
