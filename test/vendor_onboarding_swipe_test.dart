import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/login_screen.dart';
import 'package:ceylongo/features/auth/screens/role_selection_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_login_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_onboarding_screen.dart';
import 'package:ceylongo/features/vendor/services/provider_api_service.dart';
import 'package:ceylongo/features/vendor/services/vendor_demo_service.dart';
import 'package:ceylongo/main.dart';

class _OnboardingTestStorage extends SecureStorageService {
  String? token;
  UserModel? user;
  Map<String, dynamic>? vendorDemoSession;
  bool vendorOnboardingCompleted = false;

  @override
  Future<void> saveToken(String token) async => this.token = token;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveUser(UserModel user) async => this.user = user;

  @override
  Future<UserModel?> getUser() async => user;

  @override
  Future<void> saveVendorDemoSession(Map<String, dynamic> session) async =>
      vendorDemoSession = Map<String, dynamic>.from(session);

  @override
  Future<Map<String, dynamic>?> getVendorDemoSession() async =>
      vendorDemoSession;

  @override
  Future<void> clearVendorDemoSession() async => vendorDemoSession = null;

  @override
  Future<bool> isVendorOnboardingCompleted() async => vendorOnboardingCompleted;

  @override
  Future<void> setVendorOnboardingCompleted({bool completed = true}) async =>
      vendorOnboardingCompleted = completed;

  @override
  Future<void> clear() async {
    token = null;
    user = null;
    vendorDemoSession = null;
  }
}

class _NoopAuthService extends AuthService {
  @override
  Future<UserModel> getMe(String accessToken) async {
    return const UserModel(
      id: '10',
      fullName: 'Traveler',
      email: 'traveler@ceylongo.com',
      role: 'traveler',
    );
  }
}

void main() {
  setUp(() {
    VendorDemoService.instance.signOutVendor();
  });

  group('Vendor Onboarding Swipe Screens Tests', () {
    testWidgets(
        'First-time Continue as Vendor opens VendorOnboardingScreen on 360x800 without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = _OnboardingTestStorage();

      await tester.pumpWidget(
        CeylonGoApp(
          authService: _NoopAuthService(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);

      final vendorBtn = find.byKey(const Key('role_continue_vendor_btn'));
      await tester.ensureVisible(vendorBtn);
      await tester.tap(vendorBtn);
      await tester.pumpAndSettle();

      expect(find.byType(VendorOnboardingScreen), findsOneWidget);
      expect(find.text('Showcase Your Business'), findsOneWidget);
      expect(
        find.text(
          'Create and manage your homestays, tours, rentals, and local experiences in one place.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('vendor_onboarding_skip_btn')), findsOneWidget);
      expect(find.byKey(const Key('vendor_onboarding_next_btn')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Horizontal drag swipes left/right across all 3 pages, updates dots, and respects boundaries on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = _OnboardingTestStorage();

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/vendor/login': (_) => VendorLoginScreen(storageService: storage),
          },
          home: VendorOnboardingScreen(storageService: storage),
        ),
      );
      await tester.pumpAndSettle();

      double dotWidth(int idx) {
        final box = tester.getSize(
          find.byKey(Key('vendor_onboarding_dot_$idx')),
        );
        return box.width;
      }

      final pageView = find.byKey(const Key('vendor_onboarding_pageview'));

      // Initial Page 1 + boundary swipe right stays on Page 1 (26+8=34 active, 8+8=16 inactive)
      expect(find.text('Showcase Your Business'), findsOneWidget);
      expect(dotWidth(0), 34);
      expect(dotWidth(1), 16);
      expect(dotWidth(2), 16);

      await tester.drag(pageView, const Offset(280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Showcase Your Business'), findsOneWidget);
      expect(dotWidth(0), 34);

      // Drag LEFT (slightly diagonal thumb swipe) from Page 1 -> Page 2
      await tester.drag(pageView, const Offset(-280, 24));
      await tester.pumpAndSettle();
      expect(find.text('Manage Bookings Easily'), findsOneWidget);
      expect(
        find.text(
          'Stay organized with booking requests, availability, and customer reservations.',
        ),
        findsOneWidget,
      );
      expect(dotWidth(0), 16);
      expect(dotWidth(1), 34);
      expect(dotWidth(2), 16);

      // Drag LEFT from Page 2 -> Page 3
      await tester.drag(pageView, const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Grow with CeylonGo'), findsOneWidget);
      expect(
        find.text(
          'View your earnings, track settlements, and manage your tourism business.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('vendor_onboarding_get_started_btn')),
        findsOneWidget,
      );
      expect(dotWidth(0), 16);
      expect(dotWidth(1), 16);
      expect(dotWidth(2), 34);

      // Boundary swipe LEFT on Page 3 stays on Page 3
      await tester.drag(pageView, const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Grow with CeylonGo'), findsOneWidget);
      expect(dotWidth(2), 34);

      // Drag RIGHT from Page 3 -> Page 2
      await tester.drag(pageView, const Offset(280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Manage Bookings Easily'), findsOneWidget);
      expect(dotWidth(1), 34);

      // Drag RIGHT from Page 2 -> Page 1
      await tester.drag(pageView, const Offset(280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Showcase Your Business'), findsOneWidget);
      expect(dotWidth(0), 34);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Next button advances pages and Get Started persists completion & navigates to VendorLoginScreen',
        (WidgetTester tester) async {
      final storage = _OnboardingTestStorage();

      await tester.pumpWidget(
        CeylonGoApp(
          authService: _NoopAuthService(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      final vendorBtn = find.byKey(const Key('role_continue_vendor_btn'));
      await tester.ensureVisible(vendorBtn);
      await tester.tap(vendorBtn);
      await tester.pumpAndSettle();

      // Page 1 -> Page 2 via Next
      await tester.tap(find.byKey(const Key('vendor_onboarding_next_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Manage Bookings Easily'), findsOneWidget);

      // Page 2 -> Page 3 via Next
      await tester.tap(find.byKey(const Key('vendor_onboarding_next_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Grow with CeylonGo'), findsOneWidget);

      // Page 3 -> Get Started -> VendorLoginScreen
      await tester.tap(
        find.byKey(const Key('vendor_onboarding_get_started_btn')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(find.byType(VendorOnboardingScreen), findsNothing);
      expect(storage.vendorOnboardingCompleted, isTrue);
    });

    testWidgets(
        'Skip button persists completion, navigates to VendorLoginScreen, and does not reappear after completion or logout',
        (WidgetTester tester) async {
      final storage = _OnboardingTestStorage();

      await tester.pumpWidget(
        CeylonGoApp(
          authService: _NoopAuthService(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('role_continue_vendor_btn')),
      );
      await tester.tap(find.byKey(const Key('role_continue_vendor_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(VendorOnboardingScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('vendor_onboarding_skip_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(storage.vendorOnboardingCompleted, isTrue);

      // Simulate clearing auth storage (logout) and reopening RoleSelection -> Continue as Vendor
      await storage.clear();
      expect(await storage.isVendorOnboardingCompleted(), isTrue);

      final changeRoleBtn = find.byKey(const Key('vendor_change_role_btn'));
      await tester.ensureVisible(changeRoleBtn);
      await tester.tap(changeRoleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('role_continue_vendor_btn')),
      );
      await tester.tap(find.byKey(const Key('role_continue_vendor_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(find.byType(VendorOnboardingScreen), findsNothing);
    });

    testWidgets(
        'Traveler flow remains unaffected regardless of Vendor onboarding state',
        (WidgetTester tester) async {
      final storage = _OnboardingTestStorage();

      await tester.pumpWidget(
        CeylonGoApp(
          authService: _NoopAuthService(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      final travelerBtn = find.byKey(const Key('role_continue_traveler_btn'));
      await tester.ensureVisible(travelerBtn);
      await tester.tap(travelerBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(VendorOnboardingScreen), findsNothing);
      expect(storage.vendorOnboardingCompleted, isFalse);
    });

    testWidgets(
        'Existing authenticated Provider and Vendor Demo sessions bypass onboarding directly to VendorDashboardScreen',
        (WidgetTester tester) async {
      final storage = _OnboardingTestStorage()
        ..token = 'provider-jwt'
        ..user = const UserModel(
          id: '45',
          fullName: 'Saman Silva',
          email: 'saman@kandyvilla.lk',
          role: 'provider',
        )
        ..vendorOnboardingCompleted = false;

      final providerService = ProviderApiService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/providers/me')) {
            return http.Response(
              jsonEncode({
                'id': 1,
                'user_id': 45,
                'email': 'saman@kandyvilla.lk',
                'full_name': 'Saman Silva',
                'role': 'provider',
                'is_active': true,
                'business_name': 'Kandy Heritage Villa',
                'provider_type': 'homestay',
                'phone': '+94771234567',
                'district': 'Kandy',
                'approval_status': 'approved',
                'created_at': '2026-01-01T00:00:00Z',
              }),
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      );

      await tester.pumpWidget(
        CeylonGoApp(
          authService: _NoopAuthService(),
          providerService: providerService,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorDashboardScreen), findsOneWidget);
      expect(find.byType(VendorOnboardingScreen), findsNothing);
    });

    testWidgets(
        'Back button steps back through onboarding pages and pops to RoleSelectionScreen from page 1 without marking completed',
        (WidgetTester tester) async {
      final storage = _OnboardingTestStorage();

      await tester.pumpWidget(
        CeylonGoApp(
          authService: _NoopAuthService(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('role_continue_vendor_btn')),
      );
      await tester.tap(find.byKey(const Key('role_continue_vendor_btn')));
      await tester.pumpAndSettle();

      // Advance to Page 2
      await tester.tap(find.byKey(const Key('vendor_onboarding_next_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Manage Bookings Easily'), findsOneWidget);

      // Back button returns to Page 1
      await tester.tap(find.byKey(const Key('vendor_onboarding_back_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Showcase Your Business'), findsOneWidget);

      // Back button on Page 1 pops to RoleSelectionScreen without marking completed
      await tester.tap(find.byKey(const Key('vendor_onboarding_back_btn')));
      await tester.pumpAndSettle();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(storage.vendorOnboardingCompleted, isFalse);
    });
  });
}

