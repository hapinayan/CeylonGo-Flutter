import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/models/auth_response.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/auth_landing_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/features/auth/widgets/auth_wave_decoration.dart';
import 'package:ceylongo/features/navigation/screens/main_navigation_shell.dart';
import 'package:ceylongo/features/vendor/models/vendor_models.dart';
import 'package:ceylongo/features/vendor/screens/vendor_about_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_availability_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_bookings_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_earnings_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_listings_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_login_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_more_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_notifications_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_profile_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_register_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_reviews_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_settings_screen.dart';
import 'package:ceylongo/features/vendor/screens/vendor_support_screen.dart';
import 'package:ceylongo/features/vendor/services/vendor_demo_service.dart';
import 'package:ceylongo/features/vendor/services/vendor_photo_picker.dart';
import 'package:ceylongo/features/vendor/widgets/vendor_bottom_nav_bar.dart';
import 'package:ceylongo/features/vendor/widgets/vendor_listing_image.dart';
import 'package:ceylongo/main.dart';

class _FakeVendorPhotoPicker implements VendorPhotoPicker {
  static final Uint8List _samplePng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  List<VendorListingPhoto> galleryQueue = [];
  VendorListingPhoto? cameraPhoto;
  VendorPhotoException? nextError;
  int _counter = 0;

  VendorListingPhoto makePhoto(String prefix) {
    _counter += 1;
    return VendorListingPhoto(
      id: '${prefix}_$_counter',
      path: '/local/mock/${prefix}_$_counter.jpg',
      bytes: _samplePng,
      isLocalFile: true,
    );
  }

  @override
  Future<List<VendorListingPhoto>> pickFromGallery({
    required int maxCount,
  }) async {
    if (nextError != null) {
      final err = nextError!;
      nextError = null;
      throw err;
    }
    if (galleryQueue.isNotEmpty) {
      return galleryQueue.take(maxCount).toList();
    }
    return [makePhoto('gallery')];
  }

  @override
  Future<VendorListingPhoto?> captureFromCamera() async {
    if (nextError != null) {
      final err = nextError!;
      nextError = null;
      throw err;
    }
    return cameraPhoto ?? makePhoto('camera');
  }
}

class _InMemorySecureStorage extends SecureStorageService {
  String? token;
  UserModel? user;
  Map<String, dynamic>? vendorDemoSession;

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<bool> hasToken() async => token != null && token!.isNotEmpty;

  @override
  Future<void> deleteToken() async {
    token = null;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    this.user = user;
  }

  @override
  Future<UserModel?> getUser() async => user;

  @override
  Future<void> saveVendorDemoSession(Map<String, dynamic> demoData) async {
    vendorDemoSession = {...demoData, 'is_demo_session': true};
  }

  @override
  Future<Map<String, dynamic>?> getVendorDemoSession() async {
    if (vendorDemoSession == null ||
        vendorDemoSession!['is_demo_session'] != true) {
      return null;
    }
    return vendorDemoSession;
  }

  @override
  Future<void> clearVendorDemoSession() async {
    vendorDemoSession = null;
  }

  @override
  Future<void> clear() async {
    token = null;
    user = null;
    vendorDemoSession = null;
  }
}

class _MockVendorAuthService extends AuthService {
  UserModel? meUser;
  ApiError? meError;
  LoginResponse? loginResponse;

  @override
  Future<UserModel> getMe(String accessToken) async {
    if (meError != null) {
      throw meError!;
    }
    if (meUser != null) {
      return meUser!;
    }
    throw const ApiError(
      statusCode: 401,
      code: 'UNAUTHORIZED',
      message: 'Invalid token',
    );
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    if (loginResponse != null) {
      return loginResponse!;
    }
    throw const ApiError(
      statusCode: 401,
      code: 'INVALID_CREDENTIALS',
      message: 'Invalid credentials',
    );
  }
}

void main() {
  setUp(() {
    VendorDemoService.instance.resetToDefaults();
  });

  Widget createVendorApp(
    Widget home, {
    SecureStorageService? storageService,
  }) {
    final storage = storageService ?? _InMemorySecureStorage();
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        '/vendor/login': (_) => VendorLoginScreen(storageService: storage),
        '/vendor/register': (_) =>
            VendorRegisterScreen(storageService: storage),
        '/vendor/dashboard': (_) => const VendorDashboardScreen(),
        '/vendor/listings': (_) => const VendorListingsScreen(),
        '/vendor/bookings': (_) => const VendorBookingsScreen(),
        '/vendor/more': (_) => VendorMoreScreen(storageService: storage),
        '/vendor/availability': (_) => const VendorAvailabilityScreen(),
        '/vendor/earnings': (_) => const VendorEarningsScreen(),
        '/vendor/reviews': (_) => const VendorReviewsScreen(),
        '/vendor/notifications': (_) => const VendorNotificationsScreen(),
        '/vendor/settings': (_) => VendorSettingsScreen(storageService: storage),
        '/vendor/support': (_) => const VendorSupportScreen(),
        '/vendor/about': (_) => const VendorAboutScreen(),
        '/vendor/profile': (_) => VendorProfileScreen(storageService: storage),
      },
      home: home,
    );
  }

  group('Vendor Registration & Login Tests', () {
    testWidgets(
      'Vendor Registration validates fields, supports categories, and opens Vendor Dashboard',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final storage = _InMemorySecureStorage();
        await tester.pumpWidget(
          createVendorApp(
            VendorRegisterScreen(storageService: storage),
            storageService: storage,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('vendor_reg_name_field')),
          'Kandy Eco Villas',
        );
        await tester.enterText(
          find.byKey(const Key('vendor_reg_email_field')),
          'host@kandyvillas.lk',
        );
        await tester.enterText(
          find.byKey(const Key('vendor_reg_phone_field')),
          '0771234567',
        );
        await tester.enterText(
          find.byKey(const Key('vendor_reg_location_field')),
          'Kandy',
        );
        await tester.enterText(
          find.byKey(const Key('vendor_reg_password_field')),
          'StrongPass1!',
        );
        await tester.enterText(
          find.byKey(const Key('vendor_reg_confirm_field')),
          'StrongPass1!',
        );

        final submitBtn = find.byKey(const Key('vendor_register_submit_btn'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.byType(VendorDashboardScreen), findsOneWidget);
        expect(find.text('Welcome, Kandy Eco Villas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Vendor Login supports password toggle, Register link, and Demo Vendor login',
      (WidgetTester tester) async {
        final storage = _InMemorySecureStorage();
        await tester.pumpWidget(
          createVendorApp(
            VendorLoginScreen(storageService: storage),
            storageService: storage,
          ),
        );
        await tester.pumpAndSettle();

        // Password obscured by default
        final editableBefore = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('vendor_login_password_field')),
            matching: find.byType(EditableText),
          ),
        );
        expect(editableBefore.obscureText, isTrue);

        await tester.tap(find.byKey(const Key('vendor_toggle_password_btn')));
        await tester.pump();

        final editableAfter = tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('vendor_login_password_field')),
            matching: find.byType(EditableText),
          ),
        );
        expect(editableAfter.obscureText, isFalse);

        // Demo Vendor Login -> Vendor Dashboard
        final demoBtn = find.byKey(const Key('vendor_demo_login_btn'));
        await tester.ensureVisible(demoBtn);
        await tester.tap(demoBtn);
        await tester.pumpAndSettle();

        expect(find.byType(VendorDashboardScreen), findsOneWidget);
        expect(find.text('Total Listings'), findsOneWidget);
        expect(find.text('Pending Bookings'), findsOneWidget);
      },
    );

    testWidgets(
      'Vendor Login bottom wave is full-width and flush with bottom on 360x800',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createVendorApp(const VendorLoginScreen()));
        await tester.pumpAndSettle();

        final waveFinder = find.byType(AuthWaveDecoration);
        expect(waveFinder, findsOneWidget);
        final waveRect = tester.getRect(waveFinder);
        expect(waveRect.left, 0.0);
        expect(waveRect.right, 360.0);
        expect(waveRect.bottom, greaterThanOrEqualTo(800.0));
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Vendor Dashboard, Listings & Bookings Tests', () {
    testWidgets(
      'Vendor Dashboard navigates to Listings, supports Add/Edit/Delete in demo state, and Back returns',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createVendorApp(const VendorDashboardScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vendor_nav_listings')));
        await tester.pumpAndSettle();
        expect(find.byType(VendorListingsScreen), findsOneWidget);

        // Add Listing
        await tester.tap(find.byKey(const Key('vendor_add_listing_fab')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('listing_form_title')),
          'Galle Sunset Kayak',
        );
        await tester.enterText(
          find.byKey(const Key('listing_form_location')),
          'Galle',
        );
        await tester.enterText(
          find.byKey(const Key('listing_form_price')),
          '4000',
        );
        await tester.enterText(
          find.byKey(const Key('listing_form_field_rooms')),
          '2',
        );
        await tester.enterText(
          find.byKey(const Key('listing_form_field_max_guests')),
          '4',
        );
        await tester.enterText(
          find.byKey(const Key('listing_form_field_amenities')),
          'Wi-Fi, Breakfast',
        );
        final descField = find.byKey(const Key('listing_form_description'));
        await tester.ensureVisible(descField);
        await tester.enterText(
          descField,
          'Evening lagoon kayak tour.',
        );
        final saveBtn = find.byKey(const Key('listing_form_save_btn'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(find.text('Galle Sunset Kayak'), findsOneWidget);

        // Delete existing listing vl_1 with confirmation
        await tester.drag(find.byType(ListView), const Offset(0, -160));
        await tester.pumpAndSettle();
        final deleteBtn = find.byKey(const Key('delete_listing_vl_1'));
        await tester.ensureVisible(deleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(deleteBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_delete_listing_btn')));
        await tester.pumpAndSettle();
        expect(find.text('Traditional Villa with garden'), findsNothing);

        // Back to Dashboard
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(VendorDashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Vendor Booking Management filters by status and updates simulated status',
      (WidgetTester tester) async {
        await tester.pumpWidget(createVendorApp(const VendorBookingsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Kamal Perera • 12 Dec – 14 Dec • 2 Nights • 2 Guests'),
            findsOneWidget);

        // Accept pending booking vb_101
        await tester.tap(find.byKey(const Key('accept_booking_vb_101')));
        await tester.pumpAndSettle();

        final updated = VendorDemoService.instance.bookings
            .firstWhere((b) => b.id == 'vb_101');
        expect(updated.status, VendorBookingStatus.accepted);

        // Filter Completed
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();
        expect(find.text('Honda Dio 110cc Scooter'), findsOneWidget);
      },
    );
  });

  group('Vendor App Startup & Session Routing Tests', () {
    testWidgets('Fresh app launch with no session opens Vendor Login',
        (WidgetTester tester) async {
      final storage = _InMemorySecureStorage();
      final authService = _MockVendorAuthService();

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsNothing);
      expect(find.byType(AuthLandingScreen), findsNothing);
    });

    testWidgets(
        'Valid verified Vendor session opens Vendor Dashboard without Demo Mode',
        (WidgetTester tester) async {
      final storage = _InMemorySecureStorage()
        ..token = 'valid-vendor-jwt';
      final authService = _MockVendorAuthService()
        ..meUser = const UserModel(
          id: 'vnd-900',
          fullName: 'Galle Fort Heritage Villa',
          email: 'owner@gallefort.lk',
          role: 'vendor',
        );

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorDashboardScreen), findsOneWidget);
      expect(find.text('Welcome, Galle Fort Heritage Villa'), findsOneWidget);
      expect(find.textContaining('(Demo Mode)'), findsNothing);
      expect(find.byType(MainNavigationShell), findsNothing);
    });

    testWidgets(
        'Traveler session never opens Traveler Home and fails safely to Vendor Login',
        (WidgetTester tester) async {
      final storage = _InMemorySecureStorage()
        ..token = 'valid-traveler-jwt';
      final authService = _MockVendorAuthService()
        ..meUser = const UserModel(
          id: 'usr-101',
          fullName: 'Traveler User',
          email: 'traveler@ceylongo.com',
          role: 'traveler',
        );

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsNothing);
      expect(find.byType(VendorDashboardScreen), findsNothing);
      expect(storage.token, isNull);
    });

    testWidgets(
        'Legacy demo- traveler token never opens Traveler Home and falls back to Vendor Login',
        (WidgetTester tester) async {
      final storage = _InMemorySecureStorage()
        ..token = 'demo-traveler-token'
        ..user = const UserModel(
          id: 'demo-1',
          fullName: 'Demo Traveler',
          email: 'demo@ceylongo.com',
          role: 'traveler',
        );
      final authService = _MockVendorAuthService();

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsNothing);
      expect(storage.token, isNull);
    });

    testWidgets(
        'Invalid or expired session (401) clears storage and opens Vendor Login',
        (WidgetTester tester) async {
      final storage = _InMemorySecureStorage()..token = 'expired-jwt';
      final authService = _MockVendorAuthService()
        ..meError = const ApiError(
          statusCode: 401,
          code: 'UNAUTHORIZED',
          message: 'Token expired',
        );

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(storage.token, isNull);
    });

    testWidgets(
        'Demo Vendor Login -> Vendor Dashboard -> App Restart restores Demo Mode -> Logout -> Vendor Login',
        (WidgetTester tester) async {
      final storage = _InMemorySecureStorage();
      final authService = _MockVendorAuthService();

      // 1. Fresh launch -> Vendor Login
      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VendorLoginScreen), findsOneWidget);

      // 2. Tap Demo Vendor Login -> Vendor Dashboard
      final demoBtn = find.byKey(const Key('vendor_demo_login_btn'));
      await tester.ensureVisible(demoBtn);
      await tester.tap(demoBtn);
      await tester.pumpAndSettle();

      expect(find.byType(VendorDashboardScreen), findsOneWidget);
      expect(find.textContaining('(Demo Mode)'), findsOneWidget);
      expect(storage.token, isNull);
      expect(storage.vendorDemoSession?['is_demo_session'], isTrue);

      // 3. Simulate app restart by mounting a fresh CeylonGoApp with same storage
      VendorDemoService.instance.signOutVendor();
      await tester.pumpWidget(Container());
      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorDashboardScreen), findsOneWidget);
      expect(find.textContaining('(Demo Mode)'), findsOneWidget);

      // 4. Open Vendor Profile and Log Out -> Vendor Login
      await tester.tap(find.byKey(const Key('vendor_dashboard_profile_icon')));
      await tester.pumpAndSettle();
      expect(find.byType(VendorProfileScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('vendor_logout_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(storage.vendorDemoSession, isNull);

      // 5. Simulate app restart after logout -> Vendor Login
      await tester.pumpWidget(Container());
      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
    });

    testWidgets(
        'Real Vendor Login rejects non-vendor role safely without saving token',
        (WidgetTester tester) async {
      final storage = _InMemorySecureStorage();
      final authService = _MockVendorAuthService()
        ..loginResponse = LoginResponse(
          accessToken: 'traveler-jwt-token',
          tokenType: 'bearer',
          expiresIn: 3600,
          user: const UserModel(
            id: 'usr-22',
            fullName: 'Regular Traveler',
            email: 'traveler@example.com',
            role: 'traveler',
          ),
        );

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storage),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('vendor_login_email_field')),
        'traveler@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('vendor_login_password_field')),
        'Password@123',
      );

      final signInBtn = find.byKey(const Key('vendor_login_submit_btn'));
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(find.byType(VendorDashboardScreen), findsNothing);
      expect(
        find.text(
          'This account does not have Vendor access. Please sign in with a Vendor account.',
        ),
        findsOneWidget,
      );
      expect(storage.token, isNull);
    });
  });

  group('Enhanced Vendor Add/Edit Listing, Photo Selection & Isolation Tests',
      () {
    testWidgets(
        'Supports Gallery, Camera, max 5 photos, cover selection, remove, validation, and Edit preservation on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakePicker = _FakeVendorPhotoPicker();
      await tester.pumpWidget(
        createVendorApp(VendorListingsScreen(photoPicker: fakePicker)),
      );
      await tester.pumpAndSettle();

      // Vendor isolation: unrelated vendor listing must NOT appear
      expect(find.text('Unrelated Vendor Coastal Bungalow'), findsNothing);
      expect(find.text('Traditional Villa with garden'), findsOneWidget);

      // Open Add Listing
      await tester.tap(find.byKey(const Key('vendor_add_listing_fab')));
      await tester.pumpAndSettle();

      // Placeholder shown when no photos selected
      expect(find.byKey(const Key('listing_photo_placeholder')), findsOneWidget);
      expect(find.text('0 / 5'), findsOneWidget);

      // Denied permission error handled safely without crashing
      fakePicker.nextError = const VendorPhotoException(
        'Camera permission was denied. Please allow camera access in device settings.',
      );
      final camBtn = find.byKey(const Key('capture_camera_photo_btn'));
      await tester.ensureVisible(camBtn);
      await tester.tap(camBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('listing_photo_error')), findsOneWidget);

      // Gallery picks 3 photos
      fakePicker.galleryQueue = [
        fakePicker.makePhoto('g1'),
        fakePicker.makePhoto('g2'),
        fakePicker.makePhoto('g3'),
      ];
      final galBtn = find.byKey(const Key('pick_gallery_photo_btn'));
      await tester.ensureVisible(galBtn);
      await tester.tap(galBtn);
      await tester.pumpAndSettle();

      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.byKey(const Key('listing_photo_placeholder')), findsNothing);
      expect(find.byKey(const Key('cover_badge_0')), findsOneWidget);

      // Camera adds 4th photo, Gallery adds 5th photo -> cap at 5
      fakePicker.galleryQueue = [];
      await tester.tap(camBtn);
      await tester.pumpAndSettle();
      await tester.tap(galBtn);
      await tester.pumpAndSettle();
      expect(find.text('5 / 5'), findsOneWidget);

      // Buttons disabled at 5 photos
      final galleryButtonWidget = tester.widget<OutlinedButton>(galBtn);
      final cameraButtonWidget = tester.widget<OutlinedButton>(camBtn);
      expect(galleryButtonWidget.onPressed, isNull);
      expect(cameraButtonWidget.onPressed, isNull);

      // Choose photo index 2 as Cover
      final setCover2 = find.byKey(const Key('set_cover_photo_2'));
      await tester.ensureVisible(setCover2);
      await tester.tap(setCover2);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cover_badge_2')), findsOneWidget);

      // Remove photo index 0 -> count becomes 4, previous index 2 shifts to index 1
      final remove0 = find.byKey(const Key('remove_photo_0'));
      await tester.ensureVisible(remove0);
      await tester.tap(remove0);
      await tester.pumpAndSettle();
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.byKey(const Key('cover_badge_1')), findsOneWidget);

      // Validation check: submitting empty form shows errors and stays on form
      final saveBtn = find.byKey(const Key('listing_form_save_btn'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(find.text('Property Name is required'), findsOneWidget);
      expect(find.text('Number of Rooms is required'), findsOneWidget);

      // Fill Homestay fields and save
      await tester.ensureVisible(find.byKey(const Key('listing_form_title')));
      await tester.enterText(
        find.byKey(const Key('listing_form_title')),
        'Sigiriya Lakefront Cottage',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_location')),
        'Sigiriya',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_price')),
        '15000',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_field_rooms')),
        '3',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_field_max_guests')),
        '6',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_field_amenities')),
        'Lake view, AC, Breakfast',
      );
      final descField = find.byKey(const Key('listing_form_description'));
      await tester.ensureVisible(descField);
      await tester.enterText(
        descField,
        'Peaceful cottage overlooking Sigiriya tank.',
      );

      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Back on My Listings: new listing visible with 4 photos
      expect(find.byType(VendorListingsScreen), findsOneWidget);
      expect(find.text('Sigiriya Lakefront Cottage'), findsOneWidget);
      expect(find.text('4 photos'), findsOneWidget);

      final saved = VendorDemoService.instance.listings
          .firstWhere((l) => l.title == 'Sigiriya Lakefront Cottage');
      expect(saved.photos.length, 4);
      expect(saved.coverPhotoIndex, 1);

      // Edit Listing preserves existing photos and category fields
      await tester.tap(find.byKey(Key('edit_listing_${saved.id}')));
      await tester.pumpAndSettle();
      expect(find.text('4 / 5'), findsOneWidget);
      expect(find.byKey(const Key('cover_badge_1')), findsOneWidget);
      expect(find.text('Lake view, AC, Breakfast'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('listing_form_save_btn')));
      await tester.tap(find.byKey(const Key('listing_form_save_btn')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Switching Vendor Category dynamically renders category-specific fields for all 6 categories',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createVendorApp(
          VendorListingFormScreen(photoPicker: _FakeVendorPhotoPicker()),
        ),
      );
      await tester.pumpAndSettle();

      // Default: Homestay Provider
      expect(find.text('Property Name'), findsOneWidget);
      expect(find.text('Number of Rooms'), findsOneWidget);
      expect(find.text('Maximum Guests'), findsOneWidget);
      expect(find.text('Amenities'), findsOneWidget);

      Future<void> selectCategory(VendorCategory cat) async {
        final dropdown = find.byKey(const Key('listing_form_category'));
        await tester.ensureVisible(dropdown);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text(cat.label).last);
        await tester.pumpAndSettle();
      }

      // Eco Tourism Provider
      await selectCategory(VendorCategory.ecoTourism);
      expect(find.text('Experience Name'), findsOneWidget);
      expect(find.text('Eco-friendly Features'), findsOneWidget);

      // Activity Provider
      await selectCategory(VendorCategory.activity);
      expect(find.text('Activity Name'), findsOneWidget);
      expect(find.text('Price per Person (LKR)'), findsOneWidget);
      expect(find.text('Maximum Participants'), findsOneWidget);

      // Local Guide
      await selectCategory(VendorCategory.localGuide);
      expect(find.text('Service Name'), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);
      expect(find.text('Experience'), findsOneWidget);

      // Rental Provider
      await selectCategory(VendorCategory.rental);
      expect(find.text('Vehicle Name'), findsOneWidget);
      expect(find.text('Vehicle Type'), findsOneWidget);
      expect(find.text('Price per Day (LKR)'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);

      // Artisan Provider
      await selectCategory(VendorCategory.artisan);
      expect(find.text('Product or Workshop Name'), findsOneWidget);
      expect(find.text('Product Type'), findsOneWidget);
      expect(
        find.text('Available Quantity or Workshop Capacity'),
        findsOneWidget,
      );
    });

    test('VendorPhotoPicker validates file extensions and max 10 MB size', () {
      expect(
        () => VendorPhotoPicker.validatePhoto(
          path: '/tmp/document.pdf',
          sizeBytes: 1024,
        ),
        throwsA(isA<VendorPhotoException>()),
      );
      expect(
        () => VendorPhotoPicker.validatePhoto(
          path: '/tmp/huge.jpg',
          sizeBytes: VendorPhotoPicker.maxFileSizeBytes + 1,
        ),
        throwsA(isA<VendorPhotoException>()),
      );
      expect(
        () => VendorPhotoPicker.validatePhoto(
          path: '/tmp/valid_photo.webp',
          sizeBytes: 500 * 1024,
        ),
        returnsNormally,
      );
    });

    test('Vendor data isolation scopes listings to active demo vendor', () {
      final service = VendorDemoService.instance;
      expect(
        service.listings.any((l) => l.ownerVendorId != service.currentVendor.id),
        isFalse,
      );

      service.registerVendorDemo(
        businessName: 'New Ella Host',
        email: 'ella@host.lk',
        phone: '0771112222',
        category: VendorCategory.ecoTourism,
        location: 'Ella',
      );
      expect(service.listings, isEmpty);
    });
  });

  group('Vendor Listing Bug-Fix & Complete Category Audit Tests', () {
    testWidgets(
        'My Listings shows only the 7 category filter buttons in order and filters cleanly on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createVendorApp(const VendorListingsScreen()));
      await tester.pumpAndSettle();

      // Active / Inactive filter buttons must be removed
      expect(find.byKey(const Key('status_filter_Active')), findsNothing);
      expect(find.byKey(const Key('status_filter_Inactive')), findsNothing);

      // Verify exact 7 filter buttons in order
      final expectedLabels = [
        'All',
        'Homestay',
        'Eco Tourism',
        'Activity',
        'Guide',
        'Rental',
        'Artisan',
      ];
      final chipTexts = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .map((chip) => (chip.label as Text).data)
          .toList();
      expect(chipTexts, expectedLabels);

      // All is selected by default and shows both active (vl_1, vl_2) and inactive (vl_3)
      final allChip = tester.widget<ChoiceChip>(
        find.byKey(const Key('category_filter_all')),
      );
      expect(allChip.selected, isTrue);
      expect(find.text('Traditional Villa with garden'), findsOneWidget);
      expect(find.text('Ella Rock Sunrise Hike'), findsOneWidget);
      expect(find.text('Honda Dio 110cc Scooter'), findsOneWidget);

      // Homestay
      await tester.tap(find.byKey(const Key('category_filter_homestay')));
      await tester.pumpAndSettle();
      expect(find.text('Traditional Villa with garden'), findsOneWidget);
      expect(find.text('Ella Rock Sunrise Hike'), findsNothing);
      expect(find.text('Honda Dio 110cc Scooter'), findsNothing);

      // Eco Tourism
      final ecoChip = find.byKey(const Key('category_filter_ecoTourism'));
      await tester.ensureVisible(ecoChip);
      await tester.pumpAndSettle();
      await tester.tap(ecoChip);
      await tester.pumpAndSettle();
      expect(find.text('No listings match your filter.'), findsOneWidget);

      // Activity
      final activityChip = find.byKey(const Key('category_filter_activity'));
      await tester.ensureVisible(activityChip);
      await tester.pumpAndSettle();
      await tester.tap(activityChip);
      await tester.pumpAndSettle();
      expect(find.text('Ella Rock Sunrise Hike'), findsOneWidget);

      // Guide
      final guideChip = find.byKey(const Key('category_filter_localGuide'));
      await tester.ensureVisible(guideChip);
      await tester.pumpAndSettle();
      await tester.tap(guideChip);
      await tester.pumpAndSettle();
      expect(find.text('No listings match your filter.'), findsOneWidget);

      // Rental
      final rentalChip = find.byKey(const Key('category_filter_rental'));
      await tester.ensureVisible(rentalChip);
      await tester.pumpAndSettle();
      await tester.tap(rentalChip);
      await tester.pumpAndSettle();
      expect(find.text('Honda Dio 110cc Scooter'), findsOneWidget);

      // Artisan
      final artisanChip = find.byKey(const Key('category_filter_artisan'));
      await tester.ensureVisible(artisanChip);
      await tester.pumpAndSettle();
      await tester.tap(artisanChip);
      await tester.pumpAndSettle();
      expect(find.text('No listings match your filter.'), findsOneWidget);

      // Back to All -> shows all 3 (both active and inactive)
      final allFinder = find.byKey(const Key('category_filter_all'));
      await tester.ensureVisible(allFinder);
      await tester.pumpAndSettle();
      await tester.tap(allFinder);
      await tester.pumpAndSettle();
      expect(find.text('Traditional Villa with garden'), findsOneWidget);
      expect(find.text('Ella Rock Sunrise Hike'), findsOneWidget);
      expect(find.text('Honda Dio 110cc Scooter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Rental Provider Add Listing preserves pre-entered fields, uploads photos, saves, filters, edits, and deletes on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakePicker = _FakeVendorPhotoPicker();
      await tester.pumpWidget(
        createVendorApp(VendorListingsScreen(photoPicker: fakePicker)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vendor_add_listing_fab')));
      await tester.pumpAndSettle();

      // Enter Location before switching category -> must be preserved
      await tester.enterText(
        find.byKey(const Key('listing_form_location')),
        'Ella',
      );

      // Switch to Rental Provider
      await tester.tap(find.byKey(const Key('listing_form_category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rental Provider').last);
      await tester.pumpAndSettle();

      expect(find.text('Ella'), findsOneWidget);
      expect(find.text('Vehicle Name'), findsOneWidget);
      expect(find.text('Price per Day (LKR)'), findsOneWidget);
      expect(find.text('Vehicle Type'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('listing_form_title')),
        'Bajaj RE Tuk-Tuk',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_price')),
        '5500',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_field_vehicle_type')),
        'Tuk-Tuk',
      );
      await tester.enterText(
        find.byKey(const Key('listing_form_field_availability')),
        'Daily 6 AM - 9 PM',
      );
      final desc = find.byKey(const Key('listing_form_description'));
      await tester.ensureVisible(desc);
      await tester.enterText(desc, 'Clean tuk-tuk for Ella sightseeing.');

      // Pick 2 gallery + 1 camera photo, set index 1 as cover
      fakePicker.galleryQueue = [
        fakePicker.makePhoto('r1'),
        fakePicker.makePhoto('r2'),
      ];
      final galBtn = find.byKey(const Key('pick_gallery_photo_btn'));
      await tester.ensureVisible(galBtn);
      await tester.pumpAndSettle();
      await tester.tap(galBtn);
      await tester.pumpAndSettle();

      fakePicker.galleryQueue = [];
      await tester.tap(find.byKey(const Key('capture_camera_photo_btn')));
      await tester.pumpAndSettle();
      expect(find.text('3 / 5'), findsOneWidget);

      final cover1 = find.byKey(const Key('set_cover_photo_1'));
      await tester.ensureVisible(cover1);
      await tester.pumpAndSettle();
      await tester.tap(cover1);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cover_badge_1')), findsOneWidget);

      final saveBtn = find.byKey(const Key('listing_form_save_btn'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify in My Listings under Rental
      expect(find.byType(VendorListingsScreen), findsOneWidget);
      final rentalChip = find.byKey(const Key('category_filter_rental'));
      await tester.ensureVisible(rentalChip);
      await tester.pumpAndSettle();
      await tester.tap(rentalChip);
      await tester.pumpAndSettle();
      expect(find.text('Bajaj RE Tuk-Tuk'), findsOneWidget);
      expect(find.text('3 photos'), findsOneWidget);

      // Edit preserves rental fields & 3 photos + cover index 1
      final saved = VendorDemoService.instance.listings
          .firstWhere((l) => l.title == 'Bajaj RE Tuk-Tuk');
      await tester.tap(find.byKey(Key('edit_listing_${saved.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Tuk-Tuk'), findsOneWidget);
      expect(find.text('Daily 6 AM - 9 PM'), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.byKey(const Key('cover_badge_1')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Delete the created rental listing
      await tester.tap(find.byKey(Key('delete_listing_${saved.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_listing_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Bajaj RE Tuk-Tuk'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Details sheet renders without overflow on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createVendorApp(const VendorListingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Details').first);
      await tester.pumpAndSettle();
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('VendorPhotoPicker accepts Android fileName/mimeType fallback', () {
      expect(
        () => VendorPhotoPicker.validatePhoto(
          path: 'content://media/external/images/media/42',
          fileName: 'IMG_0042.JPG',
          mimeType: 'image/jpeg',
          sizeBytes: 2048,
        ),
        returnsNormally,
      );
    });
  });

  group('Final White Vendor Dashboard & Bottom Navigation Tests', () {
    testWidgets(
        'Pure white Dashboard renders 4 stats, recent bookings directly below, no middle shortcuts/waves on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      VendorDemoService.instance.registerVendorDemo(
        businessName:
            'Lanka Heritage Stay & Boutique Eco Villas Kandy',
        email: 'owner@heritage.lk',
        phone: '0771234567',
        category: VendorCategory.homestay,
        location: 'Kandy',
      );

      await tester.pumpWidget(createVendorApp(const VendorDashboardScreen()));
      await tester.pumpAndSettle();

      // 1. Pure white background, no blue waves
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.white);
      expect(find.byType(AuthWaveDecoration), findsNothing);

      // 2. Dynamic business name & subtitle
      expect(
        find.text(
          'Welcome, Lanka Heritage Stay & Boutique Eco Villas Kandy',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Homestay Provider • Kandy (Demo Mode)'),
        findsOneWidget,
      );

      // 3. All 4 statistic cards
      expect(find.text('Total Listings'), findsOneWidget);
      expect(find.text('Active Listings'), findsOneWidget);
      expect(find.text('Total Booking Requests'), findsOneWidget);
      expect(find.text('Pending Bookings'), findsOneWidget);

      // 4. Old Quick Actions and middle shortcut buttons removed
      expect(find.text('Quick Actions'), findsNothing);
      expect(
        find.byKey(const Key('vendor_shortcut_profile')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('vendor_shortcut_listings')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('vendor_shortcut_bookings')),
        findsNothing,
      );

      // 5. Recent Booking Requests directly below statistics & View all
      final pendingRect = tester.getRect(find.text('Pending Bookings'));
      final recentRect = tester.getRect(find.text('Recent Booking Requests'));
      expect(recentRect.top, greaterThan(pendingRect.bottom));
      expect(find.text('Recent Booking Requests'), findsOneWidget);
      expect(find.byKey(const Key('vendor_view_all_bookings')), findsOneWidget);
      expect(find.byType(VendorListingImage), findsWidgets);

      // 6. Four-item Bottom Navigation (single instance, index 0)
      expect(find.byType(VendorBottomNavigationBar), findsOneWidget);
      final navBar = tester.widget<VendorBottomNavigationBar>(
        find.byType(VendorBottomNavigationBar),
      );
      expect(navBar.currentIndex, 0);
      expect(find.byKey(const Key('vendor_nav_home')), findsOneWidget);
      expect(find.byKey(const Key('vendor_nav_listings')), findsOneWidget);
      expect(find.byKey(const Key('vendor_nav_bookings')), findsOneWidget);
      expect(find.byKey(const Key('vendor_nav_more')), findsOneWidget);

      // 7. View all -> Bookings (tab 2 active, no duplicate nav)
      await tester.tap(find.byKey(const Key('vendor_view_all_bookings')));
      await tester.pumpAndSettle();
      expect(find.byType(VendorBookingsScreen), findsOneWidget);
      expect(find.byType(VendorBottomNavigationBar), findsOneWidget);
      expect(
        tester
            .widget<VendorBottomNavigationBar>(
              find.byType(VendorBottomNavigationBar),
            )
            .currentIndex,
        2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Bottom Navigation switches across Home, My Listings, Bookings, and More with Logout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = _InMemorySecureStorage();
      await tester.pumpWidget(
        createVendorApp(
          const VendorDashboardScreen(),
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();

      // Profile icon -> VendorProfileScreen -> Back
      await tester.tap(find.byKey(const Key('vendor_dashboard_profile_icon')));
      await tester.pumpAndSettle();
      expect(find.byType(VendorProfileScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(VendorDashboardScreen), findsOneWidget);

      // Bottom Nav -> My Listings (index 1)
      await tester.tap(find.byKey(const Key('vendor_nav_listings')));
      await tester.pumpAndSettle();
      expect(find.byType(VendorListingsScreen), findsOneWidget);
      expect(find.byType(VendorBottomNavigationBar), findsOneWidget);
      expect(
        tester
            .widget<VendorBottomNavigationBar>(
              find.byType(VendorBottomNavigationBar),
            )
            .currentIndex,
        1,
      );

      // Bottom Nav -> More (index 3)
      await tester.tap(find.byKey(const Key('vendor_nav_more')));
      await tester.pumpAndSettle();
      expect(find.byType(VendorMoreScreen), findsOneWidget);
      expect(find.byType(VendorBottomNavigationBar), findsOneWidget);
      expect(
        tester
            .widget<VendorBottomNavigationBar>(
              find.byType(VendorBottomNavigationBar),
            )
            .currentIndex,
        3,
      );
      expect(find.text('Vendor Profile'), findsOneWidget);
      expect(find.text('Availability Calendar'), findsOneWidget);
      expect(find.text('About CeylonGo'), findsOneWidget);

      // Logout from More -> VendorLoginScreen
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      final logoutBtn = find.byKey(const Key('vendor_more_logout_btn'));
      await tester.ensureVisible(logoutBtn);
      await tester.pumpAndSettle();
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();
      expect(find.byType(VendorLoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Vendor More Screen 7 Features Tests', () {
    testWidgets(
        'All 7 More entries navigate to their screens and Back returns cleanly on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createVendorApp(const VendorMoreScreen()));
      await tester.pumpAndSettle();

      final entries = <({Key key, Type screenType})>[
        (
          key: const Key('vendor_more_availability_tile'),
          screenType: VendorAvailabilityScreen,
        ),
        (
          key: const Key('vendor_more_earnings_tile'),
          screenType: VendorEarningsScreen,
        ),
        (
          key: const Key('vendor_more_reviews_tile'),
          screenType: VendorReviewsScreen,
        ),
        (
          key: const Key('vendor_more_notifications_tile'),
          screenType: VendorNotificationsScreen,
        ),
        (
          key: const Key('vendor_more_settings_tile'),
          screenType: VendorSettingsScreen,
        ),
        (
          key: const Key('vendor_more_support_tile'),
          screenType: VendorSupportScreen,
        ),
        (
          key: const Key('vendor_more_about_tile'),
          screenType: VendorAboutScreen,
        ),
      ];

      for (final entry in entries) {
        final tile = find.byKey(entry.key);
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(find.byType(entry.screenType), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(VendorMoreScreen), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Availability Calendar navigates months and isolates availability per listing on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createVendorApp(const VendorAvailabilityScreen()),
      );
      await tester.pumpAndSettle();

      // Navigate to next month and select day 15
      await tester.tap(find.byKey(const Key('calendar_next_month_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('calendar_day_15')));
      await tester.pumpAndSettle();

      // Mark Unavailable for first listing (vl_1)
      final unavailBtn = find.byKey(const Key('mark_date_unavailable_btn'));
      await tester.ensureVisible(unavailBtn);
      await tester.pumpAndSettle();
      await tester.tap(unavailBtn);
      await tester.pumpAndSettle();
      expect(find.text('Status: Unavailable'), findsOneWidget);

      // Switch to second listing (vl_2) -> day 15 remains Available
      await tester.ensureVisible(
        find.byKey(const Key('availability_listing_dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('availability_listing_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ella Rock Sunrise Hike').last);
      await tester.pumpAndSettle();
      expect(find.text('Status: Available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Earnings, Reviews, Notifications, Settings, Support, and About work cleanly on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Earnings & Payments
      await tester.pumpWidget(createVendorApp(const VendorEarningsScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('earnings_demo_banner')), findsOneWidget);
      expect(find.textContaining('LKR '), findsWidgets);
      await tester.tap(find.byKey(const Key('earnings_filter_Completed')));
      await tester.pumpAndSettle();
      expect(find.text('Honda Dio 110cc Scooter'), findsOneWidget);

      // 2. Reviews & Ratings
      await tester.pumpWidget(createVendorApp(const VendorReviewsScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reviews_avg_rating')), findsOneWidget);
      expect(find.text('Amaya Jayawardena'), findsOneWidget);
      final rating1Chip = find.byKey(const Key('reviews_filter_1'));
      await tester.ensureVisible(rating1Chip);
      await tester.pumpAndSettle();
      await tester.tap(rating1Chip);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reviews_empty_state')), findsOneWidget);

      // 3. Notifications
      await tester.pumpWidget(
        createVendorApp(const VendorNotificationsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mark_read_vn_1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('mark_all_notifications_read_btn')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notifications_filter_unread')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('notifications_empty_state')),
        findsOneWidget,
      );

      // 4. App Settings
      await tester.pumpWidget(createVendorApp(const VendorSettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_sinhala_coming_soon')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('not supported in this demo build'),
        findsOneWidget,
      );

      // 5. Help & Support
      await tester.pumpWidget(createVendorApp(const VendorSupportScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('support_faq_search')),
        'photos',
      );
      await tester.pumpAndSettle();
      expect(find.text('How to upload photos'), findsOneWidget);
      expect(find.text('How to register as a vendor'), findsNothing);
      await tester.tap(find.byKey(const Key('faq_tile_upload_photos')));
      await tester.pumpAndSettle();
      expect(find.textContaining('up to 5 local photos'), findsOneWidget);
      expect(find.text('Email: support@ceylongo.com'), findsOneWidget);

      // 6. About CeylonGo
      await tester.pumpWidget(createVendorApp(const VendorAboutScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Version 1.0.0 (Build 1)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('about_privacy_policy_tile')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('not linked in this demo build'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

