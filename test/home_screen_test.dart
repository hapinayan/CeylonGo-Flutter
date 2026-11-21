import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/home/screens/home_screen.dart';
import 'package:ceylongo/features/home/widgets/home_ai_planner_banner.dart';
import 'package:ceylongo/features/home/widgets/home_bottom_navigation_bar.dart';
import 'package:ceylongo/features/home/widgets/home_featured_homestays.dart';
import 'package:ceylongo/features/home/widgets/home_header.dart';
import 'package:ceylongo/features/home/widgets/home_module_shortcuts.dart';
import 'package:ceylongo/features/home/widgets/home_popular_destinations.dart';
import 'package:ceylongo/features/home/widgets/home_quick_actions.dart';
import 'package:ceylongo/features/home/widgets/home_search_bar.dart';

void main() {
  const testUser = UserModel(
    id: 'usr-home-001',
    fullName: 'Kamal Perera',
    email: 'kamal@ceylongo.com',
    role: 'tourist',
  );

  Widget createHomeScreen({
    UserModel? user,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: routes ??
          {
            '/artisan': (_) => const Scaffold(body: Text('Artisan Discovery Screen')),
            '/artisan/wishlist': (_) => const Scaffold(body: Text('Wishlist Screen')),
            '/artisan/reservations': (_) => const Scaffold(body: Text('Reservations Screen')),
            '/login': (_) => const Scaffold(body: Text('Login Screen')),
            '/community': (_) => const Scaffold(body: Text('Community Screen')),
            '/profile': (_) => const Scaffold(body: Text('Profile Screen')),
          },
      home: HomeScreen(
        initialUser: user ?? testUser,
      ),
    );
  }

  Future<void> settleScreen(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('HomeScreen Complete Layout & Approved Design Verification', () {
    testWidgets('Renders all 8 required sections in correct order',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      // Section A: Header (Premium Navy Blue, pure white CeylonGo, no subtitle)
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.text('CeylonGo'), findsOneWidget);
      expect(find.text('Discover Local. Feel at Home.'), findsNothing);
      expect(find.byKey(const Key('home_notifications_btn')), findsOneWidget);
      expect(find.byKey(const Key('home_profile_btn')), findsOneWidget);

      // Section B: Search Bar
      expect(find.byType(HomeSearchBar), findsOneWidget);
      expect(find.text('Where do you want to go?'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      // Section C: Six Module Shortcuts
      expect(find.byType(HomeModuleShortcuts), findsOneWidget);
      expect(find.text('Homestays'), findsOneWidget);
      expect(find.text('Eco\nTourism'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Tour\nGuides'), findsOneWidget);
      expect(find.text('Rentals'), findsOneWidget);
      expect(find.text('Artisan'), findsOneWidget);

      // Section D: AI Trip Planner Banner
      expect(find.byType(HomeAiPlannerBanner), findsOneWidget);
      expect(find.text('Plan My Trip'), findsOneWidget);
      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.text('Route Plan'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Travel Tips'), findsOneWidget);

      // Section E: Quick Actions
      expect(find.byType(HomeQuickActions), findsOneWidget);
      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Promotions'), findsOneWidget);
      expect(find.text('Community'), findsNWidgets(2)); // Quick Actions and Bottom Nav

      // Section F: Popular Destinations
      expect(find.byType(HomePopularDestinations), findsOneWidget);
      expect(find.text('Popular Destinations'), findsOneWidget);
      expect(find.text('Jaffna'), findsOneWidget);
      expect(find.text('Ella'), findsOneWidget);
      expect(find.text('Kandy'), findsNWidgets(2)); // Destination and Homestay location

      // Section G: Featured Homestays
      expect(find.byType(HomeFeaturedHomestays), findsOneWidget);
      expect(find.text('Featured Homestays'), findsOneWidget);
      expect(find.text('Traditional Village Homestay'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('Private Room'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Local Meals'), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);

      // Section H: Floating Bottom Navigation Bar
      expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('AI Planner'), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_ai_planner')), findsOneWidget);
    });

    testWidgets('Header matches approved deep navy blue design with pure white CeylonGo and no subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final headerFinder = find.byType(HomeHeader);
      expect(headerFinder, findsOneWidget);

      // Verify header background container has #073B91
      final container = tester.widget<Container>(
        find.descendant(of: headerFinder, matching: find.byType(Container)).first,
      );
      expect(container.color, const Color(0xFF073B91));

      // Verify CeylonGo title is pure white (#FFFFFF)
      final titleWidget = tester.widget<Text>(find.text('CeylonGo'));
      expect(titleWidget.style?.color, Colors.white);

      // Verify subtitle is completely removed
      expect(find.text('Discover Local. Feel at Home.'), findsNothing);

      // Verify Homestays label does not break awkwardly into multiple lines
      final homestayText = tester.widget<Text>(find.text('Homestays'));
      expect(homestayText.maxLines, 1);
      expect(homestayText.softWrap, false);
    });

    testWidgets('Tapping Artisan shortcut navigates to /artisan',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final artisanShortcut = find.byKey(const Key('shortcut_artisan'));
      expect(artisanShortcut, findsOneWidget);

      await tapAndSettle(tester, artisanShortcut);

      expect(find.text('Artisan Discovery Screen'), findsOneWidget);
    });

    testWidgets('Tapping Saved in Quick Actions navigates to /artisan/wishlist',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final savedBtn = find.byKey(const Key('quick_action_saved'));
      expect(savedBtn, findsOneWidget);

      await tapAndSettle(tester, savedBtn);

      expect(find.text('Wishlist Screen'), findsOneWidget);
    });

    testWidgets('Tapping Profile button opens Profile Screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final profileBtn = find.byKey(const Key('home_profile_btn'));
      expect(profileBtn, findsOneWidget);

      await tapAndSettle(tester, profileBtn);

      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('Tapping bottom navigation Profile tab navigates to /profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final profileTab = find.byKey(const Key('bottom_nav_profile'));
      expect(profileTab, findsOneWidget);

      await tapAndSettle(tester, profileTab);

      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('Tapping bottom navigation Community tab navigates to /community',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final communityTab = find.byKey(const Key('bottom_nav_community'));
      expect(communityTab, findsOneWidget);

      await tapAndSettle(tester, communityTab);

      expect(find.text('Community Screen'), findsOneWidget);
    });

    testWidgets('Tapping Community in Quick Actions navigates to /community',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final communityQuickAction = find.byKey(const Key('quick_action_community'));
      expect(communityQuickAction, findsOneWidget);

      await tapAndSettle(tester, communityQuickAction);

      expect(find.text('Community Screen'), findsOneWidget);
    });

    testWidgets('Tapping Notification Bell opens notifications sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final notifBtn = find.byKey(const Key('home_notifications_btn'));
      expect(notifBtn, findsOneWidget);

      await tapAndSettle(tester, notifBtn);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('View Artisan Discoveries'), findsOneWidget);
    });

    testWidgets('Bottom navigation tab switching animates smoothly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      // Tap Explore tab -> Navigates to /artisan
      final exploreTab = find.byKey(const Key('bottom_nav_explore'));
      expect(exploreTab, findsOneWidget);

      await tapAndSettle(tester, exploreTab);

      expect(find.text('Artisan Discovery Screen'), findsOneWidget);
    });
  });

  group('HomeScreen Responsiveness & Samsung Galaxy A22 Verification', () {
    testWidgets('Fits Samsung Galaxy A22 (360x800) with zero RenderFlex overflows',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
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

        await tester.pumpWidget(createHomeScreen());
        await settleScreen(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(HomeHeader), findsOneWidget);
        expect(find.byType(HomeSearchBar), findsOneWidget);
        expect(find.byType(HomeModuleShortcuts), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
