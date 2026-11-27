import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/vendor/models/provider_identity_models.dart';
import 'package:ceylongo/features/vendor/screens/provider_onboarding_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_login_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_register_screen.dart';
import 'package:ceylongo/features/vendor/services/provider_identity_service.dart';
import 'package:ceylongo/features/vendor/services/vendor_demo_service.dart';
import 'package:ceylongo/features/vendor/services/vendor_identity_doc_picker.dart';

final Uint8List _samplePng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _FakeDocPicker implements VendorIdentityDocPicker {
  @override
  Future<IdentityDocumentFile?> pickDocument({
    required IdentityDocKind kind,
    required IdentityPickSource source,
  }) async {
    return IdentityDocumentFile(
      kind: kind,
      safeFilename: '${kind.fieldName}.png',
      mimeType: 'image/png',
      bytes: _samplePng,
    );
  }
}

Map<String, dynamic> _draftJson({
  bool personalCompleted = false,
  bool businessCompleted = false,
  bool selfieUploaded = false,
  bool nicFrontUploaded = false,
  bool nicBackUploaded = false,
  bool identityCompleted = false,
}) {
  return {
    'email': 'realprovider@ceylongo.lk',
    'full_name': personalCompleted ? 'Saman Kumara' : null,
    'phone': personalCompleted ? '0771234567' : null,
    'identity_document_type': 'nic',
    'nic_number': personalCompleted ? '199512345678' : null,
    'date_of_birth': personalCompleted ? '1995-05-12' : null,
    'gender': personalCompleted ? 'Male' : null,
    'nationality': personalCompleted ? 'Sri Lankan' : null,
    'permanent_province': personalCompleted ? 'Central' : null,
    'permanent_district': personalCompleted ? 'Kandy' : null,
    'permanent_city': personalCompleted ? 'Peradeniya' : null,
    'permanent_landmark': personalCompleted ? 'Near Main Gate' : null,
    'permanent_postal_code': personalCompleted ? '20400' : null,
    'business_name': businessCompleted ? 'Kandy Tea Estate Stay' : null,
    'provider_type': businessCompleted ? 'homestay' : null,
    'description':
        businessCompleted ? 'Scenic estate homestay in Kandy.' : null,
    'selfie_uploaded': selfieUploaded,
    'nic_front_uploaded': nicFrontUploaded,
    'nic_back_uploaded': nicBackUploaded,
    'personal_completed': personalCompleted,
    'business_completed': businessCompleted,
    'identity_completed': identityCompleted,
    'current_step': identityCompleted
        ? 'review'
        : (businessCompleted
            ? 'identity'
            : (personalCompleted ? 'business' : 'personal')),
  };
}

void main() {
  setUp(() {
    VendorDemoService.instance.resetToDefaults();
  });

  group('Onboarding Models & Validators Unit Tests', () {
    test('PersonalDetailsPayload & BusinessDetailsPayload serialize accurately',
        () {
      const personal = PersonalDetailsPayload(
        fullName: ' Saman Kumara ',
        phone: '0771234567',
        dateOfBirth: '1995-05-12',
        gender: 'Male',
        nationality: 'Sri Lankan',
        identityDocumentType: 'nic',
        nicNumber: '123456789v',
        permanentProvince: 'Central',
        permanentDistrict: 'Kandy',
        permanentCity: 'Peradeniya',
        permanentLandmark: 'Near Main Gate',
        permanentPostalCode: '20400',
      );
      final pJson = personal.toJson();
      expect(pJson['full_name'], 'Saman Kumara');
      expect(pJson['nic_number'], '123456789V');
      expect(pJson['identity_document_type'], 'nic');

      const business = BusinessDetailsPayload(
        businessName: 'Kandy Tea Stay',
        providerType: 'homestay',
        description: 'Peaceful hilltop villa.',
        sameAsPermanent: true,
      );
      final bJson = business.toJson();
      expect(bJson['business_name'], 'Kandy Tea Stay');
      expect(bJson['provider_type'], 'homestay');
      expect(bJson['same_as_permanent'], isTrue);
      expect(bJson['business_province'], isNull);
    });

    test('ProviderOnboardingValidators enforce DOB 18+, NIC, and Passport', () {
      final now = DateTime.utc(2026, 11, 27);
      expect(
        ProviderOnboardingValidators.validateDateOfBirth('2012-01-01', now: now),
        isNotNull,
      );
      expect(
        ProviderOnboardingValidators.validateDateOfBirth('1995-05-12', now: now),
        isNull,
      );

      expect(
        ProviderOnboardingValidators.validateIdentityNumber(
          'invalid',
          docType: 'nic',
        ),
        isNotNull,
      );
      expect(
        ProviderOnboardingValidators.validateIdentityNumber(
          '123456789V',
          docType: 'nic',
        ),
        isNull,
      );
      expect(
        ProviderOnboardingValidators.validateIdentityNumber(
          'N1234567',
          docType: 'passport',
        ),
        isNull,
      );
    });
  });

  group('ProviderIdentityService Registration HTTP & Error Tests', () {
    test('Calls exact PUT /personal, PUT /business, and POST /submit routes',
        () async {
      final calls = <String>[];
      final service = ProviderIdentityService(
        client: MockClient((req) async {
          calls.add('${req.method} ${req.url.path}');
          expect(req.headers['Authorization'], 'Bearer reg-tok-1');
          if (req.method == 'PUT' &&
              req.url.path.endsWith('/providers/registration/personal')) {
            return http.Response(
              jsonEncode(_draftJson(personalCompleted: true)),
              200,
            );
          }
          if (req.method == 'PUT' &&
              req.url.path.endsWith('/providers/registration/business')) {
            return http.Response(
              jsonEncode(
                _draftJson(personalCompleted: true, businessCompleted: true),
              ),
              200,
            );
          }
          if (req.method == 'POST' &&
              req.url.path.endsWith('/providers/registration/submit')) {
            return http.Response(
              jsonEncode({
                'submitted': true,
                'approval_status': 'pending',
                'next_action': 'await_admin_review',
                'message': 'Your application has been submitted for review.',
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      );

      final d1 = await service.savePersonalDetails(
        registrationAuthToken: 'reg-tok-1',
        payload: const PersonalDetailsPayload(
          fullName: 'Saman Kumara',
          phone: '0771234567',
          dateOfBirth: '1995-05-12',
          gender: 'Male',
          nationality: 'Sri Lankan',
          identityDocumentType: 'nic',
          nicNumber: '199512345678',
          permanentProvince: 'Central',
          permanentDistrict: 'Kandy',
          permanentCity: 'Peradeniya',
          permanentLandmark: 'Near Main Gate',
          permanentPostalCode: '20400',
        ),
      );
      expect(d1.personalCompleted, isTrue);

      final d2 = await service.saveBusinessDetails(
        registrationAuthToken: 'reg-tok-1',
        payload: const BusinessDetailsPayload(
          businessName: 'Kandy Tea Estate Stay',
          providerType: 'homestay',
          description: 'Scenic estate homestay in Kandy.',
          sameAsPermanent: true,
        ),
      );
      expect(d2.businessCompleted, isTrue);

      final sub = await service.submitRegistration('reg-tok-1');
      expect(sub.submitted, isTrue);
      expect(sub.approvalStatus, 'pending');
      expect(calls, [
        'PUT /api/v1/providers/registration/personal',
        'PUT /api/v1/providers/registration/business',
        'POST /api/v1/providers/registration/submit',
      ]);
    });

    test('Maps 400, 401, 403, 409, 422, 429, 500, SocketException, TimeoutException',
        () async {
      for (final status in [400, 401, 403, 409, 422, 429, 500]) {
        final service = ProviderIdentityService(
          client: MockClient(
            (_) async =>
                http.Response(jsonEncode({'detail': 'Err $status'}), status),
          ),
        );
        await expectLater(
          service.submitRegistration('tok'),
          throwsA(
            isA<ApiError>().having((e) => e.statusCode, 'statusCode', status),
          ),
        );
      }

      final netService = ProviderIdentityService(
        client: MockClient((_) => throw const SocketException('Refused')),
      );
      await expectLater(
        netService.submitRegistration('tok'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );

      final timeoutService = ProviderIdentityService(
        client: MockClient((_) => throw TimeoutException('Timed out')),
      );
      await expectLater(
        timeoutService.submitRegistration('tok'),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );
    });
  });

  group('ProviderOnboardingScreen Widget Tests', () {
    testWidgets(
        'Full E2E mock flow: OTP -> Personal -> Business -> Identity Upload -> Submit Confirmation on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool personalDone = false;
      bool businessDone = false;
      bool identityDone = false;

      final service = ProviderIdentityService(
        client: MockClient.streaming((req, bodyStream) async {
          final path = req.url.path;
          if (path.endsWith('/providers/otp/send')) {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'message': 'Code sent',
                    'email': 'realprovider@ceylongo.lk',
                  }),
                ),
              ),
              200,
            );
          }
          if (path.endsWith('/providers/otp/verify')) {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'verified': true,
                    'next_action': 'continue_registration',
                    'authorization_token': 'real-reg-token',
                    'expires_in': 1800,
                  }),
                ),
              ),
              200,
            );
          }
          if (path.endsWith('/providers/registration/personal')) {
            personalDone = true;
          } else if (path.endsWith('/providers/registration/business')) {
            businessDone = true;
          } else if (path.endsWith('/providers/registration/identity')) {
            identityDone = true;
          } else if (path.endsWith('/providers/registration/submit')) {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'submitted': true,
                    'approval_status': 'pending',
                    'next_action': 'await_admin_review',
                    'message':
                        'Your application has been submitted for review.',
                  }),
                ),
              ),
              200,
            );
          }

          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode(
                  _draftJson(
                    personalCompleted: personalDone,
                    businessCompleted: businessDone,
                    selfieUploaded: identityDone,
                    nicFrontUploaded: identityDone,
                    nicBackUploaded: identityDone,
                    identityCompleted: identityDone,
                  ),
                ),
              ),
            ),
            200,
          );
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            '/vendor/login': (_) => const VendorLoginScreen(),
          },
          home: ProviderOnboardingScreen(
            identityService: service,
            docPicker: _FakeDocPicker(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. OTP Verification
      await tester.enterText(
        find.byKey(const Key('onboarding_email_field')),
        'realprovider@ceylongo.lk',
      );
      await tester.tap(find.byKey(const Key('onboarding_send_otp_btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('onboarding_otp_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('onboarding_verify_otp_btn')));
      await tester.pumpAndSettle();

      // Progress Overview: Submit disabled initially
      expect(find.byKey(const Key('onboarding_progress_card')), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('onboarding_submit_btn')),
            )
            .onPressed,
        isNull,
      );

      // 2. Personal Details
      await tester.tap(find.byKey(const Key('onboarding_step_personal')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('personal_full_name_field')),
        'Saman Kumara',
      );
      await tester.enterText(
        find.byKey(const Key('personal_phone_field')),
        '0771234567',
      );
      await tester.enterText(
        find.byKey(const Key('personal_dob_field')),
        '1995-05-12',
      );
      await tester.enterText(
        find.byKey(const Key('personal_nic_field')),
        '199512345678',
      );
      await tester.enterText(
        find.byKey(const Key('personal_province_field')),
        'Central',
      );
      await tester.enterText(
        find.byKey(const Key('personal_district_field')),
        'Kandy',
      );
      await tester.enterText(
        find.byKey(const Key('personal_city_field')),
        'Peradeniya',
      );
      await tester.enterText(
        find.byKey(const Key('personal_landmark_field')),
        'Near Main Gate',
      );
      await tester.enterText(
        find.byKey(const Key('personal_postal_field')),
        '20400',
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      final pSave = find.byKey(const Key('personal_save_btn'));
      await tester.ensureVisible(pSave);
      await tester.pumpAndSettle();
      await tester.tap(pSave);
      await tester.pumpAndSettle();

      // 3. Business Details
      await tester.tap(find.byKey(const Key('onboarding_step_business')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('business_name_field')),
        'Kandy Tea Estate Stay',
      );
      await tester.tap(find.byKey(const Key('business_same_address_switch')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('business_description_field')),
        'Scenic estate homestay in Kandy.',
      );
      final bSave = find.byKey(const Key('business_save_btn'));
      await tester.ensureVisible(bSave);
      await tester.pumpAndSettle();
      await tester.tap(bSave);
      await tester.pumpAndSettle();

      // 4. Identity Upload (reuses auth token without repeating OTP!)
      final identityStep = find.byKey(const Key('onboarding_step_identity'));
      await tester.ensureVisible(identityStep);
      await tester.pumpAndSettle();
      await tester.tap(identityStep);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('identity_auth_verified_badge')),
        findsOneWidget,
      );

      for (final keyStr in [
        'identity_camera_selfie',
        'identity_gallery_nic_front',
        'identity_gallery_nic_back',
      ]) {
        final btn = find.byKey(Key(keyStr));
        await tester.ensureVisible(btn);
        await tester.pumpAndSettle();
        await tester.tap(btn);
        await tester.pumpAndSettle();
      }

      final uploadBtn = find.byKey(const Key('identity_upload_submit_btn'));
      await tester.ensureVisible(uploadBtn);
      await tester.pumpAndSettle();
      await tester.tap(uploadBtn);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      // 5. Final Submit now enabled
      final submitBtn = find.byKey(const Key('onboarding_submit_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(submitBtn).onPressed, isNotNull);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('onboarding_submitted_card')),
        findsOneWidget,
      );
      expect(
        find.text('Approval Status: PENDING (await_admin_review)'),
        findsOneWidget,
      );
      // Demo service was never mutated by real onboarding
      expect(
        VendorDemoService.instance.currentVendor.id,
        VendorDemoService.defaultDemoVendor.id,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Submit timeout shows Check Draft Status recovery button and prevents blind duplicate submit',
        (WidgetTester tester) async {
      final service = ProviderIdentityService(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/providers/registration/submit')) {
            throw TimeoutException('Timed out');
          }
          if (req.url.path.endsWith('/providers/registration/draft')) {
            return http.Response(
              jsonEncode(
                _draftJson(
                  personalCompleted: true,
                  businessCompleted: true,
                  selfieUploaded: true,
                  nicFrontUploaded: true,
                  nicBackUploaded: true,
                  identityCompleted: true,
                ),
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
          home: ProviderOnboardingScreen(
            identityService: service,
            initialAuthToken: 'reg-tok',
            initialDraft: ProviderDraftStatus.fromJson(
              _draftJson(
                personalCompleted: true,
                businessCompleted: true,
                selfieUploaded: true,
                nicFrontUploaded: true,
                nicBackUploaded: true,
                identityCompleted: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('onboarding_submit_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('onboarding_check_draft_btn')),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(submitBtn).onPressed, isNull);

      await tester.tap(find.byKey(const Key('onboarding_check_draft_btn')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('onboarding_check_draft_btn')),
        findsNothing,
      );
    });

    testWidgets(
        'VendorRegisterScreen navigates to Real Provider Onboarding cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            '/vendor/register/onboarding': (_) =>
                const ProviderOnboardingScreen(),
          },
          home: const VendorRegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final realBtn = find.byKey(const Key('vendor_reg_real_onboarding_btn'));
      await tester.ensureVisible(realBtn);
      await tester.pumpAndSettle();
      await tester.tap(realBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ProviderOnboardingScreen), findsOneWidget);
    });
  });
}

