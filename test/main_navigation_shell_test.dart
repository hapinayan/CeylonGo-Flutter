import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/ai_planner/screens/ai_planner_screen.dart';
import 'package:ceylongo/features/artisan/screens/artisan_discovery_screen.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/community/screens/community_feed_screen.dart';
import 'package:ceylongo/features/home/screens/home_screen.dart';
import 'package:ceylongo/features/home/widgets/home_bottom_navigation_bar.dart';
import 'package:ceylongo/features/home/widgets/home_category_filters.dart';
import 'package:ceylongo/features/navigation/screens/main_navigation_shell.dart';
import 'package:ceylongo/features/profile/screens/profile_screen.dart';

void main() {
  const testUser = UserModel(
    id: 'usr-swipe-001',
    fullName: 'Kamal Perera',
    email: 'kamal@ceylongo.com',
    role: 'tourist',
  );

  setUp(() {
    ArtisanDemoService.isDemoMode = true;
    ArtisanDemoService.instance.resetToDefaults();
  });

  Widget createShellApp({int initialIndex = 0}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MainNavigationShell(
        initialIndex: initialIndex,
        initialUser: testUser,
        artisanService: ArtisanDemoService.instance,
      ),
    );
  }

  int activeIndex(WidgetTester tester) {
    final nav = tester.widget<HomeBottomNavigationBar>(
      find.byType(HomeBottomNavigationBar),
    );
    return nav.currentIndex;
  }

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.flingFrom(
      const Offset(300, 520),
      const Offset(-250, 0),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> swipeRight(WidgetTester tester) async {
    await tester.flingFrom(
      const Offset(60, 520),
      const Offset(250, 0),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('MainNavigationShell Instagram-Style Swipe Navigation Tests', () {
    testWidgets(
      'Renders exactly one fixed HomeBottomNavigationBar with no duplicates',
      (WidgetTester tester) async {
        await tester.pumpWidget(createShellApp());
        await tester.pump(const Duration(milliseconds: 750));

        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(activeIndex(tester), 0);
      },
    );

    testWidgets(
      'Swipes left through all 5 tabs and swipes right back without wrapping',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createShellApp());
        await tester.pump(const Duration(milliseconds: 750));

        // 0: Home
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(activeIndex(tester), 0);

        // Swipe Home -> Explore (1)
        await swipeLeft(tester);
        expect(find.byType(ArtisanDiscoveryScreen), findsOneWidget);
        expect(activeIndex(tester), 1);
        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);

        // Swipe Explore -> AI Planner (2)
        await swipeLeft(tester);
        expect(find.byType(AiPlannerScreen), findsOneWidget);
        expect(activeIndex(tester), 2);
        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);

        // Swipe AI Planner -> Community (3)
        await swipeLeft(tester);
        expect(find.byType(CommunityFeedScreen), findsOneWidget);
        expect(activeIndex(tester), 3);
        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);

        // Swipe Community -> Profile (4)
        await swipeLeft(tester);
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(activeIndex(tester), 4);
        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);

        // Swiping left on Profile (4) must NOT wrap around to Home (0)
        await swipeLeft(tester);
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(activeIndex(tester), 4);

        // Swipe right back: Profile -> Community -> AI Planner -> Explore -> Home
        await swipeRight(tester);
        expect(find.byType(CommunityFeedScreen), findsOneWidget);
        expect(activeIndex(tester), 3);

        await swipeRight(tester);
        expect(find.byType(AiPlannerScreen), findsOneWidget);
        expect(activeIndex(tester), 2);

        await swipeRight(tester);
        expect(find.byType(ArtisanDiscoveryScreen), findsOneWidget);
        expect(activeIndex(tester), 1);

        await swipeRight(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(activeIndex(tester), 0);

        // Swiping right on Home (0) must NOT wrap around to Profile (4)
        await swipeRight(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(activeIndex(tester), 0);
      },
    );

    testWidgets('Bottom navigation tap animates to corresponding screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createShellApp());
      await tester.pump(const Duration(milliseconds: 750));

      await tester.tap(find.byKey(const Key('bottom_nav_ai_planner')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AiPlannerScreen), findsOneWidget);
      expect(activeIndex(tester), 2);

      await tester.tap(find.byKey(const Key('bottom_nav_profile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(activeIndex(tester), 4);

      await tester.tap(find.byKey(const Key('bottom_nav_home')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeIndex(tester), 0);
    });

    testWidgets(
      'Horizontal category filter scroll on Home does not accidentally switch tabs',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createShellApp());
        await tester.pump(const Duration(milliseconds: 750));

        await tester.drag(
          find.byType(HomeCategoryFilters),
          const Offset(-120, 0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(activeIndex(tester), 0);
      },
    );

    testWidgets('Android Back from non-Home tab returns to Home tab (index 0)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createShellApp(initialIndex: 2));
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.byType(AiPlannerScreen), findsOneWidget);
      expect(activeIndex(tester), 2);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeIndex(tester), 0);
    });
  });
}

