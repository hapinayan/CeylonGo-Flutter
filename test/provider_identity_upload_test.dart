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
import 'package:ceylongo/features/vendor/screens/vendor_identity_upload_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_register_screen.dart';
import 'package:ceylongo/features/vendor/services/provider_identity_service.dart';
import 'package:ceylongo/features/vendor/services/vendor_identity_doc_picker.dart';

// Valid minimal 1x1 PNG (starts with PNG magic bytes 89 50 4E 47 0D 0A 1A 0A)
final Uint8List _validPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

// Valid minimal JPEG header bytes (FF D8 FF E0 ...)
final Uint8List _validJpegHeaderBytes = Uint8List.fromList([
  0xFF,
  0xD8,
  0xFF,
  0xE0,
  0x00,
  0x10,
  0x4A,
  0x46,
  0x49,
  0x46,
  0x00,
  0x01,
]);

// Valid minimal WEBP header bytes (RIFF....WEBP)
final Uint8List _validWebpHeaderBytes = Uint8List.fromList([
  0x52,
  0x49,
  0x46,
  0x46,
  0x24,
  0x00,
  0x00,
  0x00,
  0x57,
  0x45,
  0x42,
  0x50,
]);

class _FakeIdentityDocPicker implements VendorIdentityDocPicker {
  final Map<IdentityDocKind, IdentityDocumentFile> nextFiles = {};
  IdentityValidationException? nextError;

  @override
  Future<IdentityDocumentFile?> pickDocument({
    required IdentityDocKind kind,
    required IdentityPickSource source,
  }) async {
    if (nextError != null) {
      final err = nextError!;
      nextError = null;
      throw err;
    }
    return nextFiles[kind] ??
        IdentityDocumentFile(
          kind: kind,
          safeFilename: '${kind.fieldName}.png',
          mimeType: 'image/png',
          bytes: _validPngBytes,
        );
  }
}

void main() {
  group('IdentityDocumentValidator Unit Tests', () {
    test('Accepts valid JPEG, PNG, and WEBP magic-byte headers under 5 MB', () {
      expect(
        IdentityDocumentValidator.validate(
          kind: IdentityDocKind.selfie,
          bytes: _validJpegHeaderBytes,
          filename: 'selfie.jpg',
          mimeType: 'image/jpeg',
        ),
        'image/jpeg',
      );
      expect(
        IdentityDocumentValidator.validate(
          kind: IdentityDocKind.nicFront,
          bytes: _validPngBytes,
          filename: 'nic_front.png',
          mimeType: 'image/png',
        ),
        'image/png',
      );
      expect(
        IdentityDocumentValidator.validate(
          kind: IdentityDocKind.nicBack,
          bytes: _validWebpHeaderBytes,
          filename: 'nic_back.webp',
          mimeType: 'image/webp',
        ),
        'image/webp',
      );
    });

    test('Rejects empty, > 5 MB oversized, HEIC, and spoofed-extension files',
        () {
      expect(
        () => IdentityDocumentValidator.validate(
          kind: IdentityDocKind.selfie,
          bytes: Uint8List(0),
          filename: 'empty.jpg',
        ),
        throwsA(isA<IdentityValidationException>()),
      );

      final oversized = Uint8List(IdentityDocumentValidator.maxFileSizeBytes + 1)
        ..[0] = 0xFF
        ..[1] = 0xD8
        ..[2] = 0xFF;
      expect(
        () => IdentityDocumentValidator.validate(
          kind: IdentityDocKind.nicFront,
          bytes: oversized,
          filename: 'huge.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<IdentityValidationException>()),
      );

      expect(
        () => IdentityDocumentValidator.validate(
          kind: IdentityDocKind.nicBack,
          bytes: _validPngBytes,
          filename: 'photo.heic',
          mimeType: 'image/heic',
        ),
        throwsA(isA<IdentityValidationException>()),
      );

      // Spoofed .jpg extension containing PDF magic bytes (%PDF)
      final spoofedPdf = Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2D,
        0x31,
        0x2E,
        0x34,
        0x0A,
        0x00,
        0x00,
        0x00,
      ]);
      expect(
        () => IdentityDocumentValidator.validate(
          kind: IdentityDocKind.selfie,
          bytes: spoofedPdf,
          filename: 'fake.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<IdentityValidationException>()),
      );
    });
  });

  group('ProviderIdentityService Multipart & Error Handling Tests', () {
    test(
        'Sends exact multipart field names, Bearer auth header, and parses DraftResponse',
        () async {
      String? capturedAuthHeader;
      String? capturedBody;
      Uri? capturedUri;

      final service = ProviderIdentityService(
        client: MockClient.streaming((req, bodyStream) async {
          capturedUri = req.url;
          capturedAuthHeader = req.headers['Authorization'];
          final bytes = await bodyStream.toBytes();
          capturedBody = utf8.decode(bytes, allowMalformed: true);
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'email': 'provider@example.com',
                  'identity_document_type': 'nic',
                  'selfie_uploaded': true,
                  'nic_front_uploaded': true,
                  'nic_back_uploaded': false,
                  'identity_completed': false,
                  'current_step': 'identity',
                }),
              ),
            ),
            200,
          );
        }),
      );

      final result = await service.uploadIdentityDocuments(
        registrationAuthToken: 'reg-auth-token-xyz',
        selfie: IdentityDocumentFile(
          kind: IdentityDocKind.selfie,
          safeFilename: 'selfie.png',
          mimeType: 'image/png',
          bytes: _validPngBytes,
        ),
        nicFront: IdentityDocumentFile(
          kind: IdentityDocKind.nicFront,
          safeFilename: 'nic_front.png',
          mimeType: 'image/png',
          bytes: _validPngBytes,
        ),
      );

      expect(
        capturedUri?.path.endsWith('/api/v1/providers/registration/identity'),
        isTrue,
      );
      expect(capturedAuthHeader, 'Bearer reg-auth-token-xyz');
      expect(capturedBody, contains('name="selfie"'));
      expect(capturedBody, contains('name="nic_front"'));
      expect(capturedBody, isNot(contains('name="nic_back"')));
      expect(result.selfieUploaded, isTrue);
      expect(result.nicFrontUploaded, isTrue);
      expect(result.nicBackUploaded, isFalse);
      expect(result.identityCompleted, isFalse);
    });

    test('Maps 400, 401, 403, 413, 415, 422, 429, 500, SocketException, TimeoutException',
        () async {
      final doc = IdentityDocumentFile(
        kind: IdentityDocKind.selfie,
        safeFilename: 'selfie.png',
        mimeType: 'image/png',
        bytes: _validPngBytes,
      );

      for (final status in [400, 401, 403, 413, 415, 422, 429, 500]) {
        final service = ProviderIdentityService(
          client: MockClient.streaming((_, _) async {
            return http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode({'detail': 'Err $status'}))),
              status,
            );
          }),
        );
        await expectLater(
          service.uploadIdentityDocuments(
            registrationAuthToken: 'reg-token',
            selfie: doc,
          ),
          throwsA(
            isA<ApiError>().having((e) => e.statusCode, 'statusCode', status),
          ),
        );
      }

      final netService = ProviderIdentityService(
        client: MockClient.streaming(
          (_, _) => throw const SocketException('Connection refused'),
        ),
      );
      await expectLater(
        netService.uploadIdentityDocuments(
          registrationAuthToken: 'reg-token',
          selfie: doc,
        ),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );

      final timeoutService = ProviderIdentityService(
        client: MockClient.streaming(
          (_, _) => throw TimeoutException('Timed out'),
        ),
      );
      await expectLater(
        timeoutService.uploadIdentityDocuments(
          registrationAuthToken: 'reg-token',
          selfie: doc,
        ),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );
    });
  });

  group('VendorIdentityUploadScreen Widget Tests', () {
    testWidgets(
        'OTP -> Authorization -> Selfie/NIC Front/NIC Back preview, remove, partial/complete upload, and duplicate-tap guard on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakePicker = _FakeIdentityDocPicker();
      int uploadCallCount = 0;
      final uploadCompleter = Completer<void>();

      final service = ProviderIdentityService(
        client: MockClient.streaming((req, bodyStream) async {
          if (req.url.path.endsWith('/providers/otp/send')) {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'message': 'Code sent',
                    'email': 'newprovider@lk.com',
                  }),
                ),
              ),
              200,
            );
          }
          if (req.url.path.endsWith('/providers/otp/verify')) {
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'verified': true,
                    'next_action': 'continue_registration',
                    'authorization_token': 'verified-reg-token',
                    'expires_in': 1800,
                  }),
                ),
              ),
              200,
            );
          }
          if (req.url.path.endsWith('/providers/registration/identity')) {
            uploadCallCount += 1;
            await uploadCompleter.future;
            return http.StreamedResponse(
              Stream.value(
                utf8.encode(
                  jsonEncode({
                    'email': 'newprovider@lk.com',
                    'selfie_uploaded': true,
                    'nic_front_uploaded': true,
                    'nic_back_uploaded': true,
                    'identity_completed': true,
                    'current_step': 'review',
                  }),
                ),
              ),
              200,
            );
          }
          return http.StreamedResponse(Stream.value([]), 404);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VendorIdentityUploadScreen(
            identityService: service,
            docPicker: fakePicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Send & Verify OTP to get registration authorization
      await tester.enterText(
        find.byKey(const Key('identity_otp_email_field')),
        'newprovider@lk.com',
      );
      await tester.tap(find.byKey(const Key('identity_send_otp_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('identity_otp_code_field')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('identity_verify_otp_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('identity_auth_verified_badge')),
        findsOneWidget,
      );

      // Select Selfie (Camera), NIC Front (Gallery), NIC Back (Gallery)
      final selfieCam = find.byKey(const Key('identity_camera_selfie'));
      await tester.ensureVisible(selfieCam);
      await tester.pumpAndSettle();
      await tester.tap(selfieCam);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('identity_preview_selfie')), findsOneWidget);

      // Test Remove on Selfie, then re-select
      final removeSelfie = find.byKey(const Key('identity_remove_selfie'));
      await tester.ensureVisible(removeSelfie);
      await tester.pumpAndSettle();
      await tester.tap(removeSelfie);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('identity_preview_selfie')), findsNothing);
      await tester.ensureVisible(selfieCam);
      await tester.pumpAndSettle();
      await tester.tap(selfieCam);
      await tester.pumpAndSettle();

      final nicFrontGal = find.byKey(const Key('identity_gallery_nic_front'));
      await tester.ensureVisible(nicFrontGal);
      await tester.pumpAndSettle();
      await tester.tap(nicFrontGal);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('identity_preview_nic_front')),
        findsOneWidget,
      );

      final nicBackGal = find.byKey(const Key('identity_gallery_nic_back'));
      await tester.ensureVisible(nicBackGal);
      await tester.pumpAndSettle();
      await tester.tap(nicBackGal);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('identity_preview_nic_back')), findsOneWidget);

      // Tap Upload -> in-flight progress indicator & duplicate tap disabled
      final submitBtn = find.byKey(const Key('identity_upload_submit_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pump();

      expect(
        find.byKey(const Key('identity_upload_progress')),
        findsOneWidget,
      );
      expect(
        tester.widget<ElevatedButton>(submitBtn).onPressed,
        isNull,
      );

      // Complete upload
      uploadCompleter.complete();
      await tester.pumpAndSettle();

      expect(uploadCallCount, 1);
      expect(
        find.byKey(const Key('identity_server_status_card')),
        findsOneWidget,
      );
      expect(
        find.text('Identity Verification: Completed (Pending Admin Review)'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Demo Mode blocks real identity upload and makes no HTTP calls',
        (WidgetTester tester) async {
      final failIfCalledService = ProviderIdentityService(
        client: MockClient((req) async {
          fail('Demo Mode must never call real identity API: ${req.url}');
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: VendorIdentityUploadScreen(
            isDemoMode: true,
            identityService: failIfCalledService,
            docPicker: _FakeIdentityDocPicker(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('identity_demo_blocked_banner')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const Key('identity_upload_submit_btn')),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets(
        'VendorRegisterScreen preserves Demo Registration and links to Identity Verification',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          routes: {
            '/vendor/register/identity': (_) =>
                const VendorIdentityUploadScreen(initialAuthToken: 'tok'),
          },
          home: const VendorRegisterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final linkBtn = find.byKey(const Key('vendor_reg_identity_btn'));
      await tester.ensureVisible(linkBtn);
      await tester.pumpAndSettle();
      await tester.tap(linkBtn);
      await tester.pumpAndSettle();

      expect(find.byType(VendorIdentityUploadScreen), findsOneWidget);
    });
  });
}

