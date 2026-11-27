import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/models/auth_response.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/login_screen.dart';
import 'package:ceylongo/features/auth/screens/role_selection_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/features/navigation/screens/main_navigation_shell.dart';
import 'package:ceylongo/features/profile/screens/profile_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_login_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_more_screen.dart';
import 'package:ceylongo/features/vendor/services/provider_api_service.dart';
import 'package:ceylongo/features/vendor/services/vendor_demo_service.dart';
import 'package:ceylongo/main.dart';

class _InMemoryStorage extends SecureStorageService {
  String? token;
  UserModel? user;
  Map<String, dynamic>? vendorDemoSession;

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
  Future<void> clear() async {
    token = null;
    user = null;
    vendorDemoSession = null;
  }
}

class _StubAuthService extends AuthService {
  UserModel? meUser;
  ApiError? meError;
  LoginResponse? loginResponse;
  int getMeCalls = 0;

  @override
  Future<UserModel> getMe(String accessToken) async {
    getMeCalls++;
    if (meError != null) throw meError!;
    return meUser ??
        const UserModel(
          id: '10',
          fullName: 'Nimali Perera',
          email: 'nimali@ceylongo.com',
          role: 'traveler',
        );
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    if (loginResponse != null) return loginResponse!;
    throw const ApiError(
      statusCode: 401,
      code: 'UNAUTHORIZED',
      message: 'Invalid credentials',
    );
  }
}

void main() {
  setUp(() {
    VendorDemoService.instance.signOutVendor();
  });

  group('Role Selection & Dual Authentication Navigation Tests', () {
    testWidgets(
        'Unauthenticated launch renders RoleSelectionScreen with Traveler & Vendor cards on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = _InMemoryStorage();
      final authService = _StubAuthService();

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byKey(const Key('role_card_traveler')), findsOneWidget);
      expect(find.byKey(const Key('role_card_vendor')), findsOneWidget);
      expect(find.text("I'm a Traveler"), findsOneWidget);
      expect(find.text("I'm a Vendor"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'RoleSelection -> Continue as Traveler -> LoginScreen -> Change Role -> RoleSelection',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage();
      final authService = _StubAuthService();

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      final travelerBtn = find.byKey(const Key('role_continue_traveler_btn'));
      await tester.ensureVisible(travelerBtn);
      await tester.tap(travelerBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      final changeRoleBtn = find.byKey(const Key('traveler_change_role_btn'));
      await tester.ensureVisible(changeRoleBtn);
      await tester.tap(changeRoleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets(
        'RoleSelection -> Continue as Vendor -> VendorLoginScreen -> Change Role -> RoleSelection',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage();
      final authService = _StubAuthService();

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      final vendorBtn = find.byKey(const Key('role_continue_vendor_btn'));
      await tester.ensureVisible(vendorBtn);
      await tester.tap(vendorBtn);
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);

      final changeRoleBtn = find.byKey(const Key('vendor_change_role_btn'));
      await tester.ensureVisible(changeRoleBtn);
      await tester.tap(changeRoleBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(VendorLoginScreen), findsNothing);
    });

    testWidgets(
        'Valid Traveler session restores to MainNavigationShell without calling Provider /me',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage()
        ..token = 'traveler-jwt'
        ..user = const UserModel(
          id: '10',
          fullName: 'Nimali Perera',
          email: 'nimali@ceylongo.com',
          role: 'traveler',
        );
      final authService = _StubAuthService();
      int providerMeCalls = 0;
      final providerService = ProviderApiService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/providers/me')) {
            providerMeCalls++;
          }
          return http.Response('{}', 403);
        }),
      );

      await tester.pumpWidget(
        CeylonGoApp(
          authService: authService,
          providerService: providerService,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationShell), findsOneWidget);
      expect(find.byType(VendorDashboardScreen), findsNothing);
      expect(authService.getMeCalls, greaterThanOrEqualTo(1));
      expect(providerMeCalls, 0);
    });

    testWidgets(
        'Valid approved Provider session restores to VendorDashboardScreen without calling Traveler /me',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage()
        ..token = 'provider-jwt'
        ..user = const UserModel(
          id: '45',
          fullName: 'Saman Silva',
          email: 'saman@kandyvilla.lk',
          role: 'provider',
        );
      final authService = _StubAuthService();
      int providerMeCalls = 0;
      final providerService = ProviderApiService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/providers/me')) {
            providerMeCalls++;
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
          authService: authService,
          providerService: providerService,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorDashboardScreen), findsOneWidget);
      expect(find.text('Welcome, Kandy Heritage Villa'), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsNothing);
      expect(providerMeCalls, 1);
      expect(authService.getMeCalls, 0);
    });

    testWidgets(
        'Expired token (401) clears session and falls back to RoleSelectionScreen',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage()
        ..token = 'expired-traveler-jwt'
        ..user = const UserModel(
          id: '10',
          fullName: 'Nimali Perera',
          email: 'nimali@ceylongo.com',
          role: 'traveler',
        );
      final authService = _StubAuthService()
        ..meError = const ApiError(
          statusCode: 401,
          code: 'UNAUTHORIZED',
          message: 'Expired',
        );
      final providerService = ProviderApiService(
        client: MockClient((_) async => http.Response('{}', 404)),
      );

      await tester.pumpWidget(
        CeylonGoApp(
          authService: authService,
          providerService: providerService,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(storage.token, isNull);
      expect(storage.user, isNull);
    });

    testWidgets(
        'Traveler LoginScreen rejects provider account without saving token',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage();
      final authService = _StubAuthService()
        ..loginResponse = LoginResponse(
          accessToken: 'provider-jwt-leak-check',
          tokenType: 'bearer',
          expiresIn: 3600,
          user: const UserModel(
            id: '45',
            fullName: 'Saman Silva',
            email: 'saman@kandyvilla.lk',
            role: 'provider',
          ),
        );

      await tester.pumpWidget(
        CeylonGoApp(
          authService: authService,
          storageService: storage,
          initialRoute: '/login',
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'saman@kandyvilla.lk',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'Password@123',
      );

      final signInBtn = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsNothing);
      expect(
        find.text(
          'This account is registered as a Vendor. Please use Vendor Sign In.',
        ),
        findsOneWidget,
      );
      expect(storage.token, isNull);
    });

    testWidgets(
        'Traveler logout from ProfileScreen clears session and returns to RoleSelectionScreen',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage()
        ..token = 'traveler-jwt'
        ..user = const UserModel(
          id: '10',
          fullName: 'Nimali Perera',
          email: 'nimali@ceylongo.com',
          role: 'traveler',
        );
      final authService = _StubAuthService();

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/role-selection': (_) => const RoleSelectionScreen(),
          },
          home: ProfileScreen(
            authService: authService,
            storageService: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.byKey(const Key('profile_logout_btn'));
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_logout_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(storage.token, isNull);
      expect(storage.user, isNull);
    });

    testWidgets(
        'Vendor logout from VendorMoreScreen clears session and returns to RoleSelectionScreen',
        (WidgetTester tester) async {
      final storage = _InMemoryStorage()..token = 'provider-jwt';

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/role-selection': (_) => const RoleSelectionScreen(),
          },
          home: VendorMoreScreen(storageService: storage),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final logoutBtn = find.byKey(const Key('vendor_more_logout_btn'));
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(storage.token, isNull);
    });
  });
}
