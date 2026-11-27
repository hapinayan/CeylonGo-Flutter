import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/constants/api_constants.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/community/models/community_api_models.dart';
import 'package:ceylongo/features/community/screens/community_feed_screen.dart';
import 'package:ceylongo/features/community/services/community_api_service.dart';
import 'package:ceylongo/features/community/services/community_demo_service.dart';
import 'package:ceylongo/features/community/services/community_photo_picker.dart';
import 'package:ceylongo/features/community/widgets/create_community_post_sheet.dart';

// Minimal valid 1x1 PNG bytes (magic header + IHDR + IDAT + IEND)
final Uint8List _validPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

final Uint8List _validJpegBytes = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
]);

final Uint8List _validWebpBytes = Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
]);

class _FakeCommunityPhotoPicker extends CommunityPhotoPicker {
  List<SelectedCommunityPhoto> nextBatch;
  SelectedCommunityPhoto? nextReplacement;

  _FakeCommunityPhotoPicker({
    this.nextBatch = const [],
    this.nextReplacement,
  });

  @override
  Future<({List<SelectedCommunityPhoto> accepted, List<String> warnings})>
      pickFromGallery({required int maxRemaining}) async {
    return (
      accepted: nextBatch.take(maxRemaining).toList(),
      warnings: const <String>[],
    );
  }

  @override
  Future<SelectedCommunityPhoto?> pickSingleReplacement() async =>
      nextReplacement;
}

Map<String, dynamic> _sampleApiPostJson({
  int id = 42,
  bool includeMedia = false,
  bool isPublished = true,
}) =>
    {
      'id': id,
      'author_id': 7,
      'author': {
        'id': 7,
        'full_name': 'Nimali Perera',
        'role': 'traveler',
        'is_verified_provider': false,
      },
      'content': 'Sunrise over Ella Rock!',
      'location_tag': 'Ella, Sri Lanka',
      'district': 'Badulla',
      'likes_count': 0,
      'comments_count': 0,
      'is_published': isPublished,
      'is_promotional': false,
      'is_featured': false,
      'is_liked': false,
      'is_saved': false,
      'media': includeMedia
          ? [
              {
                'id': 101,
                'post_id': id,
                'media_type': 'image',
                'media_url': '/api/v1/uploads/community/post_${id}_abc.png',
                'display_order': 0,
                'created_at': '2026-01-01T10:00:00',
              }
            ]
          : [],
      'hashtags': [
        {'id': 1, 'tag': 'ella', 'usage_count': 5, 'is_featured': false},
      ],
      'share_url': '/community/posts/$id',
      'created_at': '2026-01-01T10:00:00',
    };

void main() {
  setUp(() {
    CommunityDemoService().resetToDefaults();
  });

  group('CommunityMediaValidator & URL Resolution Tests', () {
    test('accepts valid JPEG, PNG, and WEBP signatures', () {
      final png = CommunityMediaValidator.validate(
        bytes: _validPngBytes,
        filename: 'ella.png',
        mimeType: 'image/png',
      );
      expect(png.mimeType, 'image/png');

      final jpg = CommunityMediaValidator.validate(
        bytes: _validJpegBytes,
        filename: 'galle.jpg',
        mimeType: 'image/jpeg',
      );
      expect(jpg.mimeType, 'image/jpeg');

      final webp = CommunityMediaValidator.validate(
        bytes: _validWebpBytes,
        filename: 'kandy.webp',
        mimeType: 'image/webp',
      );
      expect(webp.mimeType, 'image/webp');
    });

    test('rejects empty files, >5MB files, and spoofed extensions', () {
      expect(
        () => CommunityMediaValidator.validate(
          bytes: Uint8List(0),
          filename: 'empty.jpg',
        ),
        throwsA(isA<CommunityMediaValidationException>()),
      );

      final tooBig = Uint8List(CommunityMediaValidator.maxFileBytes + 1);
      tooBig[0] = 0xFF;
      tooBig[1] = 0xD8;
      tooBig[2] = 0xFF;
      expect(
        () => CommunityMediaValidator.validate(
          bytes: tooBig,
          filename: 'huge.jpg',
        ),
        throwsA(isA<CommunityMediaValidationException>()),
      );

      final spoofed = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
      expect(
        () => CommunityMediaValidator.validate(
          bytes: spoofed,
          filename: 'fake.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<CommunityMediaValidationException>()),
      );
    });

    test('resolves relative and absolute community media URLs safely', () {
      expect(
        resolveCommunityMediaUrl('/api/v1/uploads/community/post_42_abc.png'),
        '${ApiConstants.baseUrl}/api/v1/uploads/community/post_42_abc.png',
      );
      expect(
        resolveCommunityMediaUrl('https://cdn.example.com/photo.jpg'),
        'https://cdn.example.com/photo.jpg',
      );
    });
  });

  group('CommunityApiService Contract & Error Handling Tests', () {
    test('creates post with Bearer token and parses server-generated ID',
        () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_sampleApiPostJson(id: 42)), 201);
      });

      final service = CommunityApiService(client: client);
      final post = await service.createPost(
        authToken: 'real-traveler-jwt',
        content: 'Sunrise over Ella Rock!',
        locationTag: 'Ella, Sri Lanka',
        hashtags: ['#Ella', '#TravelSriLanka'],
      );

      expect(captured.url.toString(), ApiConstants.communityPostsEndpoint);
      expect(captured.headers['Authorization'], 'Bearer real-traveler-jwt');
      expect(post.id, 42);
      expect(post.isPublished, isTrue);
    });

    test('uploads media with multipart field "file" and display_order',
        () async {
      late http.BaseRequest captured;
      String? bodyText;
      final client = MockClient.streaming((request, bodyStream) async {
        captured = request;
        final bytes = await bodyStream.toBytes();
        bodyText = utf8.decode(bytes, allowMalformed: true);
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'id': 101,
                'post_id': 42,
                'media_type': 'image',
                'media_url': '/api/v1/uploads/community/post_42_abc.png',
                'display_order': 0,
                'created_at': '2026-01-01T10:00:00',
              }),
            ),
          ),
          201,
        );
      });

      final service = CommunityApiService(client: client);
      final media = await service.uploadPostMedia(
        authToken: 'real-traveler-jwt',
        postId: 42,
        displayOrder: 0,
        photo: SelectedCommunityPhoto(
          bytes: _validPngBytes,
          safeFilename: 'ella.png',
          mimeType: 'image/png',
        ),
      );

      expect(
        captured.url.toString(),
        ApiConstants.communityPostMediaEndpoint(42),
      );
      expect(captured.headers['Authorization'], 'Bearer real-traveler-jwt');
      expect(bodyText, contains('name="file"'));
      expect(bodyText, contains('name="display_order"'));
      expect(media.id, 101);
      expect(media.postId, 42);
      expect(
        media.resolvedUrl,
        '${ApiConstants.baseUrl}/api/v1/uploads/community/post_42_abc.png',
      );
    });

    test('rejects demo- token and handles 401, 403 suspended, timeout, and SocketException',
        () async {
      final service = CommunityApiService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      expect(
        () => service.createPost(authToken: 'demo-traveler', content: 'Hi'),
        throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 401)),
      );

      final suspendedService = CommunityApiService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Your community account is suspended.'}),
            403,
          ),
        ),
      );
      expect(
        () => suspendedService.createPost(
          authToken: 'real-jwt',
          content: 'Hi',
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'status', 403)
              .having((e) => e.message, 'msg', contains('suspended')),
        ),
      );

      final timeoutService = CommunityApiService(
        client: MockClient((_) async => throw TimeoutException('timeout')),
      );
      expect(
        () => timeoutService.getFeed(),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'TIMEOUT')),
      );

      final offlineService = CommunityApiService(
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      expect(
        () => offlineService.getFeed(),
        throwsA(isA<ApiError>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    });
  });

  group('CreateCommunityPostSheet & CommunityFeedScreen Widget Tests', () {
    testWidgets(
      'Real Mode: Gallery pick, preview, replace, remove, partial upload failure, and retry without duplicate post on 360x800',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var createPostCalls = 0;
        var uploadCalls = 0;
        var feedCalls = 0;
        var failFirstUpload = true;

        final client = MockClient((request) async {
          if (request.url.path.endsWith('/feed')) {
            feedCalls++;
            return http.Response(
              jsonEncode({
                'items': [
                  _sampleApiPostJson(id: 42, includeMedia: createPostCalls > 0),
                ],
                'total': 1,
                'page': 1,
                'page_size': 20,
                'total_pages': 1,
                'has_next': false,
                'has_previous': false,
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/posts') && request.method == 'POST') {
            createPostCalls++;
            return http.Response(jsonEncode(_sampleApiPostJson(id: 42)), 201);
          }
          if (request.url.path.endsWith('/posts/42/media') &&
              request.method == 'POST') {
            uploadCalls++;
            if (failFirstUpload) {
              failFirstUpload = false;
              return http.Response(
                jsonEncode({'detail': 'Temporary upload error'}),
                500,
              );
            }
            return http.Response(
              jsonEncode({
                'id': 101,
                'post_id': 42,
                'media_type': 'image',
                'media_url': '/api/v1/uploads/community/post_42_abc.png',
                'display_order': 0,
                'created_at': '2026-01-01T10:00:00',
              }),
              201,
            );
          }
          if (request.url.path.endsWith('/posts/42') && request.method == 'GET') {
            return http.Response(
              jsonEncode(_sampleApiPostJson(id: 42, includeMedia: true)),
              200,
            );
          }
          return http.Response('{}', 404);
        });

        final apiService = CommunityApiService(client: client);
        final picker = _FakeCommunityPhotoPicker(
          nextBatch: [
            SelectedCommunityPhoto(
              bytes: _validPngBytes,
              safeFilename: 'ella_1.png',
              mimeType: 'image/png',
            ),
            SelectedCommunityPhoto(
              bytes: _validPngBytes,
              safeFilename: 'ella_2.png',
              mimeType: 'image/png',
            ),
          ],
          nextReplacement: SelectedCommunityPhoto(
            bytes: _validPngBytes,
            safeFilename: 'ella_replaced.png',
            mimeType: 'image/png',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: CommunityFeedScreen(
              realAuthToken: 'real-traveler-jwt',
              apiService: apiService,
              photoPicker: picker,
              showBottomNav: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(feedCalls, 1);

        // Open create post sheet
        await tester.tap(find.byKey(const Key('community_create_post_btn')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('community_photo_empty_placeholder')),
          findsOneWidget,
        );

        // Pick 2 gallery photos
        await tester.tap(find.byKey(const Key('community_gallery_pick_btn')));
        await tester.pumpAndSettle();
        expect(find.text('2/10 photos'), findsOneWidget);

        // Preview first photo
        await tester.tap(find.byKey(const Key('community_photo_preview_0')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('community_photo_preview_dialog')),
          findsOneWidget,
        );
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Replace first photo & remove second photo
        await tester.tap(find.byKey(const Key('community_photo_replace_0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('community_photo_remove_1')));
        await tester.pumpAndSettle();
        expect(find.text('1/10 photos'), findsOneWidget);

        // Enter caption and publish -> Post succeeds, upload fails (partial success)
        await tester.enterText(
          find.byKey(const Key('create_post_caption_field')),
          'Sunrise over Ella Rock!',
        );
        await tester.pumpAndSettle();
        final publishBtn = find.byKey(const Key('create_post_publish_btn'));
        await tester.tap(publishBtn);
        await tester.pumpAndSettle();

        expect(createPostCalls, 1);
        expect(uploadCalls, 1);
        expect(
          find.byKey(const Key('community_partial_success_banner')),
          findsOneWidget,
        );

        // Retry failed upload -> MUST NOT create duplicate post!
        final retryBtn = find.byKey(const Key('community_retry_uploads_btn'));
        await tester.ensureVisible(retryBtn);
        await tester.pumpAndSettle();
        await tester.tap(retryBtn);
        await tester.pumpAndSettle();

        expect(createPostCalls, 1);
        expect(uploadCalls, 2);
        expect(feedCalls, greaterThanOrEqualTo(2));
        expect(find.byType(CreateCommunityPostSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Demo Mode isolation: never calls real API when unauthenticated',
        (tester) async {
      var realApiCalled = false;
      final apiService = CommunityApiService(
        client: MockClient((_) async {
          realApiCalled = true;
          return http.Response('{}', 200);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CommunityFeedScreen(
            apiService: apiService,
            showBottomNav: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('community_create_post_btn')));
      await tester.pumpAndSettle();

      // Demo mode shows preset photos, not gallery picker
      expect(find.byKey(const Key('preset_photo_0')), findsOneWidget);
      expect(find.byKey(const Key('community_gallery_pick_btn')), findsNothing);
      expect(realApiCalled, isFalse);
    });
  });
}
