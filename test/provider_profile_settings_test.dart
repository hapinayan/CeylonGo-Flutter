import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/vendor/models/provider_profile_model.dart';
import 'package:ceylongo/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_login_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_profile_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_settings_screen.dart';
import 'package:ceylongo/features/vendor/services/provider_api_service.dart';
import 'package:ceylongo/features/vendor/services/vendor_demo_service.dart';
import 'package:ceylongo/main.dart';

class _TestSecureStorage extends SecureStorageService {
  String? token;
  UserModel? user;
  Map<String, dynamic>? demoSession;

  @override
  Future<void> saveToken(String token) async => this.token = token;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<bool> hasToken() async => token != null && token!.isNotEmpty;

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<void> saveUser(UserModel user) async => this.user = user;

  @override
  Future<UserModel?> getUser() async => user;

  @override
  Future<void> saveVendorDemoSession(Map<String, dynamic> demoData) async {
    demoSession = {...demoData, 'is_demo_session': true};
  }

  @override
  Future<Map<String, dynamic>?> getVendorDemoSession() async => demoSession;

  @override
  Future<void> clearVendorDemoSession() async => demoSession = null;

  @override
  Future<void> clear() async {
    token = null;
    user = null;
    demoSession = null;
  }
}

Map<String, dynamic> _sampleProviderJson({
  String businessName = 'Kandy Hilltop Villa',
  String phone = '0771234567',
  String district = 'Kandy',
  bool nullableFieldsNull = false,
}) {
  return {
    'id': 12,
    'user_id': 45,
    'email': 'provider@kandyvilla.lk',
    'full_name': 'Nimal Perera',
    'role': 'provider',
    'is_active': true,
    'business_name': businessName,
    'provider_type': 'homestay',
    'phone': phone,
    'secondary_phone': nullableFieldsNull ? null : '0812233445',
    'district': district,
    'description': nullableFieldsNull ? null : 'Peaceful hilltop villa.',
    'business_registration_number': nullableFieldsNull ? null : 'BR-2026-99',
    'approval_status': 'approved',
    'business_province': nullableFieldsNull ? null : 'Central',
    'business_district': nullableFieldsNull ? null : 'Kandy',
    'business_city': nullableFieldsNull ? null : 'Peradeniya',
    'business_landmark': nullableFieldsNull ? null : 'Near Botanical Garden',
    'business_postal_code': nullableFieldsNull ? null : '20400',
    'created_at': nullableFieldsNull ? null : '2026-10-01T09:30:00Z',
  };
}

void main() {
  setUp(() {
    VendorDemoService.instance.resetToDefaults();
  });

  group('ProviderProfile & Validators Unit Tests', () {
    test('Parses full ProviderProfile JSON and nullable fields safely', () {
      final full = ProviderProfile.fromJson(_sampleProviderJson());
      expect(full.id, 12);
      expect(full.userId, 45);
      expect(full.email, 'provider@kandyvilla.lk');
      expect(full.businessName, 'Kandy Hilltop Villa');
      expect(full.secondaryPhone, '0812233445');
      expect(full.createdAt, isNotNull);

      final sparse = ProviderProfile.fromJson(
        _sampleProviderJson(nullableFieldsNull: true),
      );
      expect(sparse.secondaryPhone, isNull);
      expect(sparse.description, isNull);
      expect(sparse.businessRegistrationNumber, isNull);
      expect(sparse.businessProvince, isNull);
      expect(sparse.businessDistrict, isNull);
      expect(sparse.businessCity, isNull);
      expect(sparse.businessLandmark, isNull);
      expect(sparse.businessPostalCode, isNull);
      expect(sparse.createdAt, isNull);
    });

    test('PATCH diffAgainst sends only modified editable fields', () {
      final original = ProviderProfile.fromJson(_sampleProviderJson());
      final patch = ProviderProfilePatch(
        businessName: 'Kandy Hilltop Villa Updated',
        phone: '0771234567',
        secondaryPhone: '0812233445',
        district: 'Kandy',
        description: 'Peaceful hilltop villa.',
        businessProvince: 'Central',
        businessDistrict: 'Kandy',
        businessCity: 'Peradeniya',
        businessLandmark: 'Near Botanical Garden',
        businessPostalCode: '20400',
      ).diffAgainst(original);

      expect(patch, {'business_name': 'Kandy Hilltop Villa Updated'});
      expect(patch.containsKey('provider_type'), isFalse);
      expect(patch.containsKey('approval_status'), isFalse);
      expect(patch.containsKey('email'), isFalse);
    });

    test('ProviderValidators enforce profile & password rules', () {
      expect(ProviderValidators.validateBusinessName('A'), isNotNull);
      expect(ProviderValidators.validateBusinessName('Valid Stay'), isNull);

      expect(
        ProviderValidators.validatePhone('12345', requiredField: true),
        isNotNull,
      );
      expect(
        ProviderValidators.validatePhone('0771234567', requiredField: true),
        isNull,
      );
      expect(
        ProviderValidators.validatePhone('+94771234567', requiredField: true),
        isNull,
      );
      expect(
        ProviderValidators.validatePhone('', requiredField: false),
        isNull,
      );

      expect(
        ProviderValidators.validateNewPassword(
          'short',
          currentPassword: 'OldPassword123',
        ),
        isNotNull,
      );
      expect(
        ProviderValidators.validateNewPassword(
          'SamePass123',
          currentPassword: 'SamePass123',
        ),
        isNotNull,
      );
      expect(
        ProviderValidators.validateConfirmNewPassword(
          'Mismatch123',
          newPassword: 'NewPassword123',
        ),
        isNotNull,
      );
    });
  });

  group('ProviderApiService HTTP & Error Mapping Tests', () {
    test('Maps 401, 403, 404, 422 detail list, 429, 500, SocketException, TimeoutException',
        () async {
      for (final status in [401, 403, 404, 429, 500]) {
        final service = ProviderApiService(
          client: MockClient((_) async {
            return http.Response(
              jsonEncode({'detail': 'Error $status'}),
              status,
            );
          }),
        );
        await expectLater(
          service.getProfile('jwt-token'),
          throwsA(
            isA<ApiError>().having((e) => e.statusCode, 'statusCode', status),
          ),
        );
      }

      final service422 = ProviderApiService(
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'detail': [
                {
                  'loc': ['body', 'phone'],
                  'msg': 'Invalid Sri Lankan phone number format.',
                },
              ],
            }),
            422,
          );
        }),
      );
      await expectLater(
        service422.updateProfile(
          accessToken: 'jwt',
          patchData: {'phone': '000'},
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.fields['phone'], 'phone field', isNotNull),
        ),
      );

      final socketService = ProviderApiService(
        client: MockClient((_) => throw const SocketException('Refused')),
      );
      await expectLater(
        socketService.getProfile('jwt'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );

      final timeoutService = ProviderApiService(
        client: MockClient((_) => throw TimeoutException('Timed out')),
      );
      await expectLater(
        timeoutService.getProfile('jwt'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );
    });
  });

  group('Provider Profile & Settings Widget Tests', () {
    testWidgets(
        'Real Provider loads profile, validates, sends PATCH with modified fields only, and refreshes UI',
        (WidgetTester tester) async {
      Map<String, dynamic>? capturedPatchBody;
      final storage = _TestSecureStorage()..token = 'real-provider-jwt';
      VendorDemoService.instance.setAuthenticatedVendor(
        id: '45',
        businessName: 'Kandy Hilltop Villa',
        email: 'provider@kandyvilla.lk',
      );

      final service = ProviderApiService(
        client: MockClient((req) async {
          if (req.method == 'GET' && req.url.path.endsWith('/providers/me')) {
            return http.Response(jsonEncode(_sampleProviderJson()), 200);
          }
          if (req.method == 'PATCH' && req.url.path.endsWith('/providers/me')) {
            capturedPatchBody =
                jsonDecode(req.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode(
                _sampleProviderJson(businessName: 'Kandy Royal Villa'),
              ),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            '/vendor/login': (_) => const VendorLoginScreen(),
          },
          home: VendorProfileScreen(
            providerService: service,
            storageService: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('provider@kandyvilla.lk'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_edit_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('profile_business_name_field')),
        'Kandy Royal Villa',
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      final saveBtn = find.byKey(const Key('profile_save_btn'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(capturedPatchBody, {'business_name': 'Kandy Royal Villa'});
      expect(
        find.byKey(const Key('profile_success_banner')),
        findsOneWidget,
      );
      expect(
        VendorDemoService.instance.currentVendor.businessName,
        'Kandy Royal Villa',
      );
    });

    testWidgets(
        '401 on GET /providers/me clears storage and redirects to VendorLoginScreen',
        (WidgetTester tester) async {
      final storage = _TestSecureStorage()..token = 'expired-jwt';
      VendorDemoService.instance.setAuthenticatedVendor(
        id: '45',
        businessName: 'Kandy Hilltop Villa',
        email: 'provider@kandyvilla.lk',
      );

      final service = ProviderApiService(
        client: MockClient((_) async {
          return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            '/vendor/login': (_) => VendorLoginScreen(storageService: storage),
          },
          home: VendorProfileScreen(
            providerService: service,
            storageService: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(storage.token, isNull);
    });

    testWidgets(
        'Settings Change Password validates inputs, calls real API, and clears fields on success',
        (WidgetTester tester) async {
      Map<String, dynamic>? capturedPasswordBody;
      final storage = _TestSecureStorage()..token = 'real-provider-jwt';
      VendorDemoService.instance.setAuthenticatedVendor(
        id: '45',
        businessName: 'Kandy Hilltop Villa',
        email: 'provider@kandyvilla.lk',
      );

      final service = ProviderApiService(
        client: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.path.endsWith('/providers/me/change-password')) {
            capturedPasswordBody =
                jsonDecode(req.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({'message': 'Password changed successfully'}),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            '/vendor/login': (_) => VendorLoginScreen(storageService: storage),
            '/vendor/profile': (_) => VendorProfileScreen(
                  providerService: service,
                  storageService: storage,
                ),
          },
          home: VendorSettingsScreen(
            providerService: service,
            storageService: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('settings_current_password_field')),
        'OldPass@1234',
      );
      await tester.enterText(
        find.byKey(const Key('settings_new_password_field')),
        'NewStrong@5678',
      );
      await tester.enterText(
        find.byKey(const Key('settings_confirm_password_field')),
        'NewStrong@5678',
      );

      final changeBtn = find.byKey(const Key('settings_change_password_btn'));
      await tester.ensureVisible(changeBtn);
      await tester.pumpAndSettle();
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      expect(capturedPasswordBody, {
        'current_password': 'OldPass@1234',
        'new_password': 'NewStrong@5678',
        'confirm_new_password': 'NewStrong@5678',
      });
      expect(
        find.byKey(const Key('settings_password_success')),
        findsOneWidget,
      );
      expect(find.text('Password changed successfully'), findsOneWidget);
    });

    testWidgets(
        'Demo Mode never triggers real API calls in Profile or Settings',
        (WidgetTester tester) async {
      final storage = _TestSecureStorage();
      VendorDemoService.instance.signInDemoVendor();

      final failIfCalledService = ProviderApiService(
        client: MockClient((req) async {
          fail('Demo Mode must not call real API: ${req.method} ${req.url}');
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VendorProfileScreen(
            providerService: failIfCalledService,
            storageService: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_demo_banner')), findsOneWidget);
      expect(find.byKey(const Key('profile_edit_btn')), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VendorSettingsScreen(
            providerService: failIfCalledService,
            storageService: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('settings_password_demo_disabled')),
        findsOneWidget,
      );
    });

    testWidgets(
        'Provider Login via POST /api/v1/providers/login stores token and opens VendorDashboardScreen',
        (WidgetTester tester) async {
      final storage = _TestSecureStorage();
      final service = ProviderApiService(
        client: MockClient((req) async {
          if (req.method == 'POST' &&
              req.url.path.endsWith('/providers/login')) {
            return http.Response(
              jsonEncode({
                'access_token': 'provider-jwt-999',
                'token_type': 'bearer',
                'user': {
                  'id': 45,
                  'email': 'provider@kandyvilla.lk',
                  'full_name': 'Nimal Perera',
                  'role': 'provider',
                  'is_active': true,
                  'business_name': 'Kandy Hilltop Villa',
                  'provider_type': 'homestay',
                  'district': 'Kandy',
                  'approval_status': 'approved',
                },
              }),
              200,
            );
          }
          if (req.method == 'GET' && req.url.path.endsWith('/providers/me')) {
            return http.Response(jsonEncode(_sampleProviderJson()), 200);
          }
          return http.Response('Not found', 404);
        }),
      );

      await tester.pumpWidget(
        CeylonGoApp(providerService: service, storageService: storage),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('vendor_login_email_field')),
        'provider@kandyvilla.lk',
      );
      await tester.enterText(
        find.byKey(const Key('vendor_login_password_field')),
        'StrongPass@1234',
      );
      final submitBtn = find.byKey(const Key('vendor_login_submit_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.byType(VendorDashboardScreen), findsOneWidget);
      expect(storage.token, 'provider-jwt-999');
      expect(
        VendorDemoService.instance.currentVendor.isDemoSession,
        isFalse,
      );
    });
  });
}

