import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/home/screens/home_screen.dart';
import 'package:ceylongo/features/map/models/map_models.dart';
import 'package:ceylongo/features/map/services/map_api_service.dart';
import 'package:ceylongo/features/recommendations/models/recommendation_models.dart';
import 'package:ceylongo/features/recommendations/screens/recommendations_screen.dart';
import 'package:ceylongo/features/recommendations/services/recommendation_api_service.dart';
import 'package:ceylongo/features/recommendations/services/recommendation_engine.dart';
import 'package:ceylongo/features/recommendations/services/recommendation_preferences_service.dart';
import 'package:ceylongo/main.dart';

Map<String, dynamic> _sampleMapListings({
  bool empty = false,
  bool hasMore = false,
  bool includeDuplicateAndInvalid = false,
}) {
  final items = <Map<String, dynamic>>[];
  if (!empty) {
    items.addAll([
      {
        'listing_id': 10,
        'module_type': 'homestay',
        'name': 'Kandy Mist Homestay',
        'category': 'homestay',
        'latitude': 7.29,
        'longitude': 80.63,
        'address': '5 Lake Rd',
        'city': 'Kandy',
        'district': 'Kandy',
        'image_url': null,
        'rating': 4.5,
        'price': 7500.0,
        'currency': 'LKR',
      },
      {
        'listing_id': 20,
        'module_type': 'artisan',
        'name': 'Ambalangoda Mask Studio',
        'category': 'artisan',
        'latitude': 6.23,
        'longitude': 80.05,
        'address': null,
        'city': 'Ambalangoda',
        'district': 'Galle',
        'image_url': null,
        'rating': null,
        'price': null,
        'currency': null,
      },
      {
        'listing_id': 30,
        'module_type': 'eco_experience',
        'name': 'Knuckles Eco Trail',
        'category': 'eco_tourism',
        'latitude': 7.45,
        'longitude': 80.78,
        'address': 'Trailhead',
        'city': 'Matale',
        'district': 'Matale',
        'image_url': null,
        'rating': 4.8,
        'price': 4500.0,
        'currency': 'LKR',
      },
    ]);
  }
  if (includeDuplicateAndInvalid) {
    items.add({
      'listing_id': 10,
      'module_type': 'homestay',
      'name': 'Kandy Mist Homestay',
      'category': 'homestay',
      'latitude': 7.29,
      'longitude': 80.63,
    });
    items.add({
      'listing_id': 99,
      'module_type': 'homestay',
      'name': 'Invalid Coord Place',
      'category': 'homestay',
      'latitude': 120.0,
      'longitude': null,
    });
  }
  return {
    'items': items,
    'page': 1,
    'page_size': 50,
    'has_more': hasMore,
    'distance_type': null,
  };
}

void main() {
  group('Recommendation Models, Preferences & Engine Unit Tests', () {
    test('maps TravelerInterest to verified backend categories & persists locally',
        () async {
      expect(
        TravelerInterest.natureEco.backendCategories,
        contains('eco_tourism'),
      );
      expect(
        TravelerInterest.rentals.backendCategories,
        containsAll(['bike_rental', 'bicycle_rental']),
      );

      final store = InMemoryRecommendationPreferencesStore();
      const prefs = TravelerPreferences(
        selectedInterests: {TravelerInterest.homestays, TravelerInterest.artisan},
        preferredDistrict: 'Kandy',
      );
      await store.save(prefs);
      final loaded = await store.load();
      expect(loaded.selectedInterests, containsAll([TravelerInterest.homestays, TravelerInterest.artisan]));
      expect(loaded.preferredDistrict, 'Kandy');

      await store.clear();
      final cleared = await store.load();
      expect(cleared.isEmpty, isTrue);
    });

    test('deduplicates, filters by interest, ranks by district & tie-breaks deterministically',
        () {
      final page = MapPageResponse.fromJson(
        _sampleMapListings(includeDuplicateAndInvalid: true, hasMore: true),
      );
      expect(page.skippedInvalidCount, 1);

      const engine = RecommendationEngine();
      final res = engine.rank(
        candidates: page.items,
        preferences: const TravelerPreferences(
          selectedInterests: {
            TravelerInterest.homestays,
            TravelerInterest.artisan,
          },
          preferredDistrict: 'Kandy',
        ),
        skippedInvalidCount: page.skippedInvalidCount,
        hasMore: page.hasMore,
      );

      // Deduplicated & eco_experience filtered out
      expect(res.totalFetched, 3);
      expect(res.recommendations, hasLength(2));
      expect(res.hasMore, isTrue);
      // Kandy Mist Homestay ranks first due to Kandy district match + rating
      expect(res.recommendations[0].item.name, 'Kandy Mist Homestay');
      expect(res.recommendations[0].districtMatched, isTrue);
      expect(res.recommendations[0].explanationText, contains('Kandy'));
      expect(res.recommendations[1].item.name, 'Ambalangoda Mask Studio');

      // Tie-breaking determinism: equal scores sorted alphabetically by name
      final tieRes = engine.rank(
        candidates: const [
          MapLocationItem(
            listingId: 2,
            moduleType: 'homestay',
            name: 'Zebra Villa',
            category: 'homestay',
            latitude: 7.0,
            longitude: 80.0,
          ),
          MapLocationItem(
            listingId: 1,
            moduleType: 'homestay',
            name: 'Alpha Villa',
            category: 'homestay',
            latitude: 7.1,
            longitude: 80.1,
          ),
        ],
        preferences: const TravelerPreferences(
          selectedInterests: {TravelerInterest.homestays},
        ),
      );
      expect(tieRes.recommendations[0].item.name, 'Alpha Villa');
      expect(tieRes.recommendations[1].item.name, 'Zebra Villa');
    });
  });

  group('RecommendationApiService Error & No-Fake-Results Tests', () {
    test('handles malformed JSON, timeout, SocketException, and HTTP errors without fake fallback',
        () async {
      final badJson = RecommendationApiService(
        mapApiService: MapApiService(
          client: MockClient((_) async => http.Response('{bad', 200)),
        ),
      );
      expect(
        () => badJson.fetchRecommendations(
          preferences: const TravelerPreferences(),
        ),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'map_invalid_response')),
      );

      final timeout = RecommendationApiService(
        mapApiService: MapApiService(
          client: MockClient((_) async => throw TimeoutException('timeout')),
        ),
      );
      expect(
        () => timeout.fetchRecommendations(
          preferences: const TravelerPreferences(),
        ),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );

      final offline = RecommendationApiService(
        mapApiService: MapApiService(
          client: MockClient((_) async => throw const SocketException('offline')),
        ),
      );
      expect(
        () => offline.fetchRecommendations(
          preferences: const TravelerPreferences(),
        ),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );

      final serverErr = RecommendationApiService(
        mapApiService: MapApiService(
          client: MockClient((_) async => http.Response('{}', 503)),
        ),
      );
      expect(
        () => serverErr.fetchRecommendations(
          preferences: const TravelerPreferences(),
        ),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 503)),
      );
    });
  });

  group('RecommendationsScreen & Traveler Home Integration Tests', () {
    testWidgets(
      'Renders Recommended for You, interest selection, partial notice, error/retry, and detail sheets on 360x800',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var failFirst = true;
        String? navigatedRoute;

        final client = MockClient((request) async {
          if (failFirst) {
            return http.Response(jsonEncode({'detail': 'Temporary outage'}), 503);
          }
          return http.Response(
            jsonEncode(_sampleMapListings(hasMore: true)),
            200,
          );
        });

        final service = RecommendationApiService(
          mapApiService: MapApiService(client: client),
        );
        final store = InMemoryRecommendationPreferencesStore();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            onGenerateRoute: (settings) {
              navigatedRoute = settings.name;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Artisan Detail')),
              );
            },
            home: RecommendationsScreen(
              recommendationService: service,
              preferencesStore: store,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Error state + Retry
        expect(find.byKey(const Key('rec_error_banner')), findsOneWidget);
        failFirst = false;
        final retryBtn = find.byKey(const Key('rec_retry_btn'));
        await tester.ensureVisible(retryBtn);
        await tester.pumpAndSettle();
        await tester.tap(retryBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('rec_client_side_notice')), findsOneWidget);
        expect(find.byKey(const Key('rec_no_interests_banner')), findsOneWidget);
        expect(find.byKey(const Key('rec_partial_notice')), findsOneWidget);

        final homestayCard = find.byKey(const Key('rec_card_homestay_10'));
        await tester.scrollUntilVisible(
          homestayCard,
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(homestayCard, findsOneWidget);

        final artisanCard = find.byKey(const Key('rec_card_artisan_20'));
        await tester.scrollUntilVisible(
          artisanCard,
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(artisanCard, findsOneWidget);

        // Scroll back up to select Artisan interest -> filters to Artisan only & persists
        final artisanInterest = find.byKey(const Key('rec_interest_artisan'));
        await tester.scrollUntilVisible(
          artisanInterest,
          -200.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(artisanInterest);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          artisanCard,
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(artisanCard, findsOneWidget);
        expect(homestayCard, findsNothing);
        expect((await store.load()).selectedInterests, contains(TravelerInterest.artisan));

        // Tap View Details on Artisan -> navigates to /artisan/business?id=20
        final artisanDetails =
            find.byKey(const Key('rec_details_btn_artisan_20'));
        await tester.ensureVisible(artisanDetails);
        await tester.pumpAndSettle();
        await tester.tap(artisanDetails);
        await tester.pumpAndSettle();
        expect(navigatedRoute, '/artisan/business?id=20');
      },
    );

    testWidgets('Opens read-only detail sheet for homestay recommendations',
        (tester) async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode(_sampleMapListings()), 200),
      );
      final service = RecommendationApiService(
        mapApiService: MapApiService(client: client),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: RecommendationsScreen(
            recommendationService: service,
            preferencesStore: InMemoryRecommendationPreferencesStore(
              const TravelerPreferences(
                selectedInterests: {TravelerInterest.homestays},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final detailsBtn = find.byKey(const Key('rec_details_btn_homestay_10'));
      await tester.ensureVisible(detailsBtn);
      await tester.pumpAndSettle();
      await tester.tap(detailsBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('rec_detail_sheet')), findsOneWidget);
      expect(find.text('5 Lake Rd'), findsOneWidget);
    });

    testWidgets(
      'Traveler HomeScreen integrates Recommended for You and navigates to /recommendations',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final client = MockClient(
          (_) async => http.Response(jsonEncode(_sampleMapListings()), 200),
        );
        final recService = RecommendationApiService(
          mapApiService: MapApiService(client: client),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            routes: CeylonGoApp.getRoutes(
              recommendationService: recService,
              preferencesStore: InMemoryRecommendationPreferencesStore(),
            ),
            home: const HomeScreen(
              initialUser: UserModel(
                id: 'usr-1',
                fullName: 'Test Traveler',
                email: 't@example.com',
                role: 'traveler',
              ),
              showBottomNav: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        final exploreBtn =
            find.byKey(const Key('home_open_recommendations_btn'));
        await tester.ensureVisible(exploreBtn);
        await tester.pumpAndSettle();
        await tester.tap(exploreBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('recommendations_screen')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
