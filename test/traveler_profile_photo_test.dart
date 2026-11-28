import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/profile/models/traveler_profile_photo_models.dart';
import 'package:ceylongo/features/profile/screens/profile_screen.dart';
import 'package:ceylongo/features/profile/services/traveler_profile_photo_picker.dart';
import 'package:ceylongo/features/profile/services/traveler_profile_photo_storage.dart';

// Minimal valid 1x1 PNG
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

// Second distinct valid 1x1 PNG (different pixel color) for replacement checks
final Uint8List _secondPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
  0xB0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
]);

final Uint8List _validJpegHeader = Uint8List.fromList([
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
]);

final Uint8List _validWebpHeader = Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
]);

class _FakePhotoPicker extends TravelerProfilePhotoPicker {
  PickedTravelerPhoto? galleryResult;
  PickedTravelerPhoto? cameraResult;
  Exception? throwError;

  @override
  Future<PickedTravelerPhoto?> pickFromGallery() async {
    if (throwError != null) throw throwError!;
    return galleryResult;
  }

  @override
  Future<PickedTravelerPhoto?> captureFromCamera() async {
    if (throwError != null) throw throwError!;
    return cameraResult;
  }
}

class _FakeStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => null;

  @override
  Future<UserModel?> getUser() async => null;

  @override
  Future<void> clear() async {}
}

void main() {
  group('TravelerProfilePhotoValidator Unit Tests', () {
    test('accepts valid JPEG, PNG, and WEBP signatures', () {
      expect(
        TravelerProfilePhotoValidator.validate(
          bytes: _validPngBytes,
          filename: 'avatar.png',
          mimeType: 'image/png',
        ).mimeType,
        'image/png',
      );
      expect(
        TravelerProfilePhotoValidator.validate(
          bytes: _validJpegHeader,
          filename: 'avatar.jpg',
          mimeType: 'image/jpeg',
        ).mimeType,
        'image/jpeg',
      );
      expect(
        TravelerProfilePhotoValidator.validate(
          bytes: _validWebpHeader,
          filename: 'avatar.webp',
          mimeType: 'image/webp',
        ).mimeType,
        'image/webp',
      );
    });

    test('rejects empty, oversized, spoofed, and zero-dimension PNG files', () {
      expect(
        () => TravelerProfilePhotoValidator.validate(
          bytes: Uint8List(0),
          filename: 'empty.jpg',
        ),
        throwsA(isA<TravelerPhotoValidationException>()),
      );

      final big = Uint8List(TravelerProfilePhotoValidator.maxFileBytes + 1);
      big[0] = 0xFF;
      big[1] = 0xD8;
      big[2] = 0xFF;
      expect(
        () => TravelerProfilePhotoValidator.validate(
          bytes: big,
          filename: 'big.jpg',
        ),
        throwsA(isA<TravelerPhotoValidationException>()),
      );

      expect(
        () => TravelerProfilePhotoValidator.validate(
          bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
          filename: 'fake.jpg',
        ),
        throwsA(isA<TravelerPhotoValidationException>()),
      );

      // Corrupt PNG with 0x0 width/height in IHDR
      final zeroDimPng = Uint8List.fromList(_validPngBytes);
      zeroDimPng[19] = 0; // width = 0
      expect(
        () => TravelerProfilePhotoValidator.validate(
          bytes: zeroDimPng,
          filename: 'bad.png',
        ),
        throwsA(isA<TravelerPhotoValidationException>()),
      );
    });
  });

  group('FileTravelerProfilePhotoStore Persistence & Isolation Tests', () {
    test('persists across store recreation, replaces old file, isolates accounts, and handles missing files',
        () async {
      final tempDir = Directory.systemTemp.createTempSync('ceylongo_avatar_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final store1 = FileTravelerProfilePhotoStore(
        directoryProvider: () async => tempDir,
      );
      await store1.saveForAccount(
        accountKey: 'usr-A',
        bytes: _validPngBytes,
        extension: '.png',
        mimeType: 'image/png',
      );

      // Recreate store (simulates app restart)
      final store2 = FileTravelerProfilePhotoStore(
        directoryProvider: () async => tempDir,
      );
      final loadedA = await store2.loadForAccount('usr-A');
      expect(loadedA, isNotNull);
      expect(loadedA!.bytes, _validPngBytes);

      // Account B cannot see Account A's avatar
      expect(await store2.loadForAccount('usr-B'), isNull);

      // Replace Account A's avatar -> old file deleted, new bytes stored
      await store2.saveForAccount(
        accountKey: 'usr-A',
        bytes: _secondPngBytes,
        extension: '.png',
        mimeType: 'image/png',
      );
      final avatarDir = Directory('${tempDir.path}${Platform.pathSeparator}traveler_avatars');
      final pngFiles = avatarDir
          .listSync()
          .where((f) => f.path.endsWith('.png'))
          .toList();
      expect(pngFiles, hasLength(1));

      // Remove Account A's avatar -> file removed
      await store2.removeForAccount('usr-A');
      expect(await store2.loadForAccount('usr-A'), isNull);
    });
  });

  group('ProfileScreen Traveler Photo Upload Widget Tests', () {
    const userA = UserModel(
      id: 'usr-traveler-A',
      fullName: 'Kamal Perera',
      email: 'kamal@ceylongo.com',
      role: 'traveler',
    );
    const userB = UserModel(
      id: 'usr-traveler-B',
      fullName: 'Nimali Silva',
      email: 'nimali@ceylongo.com',
      role: 'traveler',
    );

    testWidgets(
      'Gallery select, preview, cancel without saving, save, camera replace, remove, and storage failure on 360x800',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final store = InMemoryTravelerProfilePhotoStore();
        final picker = _FakePhotoPicker();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: ProfileScreen(
              initialUser: userA,
              storageService: _FakeStorage(),
              photoStore: store,
              photoPicker: picker,
              showBottomNav: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Default initials avatar shown
        expect(find.text('KP'), findsOneWidget);
        expect(find.byKey(const Key('profile_avatar_image')), findsNothing);

        // Open editor sheet -> verify local-only notice
        await tester.tap(find.byKey(const Key('profile_edit_avatar_btn')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('traveler_photo_local_only_notice')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Profile photo saved on this device only. Cloud sync is not available yet.',
          ),
          findsOneWidget,
        );

        // Pick from gallery & preview, then cancel without saving
        picker.galleryResult = PickedTravelerPhoto(
          bytes: _validPngBytes,
          extension: '.png',
          mimeType: 'image/png',
        );
        await tester.tap(find.byKey(const Key('traveler_photo_gallery_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('traveler_photo_save_btn')), findsOneWidget);
        await tester.tap(find.byKey(const Key('traveler_photo_close_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile_avatar_image')), findsNothing);

        // Open again, pick from gallery, and save
        await tester.tap(find.byKey(const Key('profile_edit_avatar_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('traveler_photo_gallery_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('traveler_photo_save_btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);

        // Open again, replace via Camera, and update
        picker.cameraResult = PickedTravelerPhoto(
          bytes: _secondPngBytes,
          extension: '.png',
          mimeType: 'image/png',
        );
        await tester.tap(find.byKey(const Key('profile_edit_avatar_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('traveler_photo_camera_btn')));
        await tester.pumpAndSettle();
        expect(find.text('Update Photo'), findsOneWidget);

        // Simulate storage failure -> shows error banner without closing
        store.failOnSave = true;
        await tester.tap(find.byKey(const Key('traveler_photo_save_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('traveler_photo_error_banner')), findsOneWidget);
        store.failOnSave = false;

        // Retry save succeeds
        await tester.tap(find.byKey(const Key('traveler_photo_save_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile_avatar_image')), findsOneWidget);

        // Remove photo -> restores KP initials
        await tester.tap(find.byKey(const Key('profile_edit_avatar_btn')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('traveler_photo_remove_btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile_avatar_image')), findsNothing);
        expect(find.text('KP'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Account switching isolates Traveler avatars cleanly',
        (tester) async {
      final store = InMemoryTravelerProfilePhotoStore();
      await store.saveForAccount(
        accountKey: userA.id,
        bytes: _validPngBytes,
        extension: '.png',
        mimeType: 'image/png',
      );

      // User B should NOT see User A's saved photo
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(
            initialUser: userB,
            storageService: _FakeStorage(),
            photoStore: store,
            showBottomNav: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_avatar_image')), findsNothing);
      expect(find.text('NS'), findsOneWidget);
    });
  });
}

