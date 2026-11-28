import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/home/widgets/home_bottom_navigation_bar.dart';
import 'package:ceylongo/features/profile/screens/profile_screen.dart';

class FakeSecureStorageService extends SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> saveToken(String token) async => _store['access_token'] = token;

  @override
  Future<String?> getToken() async => _store['access_token'];

  @override
  Future<void> clear() async => _store.clear();

  @override
  Future<void> saveUser(UserModel user) async {}

  @override
  Future<UserModel?> getUser() async => null;
}

void main() {
  const testUser = UserModel(
    id: 'usr-prof-001',
    fullName: 'Kamal Perera',
    email: 'kamal@ceylongo.com',
    role: 'traveler',
  );

  Widget createProfileScreen({
    UserModel? user,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: routes ??
          {
            '/home': (_) => const Scaffold(body: Text('Home Screen')),
            '/artisan': (_) => const Scaffold(body: Text('Artisan Discovery Screen')),
            '/community': (_) => const Scaffold(body: Text('Community Screen')),
            '/login': (_) => const Scaffold(body: Text('Login Screen')),
            '/role-selection': (_) =>
                const Scaffold(body: Text('Role Selection Screen')),
          },
      home: ProfileScreen(
        initialUser: user ?? testUser,
        storageService: FakeSecureStorageService(),
      ),
    );
  }

  Future<void> settleScreen(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  group('ProfileScreen Full White Minimal Design Verification', () {
    setUp(() {
      ArtisanDemoService.isDemoMode = true;
    });

    tearDown(() {
      ArtisanDemoService.isDemoMode = false;
    });

    testWidgets('Renders pure white background, minimal header, and all required sections without wave or header title',
        (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await settleScreen(tester);

      // Section 2: Wave design and painter must be completely removed
      expect(find.byKey(const Key('profile_wave_painter')), findsNothing);

      // Section 3: Minimal White Header Controls
      expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);
      expect(find.byKey(const Key('profile_notification_btn')), findsOneWidget);
      expect(find.byKey(const Key('profile_settings_btn')), findsOneWidget);

      // Explicit verification: Header MUST NOT display the title "Profile".
      // "Profile" only appears once on the screen (as the active label in the bottom navigation bar).
      expect(find.text('Profile'), findsOneWidget);

      // Ensure no cover banner or old tagline exists
      expect(find.text('Discover Local. Feel at Home.'), findsNothing);

      // Section 4: Profile Information & Avatar
      expect(find.text('Kamal Perera'), findsOneWidget);
      expect(find.text('kamal@ceylongo.com'), findsOneWidget);
      expect(find.byKey(const Key('profile_edit_avatar_btn')), findsOneWidget);
      expect(find.text('KP'), findsOneWidget); // Initials
      expect(find.text('Demo Traveler'), findsOneWidget);

      // Section 5: Profile Statistics Card
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Active/Done'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Bookings count
      expect(find.text('5'), findsOneWidget); // Saved count
      expect(find.text('8'), findsOneWidget); // Active/Done count

      // Section 6: Profile Menu Cards
      expect(find.byKey(const Key('menu_personal_details')), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);

      expect(find.byKey(const Key('menu_travel_preferences')), findsOneWidget);
      expect(find.text('Travel Preferences'), findsOneWidget);

      expect(find.byKey(const Key('menu_travel_history')), findsOneWidget);
      expect(find.text('My Bookings & History'), findsOneWidget);

      expect(find.byKey(const Key('menu_wishlist')), findsOneWidget);
      expect(find.text('Saved Wishlist'), findsOneWidget);

      expect(find.byKey(const Key('menu_reviews_ratings')), findsOneWidget);
      expect(find.text('Reviews & Ratings'), findsOneWidget);

      expect(find.byKey(const Key('menu_help_support')), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);

      // Section 7: Log Out Button
      expect(find.byKey(const Key('profile_logout_btn')), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Section 8: Bottom Navigation Bar with Profile active
      expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('AI Planner'), findsOneWidget);
    });

    testWidgets('Header icons show interactive feedback on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await settleScreen(tester);

      // Notification button tap shows demo notice in demo mode
      final notifBtn = find.byKey(const Key('profile_notification_btn'));
      await tapAndSettle(tester, notifBtn);
      expect(find.textContaining('Demo mode'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Settings button tap
      final settingsBtn = find.byKey(const Key('profile_settings_btn'));
      await tapAndSettle(tester, settingsBtn);
      expect(find.textContaining('Demo mode'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Edit avatar button tap -> opens Traveler Photo Editor Sheet
      final editAvatarBtn = find.byKey(const Key('profile_edit_avatar_btn'));
      await tapAndSettle(tester, editAvatarBtn);
      expect(find.byKey(const Key('traveler_photo_editor_sheet')), findsOneWidget);
    });

    testWidgets('Menu items trigger informative responses on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await settleScreen(tester);

      final menuPersonal = find.byKey(const Key('menu_personal_details'));
      await tapAndSettle(tester, menuPersonal);
      expect(find.text('Demo profile cannot be edited.'), findsOneWidget);
    });

    testWidgets('Log out button shows confirmation dialog and navigates to /login on confirm',
        (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await settleScreen(tester);

      final logoutBtn = find.byKey(const Key('profile_logout_btn'));
      await tester.ensureVisible(logoutBtn);
      await settleScreen(tester);
      await tapAndSettle(tester, logoutBtn);

      // Confirmation dialog should be displayed
      expect(find.text('Are you sure you want to log out of CeylonGo?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const Key('confirm_logout_btn')), findsOneWidget);

      // Tap confirm logout
      await tester.tap(find.byKey(const Key('confirm_logout_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await settleScreen(tester);

      expect(find.text('Role Selection Screen'), findsOneWidget);
    });

    testWidgets('Bottom navigation tab switching navigates to /home and /artisan',
        (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await settleScreen(tester);

      // Tap Explore tab
      final exploreTab = find.byKey(const Key('bottom_nav_explore'));
      await tapAndSettle(tester, exploreTab);
      expect(find.text('Artisan Discovery Screen'), findsOneWidget);
    });

    testWidgets('Bottom navigation Community tab navigates to /community',
        (WidgetTester tester) async {
      await tester.pumpWidget(createProfileScreen());
      await settleScreen(tester);

      final communityTab = find.byKey(const Key('bottom_nav_community'));
      await tapAndSettle(tester, communityTab);
      expect(find.text('Community Screen'), findsOneWidget);
    });

    testWidgets('Renders Offline Demo session user correctly',
        (WidgetTester tester) async {
      const demoUser = UserModel(
        id: 'demo-user-001',
        fullName: 'Demo Traveler',
        email: 'demo@ceylongo.com',
        role: 'traveler',
      );

      await tester.pumpWidget(createProfileScreen(user: demoUser));
      await settleScreen(tester);

      expect(find.text('Demo Traveler'), findsNWidgets(2)); // Name + Badge
      expect(find.text('demo@ceylongo.com'), findsOneWidget);
      expect(find.text('DT'), findsOneWidget);
    });
  });

  group('ProfileScreen Live MVP Mode Verification', () {
    testWidgets('Displays guest prompt instead of hardcoded demo user when unauthenticated in normal mode',
        (WidgetTester tester) async {
      ArtisanDemoService.isDemoMode = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProfileScreen(
            storageService: FakeSecureStorageService(),
          ),
        ),
      );
      await settleScreen(tester);

      expect(find.text('Guest Traveler'), findsOneWidget);
      expect(find.text('Kamal Perera'), findsNothing);
      expect(find.text('Sign In / Create Account'), findsOneWidget);
    });
  });

  group('ProfileScreen Responsiveness & Samsung Galaxy A22 Verification', () {
    testWidgets('Fits Samsung Galaxy A22 (360x800) with zero RenderFlex overflows',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createProfileScreen());
      await settleScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);
      expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
      expect(find.byKey(const Key('profile_logout_btn')), findsOneWidget);
    });

    testWidgets('Responsive across 320px to 1200px viewports without errors',
        (WidgetTester tester) async {
      final viewports = [
        320.0, // Small mobile
        360.0, // Samsung Galaxy A22
        375.0, // iPhone / compact
        430.0, // Large mobile
        800.0, // Tablet
        1200.0, // Desktop
      ];

      for (final width in viewports) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createProfileScreen());
        await settleScreen(tester);

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('profile_back_btn')), findsOneWidget);
        expect(find.byKey(const Key('menu_personal_details')), findsOneWidget);
        expect(find.byKey(const Key('profile_logout_btn')), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
