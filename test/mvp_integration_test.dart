import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/api_client.dart';
import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/utils/uuid_generator.dart';
import 'package:ceylongo/features/ai_planner/services/ai_planner_service.dart';
import 'package:ceylongo/features/artisan/models/artisan_wishlist_model.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/features/bookings/models/booking_models.dart';
import 'package:ceylongo/features/bookings/services/booking_payment_service.dart';
import 'package:ceylongo/features/bookings/widgets/booking_payment_sheet.dart';
import 'package:ceylongo/features/categories/services/discovery_service.dart';
import 'package:ceylongo/features/community/services/community_service.dart';
import 'package:ceylongo/features/profile/services/account_service.dart';
import 'package:ceylongo/features/provider/services/provider_service.dart';

class _MemStorage extends SecureStorageService {
  String? _token = 'test-jwt-token';
  UserModel? _user;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<void> saveUser(UserModel user) async => _user = user;

  @override
  Future<UserModel?> getUser() async => _user;

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
  }
}

void main() {
  group('Academic MVP Integration Contracts & Idempotency Tests', () {
    test('UuidGenerator generates canonical RFC 4122 UUID v4 strings', () {
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      final k1 = UuidGenerator.v4();
      final k2 = UuidGenerator.v4();
      expect(uuidRegex.hasMatch(k1), isTrue);
      expect(uuidRegex.hasMatch(k2), isTrue);
      expect(k1, isNot(equals(k2)));
    });

    test('AuthService handles 202 OTP registration challenge and verify-email', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/register') {
          return http.Response(
            jsonEncode({
              'message': 'OTP sent to your email',
              'email': 'nimal@ceylongo.lk',
              'registration_id': 'reg-uuid-001',
              'expires_in': 600,
              'resend_after': 60,
            }),
            202,
          );
        }
        if (request.url.path == '/api/v1/auth/verify-email') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['registration_id'], 'reg-uuid-001');
          expect(body['otp'], '123456');
          return http.Response(jsonEncode({'message': 'Email verified'}), 200);
        }
        if (request.url.path == '/api/v1/auth/reset-password') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('new_password'), isTrue);
          expect(body.containsKey('password'), isFalse);
          return http.Response(jsonEncode({'message': 'Reset successful'}), 200);
        }
        return http.Response('{}', 404);
      });

      final auth = AuthService(client: client);
      final reg = await auth.registerTraveler(
        fullName: 'Nimal Perera',
        email: 'nimal@ceylongo.lk',
        password: 'Password1!',
        phone: '+94771234567',
      );
      expect(reg.requiresOtpVerification, isTrue);
      expect(reg.challenge?.registrationId, 'reg-uuid-001');

      await auth.verifyEmailOtp(
        email: 'nimal@ceylongo.lk',
        registrationId: 'reg-uuid-001',
        otp: '123456',
      );

      final resetRes = await auth.confirmPasswordReset(
        token: 'reset-tok',
        newPassword: 'Password2!',
      );
      expect(resetRes['message'], 'Reset successful');
    });

    test('ArtisanWishlistItemModel parses MVP WishlistItem without listing_reference_id', () {
      final parsed = ArtisanWishlistItemModel.fromJson({
        'id': 4,
        'artisan_listing_id': 9,
        'user_id': 12,
        'is_available': true,
        'listing': null,
      });
      expect(parsed.id, 4);
      expect(parsed.artisanListingId, 9);
      expect(parsed.listingReferenceId, 9);
      expect(parsed.isAvailable, isTrue);
    });

    testWidgets('BookingPaymentScreen preserves identical request_key on retry after network failure',
        (tester) async {
      final seenKeys = <String>[];
      int callCount = 0;

      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/payments/simulate') {
          callCount++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          seenKeys.add(body['request_key'] as String);
          if (callCount == 1) {
            return http.Response(
              jsonEncode({'detail': 'Temporary gateway error'}),
              503,
            );
          }
          return http.Response(
            jsonEncode({
              'id': 77,
              'booking_id': 501,
              'request_key': body['request_key'],
              'attempt_no': body['attempt_no'],
              'method': 'simulated',
              'status': 'demo_succeeded',
              'display_amount': '15000',
              'currency': 'LKR',
              'created_at': '2026-11-27T10:00:00Z',
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/bookings/501') {
          return http.Response(
            jsonEncode({
              'id': 501,
              'listing_id': 3,
              'traveler_id': 9,
              'request_key': 'bkg-req-key',
              'starts_at': '2026-12-01T14:00:00Z',
              'ends_at': '2026-12-03T11:00:00Z',
              'quantity': 2,
              'total_amount': '15000',
              'currency': 'LKR',
              'status': 'confirmed',
              'created_at': '2026-11-27T09:00:00Z',
              'payments': [],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final service = BookingPaymentService(
        apiClient: ApiClient(client: client, storageService: _MemStorage()),
      );

      final booking = BookingRecord(
        id: 501,
        listingId: 3,
        travelerId: 9,
        requestKey: 'bkg-req-key',
        startsAt: DateTime(2026, 12, 1),
        endsAt: DateTime(2026, 12, 3),
        quantity: 2,
        totalAmount: '15000',
        status: 'pending',
        createdAt: DateTime(2026, 11, 27),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookingPaymentScreen(
            booking: booking,
            serviceTitle: 'Kandy Ridge Homestay',
            summarySubtitle: '2 Nights',
            service: service,
          ),
        ),
      );

      final simSuccessBtn = find.byKey(const Key('simulate_payment_success_btn'));
      await tester.ensureVisible(simSuccessBtn);
      await tester.tap(simSuccessBtn);
      await tester.pumpAndSettle();

      // First call failed with 503 -> error message shown, Retry option preserves same key
      expect(seenKeys.length, 1);
      expect(find.textContaining('Temporary gateway error'), findsOneWidget);

      await tester.tap(simSuccessBtn);
      await tester.pumpAndSettle();

      expect(seenKeys.length, 2);
      expect(seenKeys[0], equals(seenKeys[1]));
      expect(find.textContaining('Simulated Payment Succeeded'), findsOneWidget);
    });

    test('DiscoveryService, CommunityService, AiPlannerService, AccountService & ProviderService wire live endpoints',
        () async {
      final storage = _MemStorage();
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/homestays') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 1,
                  'provider_id': 2,
                  'title': 'Ella Ridge Homestay',
                  'description': 'Tea view',
                  'district': 'Badulla',
                  'locality': 'Ella',
                  'price': '12500',
                  'currency': 'LKR',
                  'host': {'id': 2, 'business_name': 'Ella Hosts'},
                  'media': [],
                  'units': [],
                },
              ],
            }),
            200,
          );
        }
        if (path == '/api/v1/community/feed') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 10,
                  'author_id': 5,
                  'author_name': 'Amaya Silva',
                  'author_type': 'traveler',
                  'author': {
                    'id': 5,
                    'full_name': 'Amaya Silva',
                    'author_type': 'traveler',
                    'member_since': '2026-01-01',
                    'is_verified_provider': false,
                  },
                  'body': 'Sunrise hike in Ella! #Ella #Nature',
                  'visibility': 'public',
                  'created_at': '2026-11-27T08:00:00Z',
                  'updated_at': '2026-11-27T08:00:00Z',
                  'likes_count': 4,
                  'comments_count': 1,
                  'viewer_has_liked': true,
                  'viewer_has_saved': false,
                  'media': [],
                },
              ],
              'total': 1,
              'page': 1,
              'page_size': 20,
              'total_pages': 1,
            }),
            200,
          );
        }
        if (path == '/api/v1/ai/planner/conversations') {
          return http.Response(
            jsonEncode([
              {
                'id': 3,
                'title': 'Ella Weekend',
                'created_at': '2026-11-27T08:00:00Z',
                'updated_at': '2026-11-27T08:00:00Z',
              },
            ]),
            200,
          );
        }
        if (path == '/api/v1/notifications') {
          return http.Response(
            jsonEncode({
              'unread_count': 1,
              'total': 1,
              'page': 1,
              'page_size': 20,
              'items': [
                {
                  'id': 99,
                  'notification_type': 'booking_confirmed',
                  'category': 'booking',
                  'title': 'Booking Confirmed',
                  'message': 'Your homestay is confirmed.',
                  'related_entity_type': 'booking',
                  'related_entity_id': 501,
                  'is_read': false,
                  'created_at': '2026-11-27T09:00:00Z',
                },
              ],
            }),
            200,
          );
        }
        if (path == '/api/v1/providers/me') {
          return http.Response(
            jsonEncode({
              'id': 7,
              'user_id': 20,
              'business_name': 'Ella Hosts',
              'phone': '+94771112222',
              'district': 'Badulla',
              'verification_status': 'approved',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final api = ApiClient(client: client, storageService: storage);
      final discovery = DiscoveryService(apiClient: api);
      final community = CommunityService(apiClient: api);
      final planner = AiPlannerService(apiClient: api);
      final account = AccountService(apiClient: api, storageService: storage);
      final provider = ProviderService(apiClient: api, storageService: storage, client: client);

      final homestays = await discovery.searchHomestays();
      expect(homestays.single.title, 'Ella Ridge Homestay');

      final posts = await community.getFeed();
      expect(posts.single.hashtags, containsAll(['#Ella', '#Nature']));
      expect(posts.single.isLikedByDemoUser, isTrue);

      final threads = await planner.getConversations();
      expect(threads.single.title, 'Ella Weekend');

      final notifPage = await account.getNotifications();
      expect(notifPage.unreadCount, 1);
      expect(notifPage.items.single.title, 'Booking Confirmed');

      final profile = await provider.getMyProviderProfile();
      expect(profile.verificationStatus, 'approved');
    });
  });
}
