import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/artisan/models/artisan_reservation_model.dart';
import 'package:ceylongo/features/artisan/models/showcase_item_model.dart';
import 'package:ceylongo/features/artisan/screens/artisan_reservation_form_screen.dart';
import 'package:ceylongo/features/artisan/screens/artisan_reservation_history_screen.dart';
import 'package:ceylongo/features/artisan/services/artisan_service.dart';
import 'package:ceylongo/features/artisan/widgets/reservation_status_badge.dart';

class MockAuthStorage extends SecureStorageService {
  final bool loggedIn;
  MockAuthStorage({this.loggedIn = true});

  @override
  Future<bool> hasToken() async => loggedIn;

  @override
  Future<String?> getToken() async => loggedIn ? 'valid_test_token' : null;
}

void main() {
  group('ReservationStatusBadge Widget Tests', () {
    testWidgets('renders all 6 statuses correctly with respective labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ReservationStatusBadge(status: ReservationStatus.pending),
                ReservationStatusBadge(status: ReservationStatus.confirmed),
                ReservationStatusBadge(status: ReservationStatus.readyForPickup),
                ReservationStatusBadge(status: ReservationStatus.completed),
                ReservationStatusBadge(status: ReservationStatus.cancelled),
                ReservationStatusBadge(status: ReservationStatus.expired),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pending Approval'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Ready for Pickup'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
    });
  });

  group('ArtisanReservationFormScreen Widget Tests', () {
    final mockProduct = ShowcaseItemResponse(
      id: 50,
      artisanListingId: 1,
      title: 'Hand-Carved Peacock Mask',
      itemType: 'product',
      price: 8500.0,
      currency: 'LKR',
      sku: 'MASK-001',
      stockQuantity: 5,
      isAvailable: true,
      isActive: true,
      approvalStatus: 'approved',
      listingTitle: 'Ambalangoda Studio',
      images: [],
    );

    testWidgets('renders product summary, updates quantity and estimated total price', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final service = ArtisanService(
        client: mockClient,
        storageService: MockAuthStorage(loggedIn: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanReservationFormScreen(
            product: mockProduct,
            artisanService: service,
            storageService: MockAuthStorage(loggedIn: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hand-Carved Peacock Mask'), findsOneWidget);
      expect(find.text('Ambalangoda Studio'), findsOneWidget);
      expect(find.text('5 In Stock'), findsOneWidget);

      // Initial quantity is 1 -> Estimated total is LKR 8500
      expect(find.text('LKR 8500'), findsWidgets);

      // Tap + button to increment quantity
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('LKR 17000'), findsOneWidget);

      // Verify payment notice
      expect(
        find.textContaining('In-store pickup only. No advance online payment is collected.'),
        findsOneWidget,
      );
    });

    testWidgets('submits reservation and displays success confirmation screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/artisan-reservations') {
          return http.Response(
            jsonEncode({
              'id': 105,
              'showcase_item_id': 50,
              'artisan_listing_id': 1,
              'traveler_id': 22,
              'quantity': 1,
              'total_price': 8500.0,
              'currency': 'LKR',
              'reservation_status': 'pending',
              'pickup_date': '2026-11-25',
              'item_title': 'Hand-Carved Peacock Mask',
              'listing_title': 'Ambalangoda Studio',
              'created_at': '2026-11-19T10:00:00Z',
              'updated_at': '2026-11-19T10:00:00Z',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final service = ArtisanService(
        client: mockClient,
        storageService: MockAuthStorage(loggedIn: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanReservationFormScreen(
            product: mockProduct,
            artisanService: service,
            storageService: MockAuthStorage(loggedIn: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit reservation
      await tester.tap(find.text('Confirm In-Store Reservation'));
      await tester.pumpAndSettle();

      // Verify confirmation screen
      expect(find.text('Reservation Placed Successfully!'), findsOneWidget);
      expect(find.text('Reservation Reference: #105'), findsOneWidget);
      expect(find.text('View My Reservations'), findsOneWidget);
    });

    testWidgets('unauthenticated traveler triggers login required dialog', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async => http.Response('{}', 200));

      final service = ArtisanService(
        client: mockClient,
        storageService: MockAuthStorage(loggedIn: false),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanReservationFormScreen(
            product: mockProduct,
            artisanService: service,
            storageService: MockAuthStorage(loggedIn: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm In-Store Reservation'));
      await tester.pumpAndSettle();

      expect(find.text('Login Required'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });

  group('ArtisanReservationHistoryScreen Widget Tests', () {
    testWidgets('renders reservations and handles cancellation modal', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/artisan-reservations/me') {
          return http.Response(
            jsonEncode([
              {
                'id': 201,
                'showcase_item_id': 50,
                'artisan_listing_id': 1,
                'traveler_id': 10,
                'quantity': 1,
                'total_price': 8500.0,
                'currency': 'LKR',
                'reservation_status': 'confirmed',
                'pickup_date': '2026-11-28',
                'item_title': 'Peacock Mask',
                'listing_title': 'Ambalangoda Studio',
                'created_at': '2026-11-19T10:00:00Z',
                'updated_at': '2026-11-19T10:00:00Z',
              },
              {
                'id': 202,
                'showcase_item_id': 55,
                'artisan_listing_id': 2,
                'traveler_id': 10,
                'quantity': 2,
                'total_price': 5000.0,
                'currency': 'LKR',
                'reservation_status': 'completed',
                'pickup_date': '2026-11-15',
                'item_title': 'Clay Pitcher',
                'listing_title': 'Kelani Pottery',
                'created_at': '2026-11-10T10:00:00Z',
                'updated_at': '2026-11-15T15:00:00Z',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.url.path == '/api/v1/artisan-reservations/201/cancel') {
          return http.Response(
            jsonEncode({
              'id': 201,
              'showcase_item_id': 50,
              'artisan_listing_id': 1,
              'traveler_id': 10,
              'quantity': 1,
              'total_price': 8500.0,
              'currency': 'LKR',
              'reservation_status': 'cancelled',
              'cancellation_reason': 'Trip postponed',
              'pickup_date': '2026-11-28',
              'item_title': 'Peacock Mask',
              'listing_title': 'Ambalangoda Studio',
              'created_at': '2026-11-19T10:00:00Z',
              'updated_at': '2026-11-19T10:10:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{}', 404);
      });

      final service = ArtisanService(
        client: mockClient,
        storageService: MockAuthStorage(loggedIn: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ArtisanReservationHistoryScreen(
            artisanService: service,
            storageService: MockAuthStorage(loggedIn: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify loaded reservations
      expect(find.text('Reservation #201'), findsOneWidget);
      expect(find.text('Peacock Mask'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Cancel Reservation'), findsOneWidget);

      expect(find.text('Reservation #202'), findsOneWidget);
      expect(find.text('Clay Pitcher'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Review Workshop'), findsOneWidget);

      // Cancel reservation #201
      await tester.tap(find.text('Cancel Reservation'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Cancel'), findsOneWidget);
      await tester.tap(find.text('Confirm Cancel'));
      await tester.pumpAndSettle();

      // Status updates to Cancelled
      expect(find.text('Cancelled'), findsOneWidget);
    });
  });
}

