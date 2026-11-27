import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/home/screens/home_screen.dart';
import 'package:ceylongo/features/home/widgets/home_ai_planner_banner.dart';
import 'package:ceylongo/features/home/widgets/home_bottom_navigation_bar.dart';
import 'package:ceylongo/features/home/widgets/home_category_filters.dart';
import 'package:ceylongo/features/home/widgets/home_category_showcase.dart';
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

  setUp(() {
    ArtisanDemoService.isDemoMode = true;
  });

  tearDown(() {
    ArtisanDemoService.isDemoMode = false;
  });

  Widget createHomeScreen({
    UserModel? user,
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: routes ??
          {
            '/artisan': (_) =>
                const Scaffold(body: Text('Artisan Discovery Screen')),
            '/ai-planner': (_) =>
                const Scaffold(body: Text('AI Planner Screen')),
            '/category/homestays': (_) =>
                const Scaffold(body: Text('Homestays Page')),
            '/category/eco': (_) => const Scaffold(body: Text('Eco Page')),
            '/category/activities': (_) =>
                const Scaffold(body: Text('Activities Page')),
            '/category/guides': (_) =>
                const Scaffold(body: Text('Guides Page')),
            '/category/rentals': (_) =>
                const Scaffold(body: Text('Rentals Page')),
            '/artisan/wishlist': (_) =>
                const Scaffold(body: Text('Wishlist Screen')),
            '/artisan/reservations': (_) =>
                const Scaffold(body: Text('Reservations Screen')),
            '/login': (_) => const Scaffold(body: Text('Login Screen')),
            '/community': (_) => const Scaffold(body: Text('Community Screen')),
            '/profile': (_) => const Scaffold(body: Text('Profile Screen')),
          },
      home: HomeScreen(initialUser: user ?? testUser),
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

  group('HomeScreen Approved White-Theme Layout Verification', () {
    testWidgets(
      'Renders all 6 approved sections and confirms removed sections are absent',
      (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await settleScreen(tester);

        // Section A: White Header (Dark navy CeylonGo, no subtitle)
        expect(find.byType(HomeHeader), findsOneWidget);
        expect(find.text('CeylonGo'), findsOneWidget);
        expect(find.text('Discover Local. Feel at Home.'), findsNothing);
        expect(find.byKey(const Key('home_notifications_btn')), findsOneWidget);
        expect(find.byKey(const Key('home_profile_btn')), findsOneWidget);

        // Section B: Search Bar ("Start your search")
        expect(find.byType(HomeSearchBar), findsOneWidget);
        expect(find.text('Start your search'), findsOneWidget);
        expect(find.text('Where do you want to go?'), findsNothing);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);

        // Section C: Single Category Filter Row (6 filters)
        expect(find.byType(HomeCategoryFilters), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(HomeCategoryFilters),
            matching: find.text('All'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(HomeCategoryFilters),
            matching: find.text('Homestays'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(HomeCategoryFilters),
            matching: find.text('Eco'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(HomeCategoryFilters),
            matching: find.text('Activities'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(HomeCategoryFilters),
            matching: find.text('Guides'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(HomeCategoryFilters),
            matching: find.text('Rentals'),
          ),
          findsOneWidget,
        );

        // Section D: Popular Destinations (Jaffna, Ella, Kandy)
        expect(find.byType(HomePopularDestinations), findsOneWidget);
        expect(find.text('Popular Destinations'), findsOneWidget);
        expect(find.text('Jaffna'), findsNWidgets(2)); // Destination + Card 1
        expect(find.text('Ella'), findsNWidgets(2)); // Destination + Card 2
        expect(find.text('Kandy'), findsOneWidget);

        // Section E: Featured Homestays (2 stacked cards, no duplicate Homestays section)
        expect(find.byType(HomeFeaturedHomestays), findsOneWidget);
        expect(find.text('Featured Homestays'), findsOneWidget);
        expect(find.text('Traditional Villa with garden'), findsOneWidget);
        expect(find.text('Ella Mountain Homestay'), findsOneWidget);
        expect(find.text('4.8 (128 reviews)'), findsOneWidget);
        expect(find.text('4.9 (256 reviews)'), findsOneWidget);
        expect(find.byKey(const Key('homestay_card_1')), findsOneWidget);
        expect(find.byKey(const Key('homestay_card_2')), findsOneWidget);

        // Unified "All" Category Showcase (Eco Tourism, Activities, Local Guides, Rentals)
        expect(find.byType(HomeCategoryShowcase), findsOneWidget);
        expect(find.text('Eco Tourism'), findsOneWidget);
        expect(find.text('Local Guides'), findsOneWidget);
        expect(find.byKey(const Key('see_all_eco')), findsOneWidget);
        expect(find.byKey(const Key('see_all_activities')), findsOneWidget);
        expect(find.byKey(const Key('see_all_guides')), findsOneWidget);
        expect(find.byKey(const Key('see_all_rentals')), findsOneWidget);

        // Section F: Fixed Bottom Navigation Bar
        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Explore'), findsOneWidget);
        expect(find.text('AI Planner'), findsOneWidget);
        expect(find.text('Community'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
        expect(find.byKey(const Key('bottom_nav_ai_planner')), findsOneWidget);

        // Removed Old Sections MUST be absent
        expect(find.byType(HomeModuleShortcuts), findsNothing);
        expect(find.byType(HomeAiPlannerBanner), findsNothing);
        expect(find.byType(HomeQuickActions), findsNothing);
        expect(find.text('Plan My Trip'), findsNothing);
        expect(find.text('My Bookings'), findsNothing);
        expect(find.text('Promotions'), findsNothing);
      },
    );

    testWidgets(
      'Header has pure white background and dark navy CeylonGo title',
      (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await settleScreen(tester);

        final headerFinder = find.byType(HomeHeader);
        expect(headerFinder, findsOneWidget);

        final container = tester.widget<Container>(
          find
              .descendant(of: headerFinder, matching: find.byType(Container))
              .first,
        );
        expect(container.color, Colors.white);

        final titleWidget = tester.widget<Text>(find.text('CeylonGo'));
        expect(titleWidget.style?.color, AppTheme.primaryNavy);
      },
    );

    testWidgets('Tapping category filter chip navigates to category page', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final ecoFilter = find.byKey(const Key('category_filter_eco'));
      expect(ecoFilter, findsOneWidget);

      await tapAndSettle(tester, ecoFilter);

      expect(find.text('Eco Page'), findsOneWidget);
    });

    testWidgets(
      'See All buttons in All view navigate to their category pages and preserve All on return',
      (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await settleScreen(tester);

        final cases = [
          ('see_all_eco', 'Eco Page'),
          ('see_all_activities', 'Activities Page'),
          ('see_all_guides', 'Guides Page'),
          ('see_all_rentals', 'Rentals Page'),
        ];

        for (final (keyName, expectedText) in cases) {
          final btn = find.byKey(Key(keyName));
          await tester.ensureVisible(btn);
          await tapAndSettle(tester, btn);
          expect(find.text(expectedText), findsOneWidget);

          Navigator.of(tester.element(find.text(expectedText))).pop();
          await tester.pumpAndSettle();
          expect(find.byType(HomeCategoryShowcase), findsOneWidget);
        }
      },
    );

    testWidgets(
      'Tapping Featured Homestay card does not open Artisan bottom sheet',
      (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await settleScreen(tester);

        final card1 = find.byKey(const Key('homestay_card_1'));
        expect(card1, findsOneWidget);

        await tester.ensureVisible(card1);
        await tapAndSettle(tester, card1);

        expect(find.text('Explore Traditional Artisans'), findsNothing);
        expect(find.text('Artisan Discovery Screen'), findsNothing);
        expect(find.text('Homestays Page'), findsOneWidget);
      },
    );

    testWidgets('Tapping Profile button opens Profile Screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final profileBtn = find.byKey(const Key('home_profile_btn'));
      expect(profileBtn, findsOneWidget);

      await tapAndSettle(tester, profileBtn);

      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('Tapping bottom navigation Profile tab navigates to /profile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final profileTab = find.byKey(const Key('bottom_nav_profile'));
      expect(profileTab, findsOneWidget);

      await tapAndSettle(tester, profileTab);

      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets(
      'Tapping bottom navigation Community tab navigates to /community',
      (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await settleScreen(tester);

        final communityTab = find.byKey(const Key('bottom_nav_community'));
        expect(communityTab, findsOneWidget);

        await tapAndSettle(tester, communityTab);

        expect(find.text('Community Screen'), findsOneWidget);
      },
    );

    testWidgets('Tapping Notification Bell opens notifications sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final notifBtn = find.byKey(const Key('home_notifications_btn'));
      expect(notifBtn, findsOneWidget);

      await tapAndSettle(tester, notifBtn);

      expect(find.text('Notifications (Demo)'), findsOneWidget);
      expect(find.text('Demo preview mode is active.'), findsOneWidget);
    });

    testWidgets('Bottom navigation Explore tab navigates to /artisan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createHomeScreen());
      await settleScreen(tester);

      final exploreTab = find.byKey(const Key('bottom_nav_explore'));
      expect(exploreTab, findsOneWidget);

      await tapAndSettle(tester, exploreTab);

      expect(find.text('Artisan Discovery Screen'), findsOneWidget);
    });

    testWidgets(
      'Bottom navigation AI Planner tab navigates to /ai-planner and not Explore',
      (WidgetTester tester) async {
        await tester.pumpWidget(createHomeScreen());
        await settleScreen(tester);

        final aiPlannerTab = find.byKey(const Key('bottom_nav_ai_planner'));
        expect(aiPlannerTab, findsOneWidget);

        await tapAndSettle(tester, aiPlannerTab);

        expect(find.text('AI Planner Screen'), findsOneWidget);
        expect(find.text('Artisan Discovery Screen'), findsNothing);
      },
    );
  });

  group('HomeScreen Responsiveness & Samsung Galaxy A22 Verification', () {
    testWidgets(
      'Fits Samsung Galaxy A22 (360x800) with zero RenderFlex overflows',
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
        expect(find.byType(HomeCategoryFilters), findsOneWidget);
        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
      },
    );

    testWidgets('Responsive across 320px to 1200px viewports without errors', (
      WidgetTester tester,
    ) async {
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
        expect(find.byType(HomeCategoryFilters), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group(
    'HomeScreen Fixed Header, Search Bar & Category Filters Verification',
    () {
      testWidgets(
        'Header, Search Bar, and Category Filters are fixed outside vertical SingleChildScrollView',
        (WidgetTester tester) async {
          await tester.pumpWidget(createHomeScreen());
          await settleScreen(tester);

          final bodyScrollFinder = find.descendant(
            of: find.byType(Expanded),
            matching: find.byType(SingleChildScrollView),
          );
          expect(bodyScrollFinder, findsOneWidget);

          // Verify Header, Search Bar, and Category Filters are NOT inside vertical body scroll
          expect(
            find.descendant(
              of: bodyScrollFinder,
              matching: find.byType(HomeHeader),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: bodyScrollFinder,
              matching: find.byType(HomeSearchBar),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: bodyScrollFinder,
              matching: find.byType(HomeCategoryFilters),
            ),
            findsNothing,
          );

          // Verify Popular Destinations and Featured Homestays ARE inside vertical body scroll
          expect(
            find.descendant(
              of: bodyScrollFinder,
              matching: find.byType(HomePopularDestinations),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: bodyScrollFinder,
              matching: find.byType(HomeFeaturedHomestays),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Vertical scrolling moves lower content while Header, Search Bar, Category Filters, and Bottom Nav stay fixed',
        (WidgetTester tester) async {
          await tester.pumpWidget(createHomeScreen());
          await settleScreen(tester);

          final bodyScrollFinder = find.descendant(
            of: find.byType(Expanded),
            matching: find.byType(SingleChildScrollView),
          );

          final headerPosBefore = tester.getTopLeft(find.byType(HomeHeader));
          final searchBarPosBefore = tester.getTopLeft(
            find.byType(HomeSearchBar),
          );
          final filtersPosBefore = tester.getTopLeft(
            find.byType(HomeCategoryFilters),
          );
          final bottomNavPosBefore = tester.getTopLeft(
            find.byType(HomeBottomNavigationBar),
          );
          final destinationsPosBefore = tester.getTopLeft(
            find.byType(HomePopularDestinations),
          );

          await tester.drag(bodyScrollFinder, const Offset(0, -150));
          await tester.pump();

          final headerPosAfter = tester.getTopLeft(find.byType(HomeHeader));
          final searchBarPosAfter = tester.getTopLeft(
            find.byType(HomeSearchBar),
          );
          final filtersPosAfter = tester.getTopLeft(
            find.byType(HomeCategoryFilters),
          );
          final bottomNavPosAfter = tester.getTopLeft(
            find.byType(HomeBottomNavigationBar),
          );
          final destinationsPosAfter = tester.getTopLeft(
            find.byType(HomePopularDestinations),
          );

          expect(headerPosAfter, equals(headerPosBefore));
          expect(searchBarPosAfter, equals(searchBarPosBefore));
          expect(filtersPosAfter, equals(filtersPosBefore));
          expect(bottomNavPosAfter, equals(bottomNavPosBefore));
          expect(destinationsPosAfter.dy, lessThan(destinationsPosBefore.dy));
        },
      );
    },
  );
}
