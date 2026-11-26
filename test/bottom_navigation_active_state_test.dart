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
import 'package:ceylongo/features/profile/screens/profile_screen.dart';

void main() {
  const testUser = UserModel(
    id: 'usr-nav-001',
    fullName: 'Kamal Perera',
    email: 'kamal@ceylongo.com',
    role: 'tourist',
  );

  setUp(() {
    ArtisanDemoService.isDemoMode = true;
    ArtisanDemoService.instance.resetToDefaults();
  });

  Widget createNavigationApp({String initialRoute = '/home'}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/home': (_) => const HomeScreen(initialUser: testUser),
        '/artisan': (_) =>
            ArtisanDiscoveryScreen(artisanService: ArtisanDemoService.instance),
        '/ai-planner': (_) => const AiPlannerScreen(),
        '/community': (_) => const CommunityFeedScreen(),
        '/profile': (_) => const ProfileScreen(initialUser: testUser),
      },
    );
  }

  int activeBottomNavIndex(WidgetTester tester) {
    final nav = tester.widget<HomeBottomNavigationBar>(
      find.byType(HomeBottomNavigationBar),
    );
    return nav.currentIndex;
  }

  Future<void> tapTab(WidgetTester tester, String keyName) async {
    await tester.tap(find.byKey(Key(keyName)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('Bottom Navigation Active State Synchronization', () {
    testWidgets('Home -> Explore -> Home keeps active tab synchronized', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createNavigationApp(initialRoute: '/home'));
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 0);

      await tapTab(tester, 'bottom_nav_explore');
      expect(find.byType(ArtisanDiscoveryScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 1);

      await tapTab(tester, 'bottom_nav_home');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 0);
    });

    testWidgets('Home -> AI Planner -> Home keeps active tab synchronized', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createNavigationApp(initialRoute: '/home'));
      await tester.pump(const Duration(milliseconds: 750));

      expect(activeBottomNavIndex(tester), 0);

      await tapTab(tester, 'bottom_nav_ai_planner');
      expect(find.byType(AiPlannerScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 2);

      await tapTab(tester, 'bottom_nav_home');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 0);
    });

    testWidgets('Explore -> Community -> Profile keeps active tab synchronized',
        (WidgetTester tester) async {
      await tester.pumpWidget(createNavigationApp(initialRoute: '/artisan'));
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.byType(ArtisanDiscoveryScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 1);

      await tapTab(tester, 'bottom_nav_community');
      expect(find.byType(CommunityFeedScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 3);

      await tapTab(tester, 'bottom_nav_profile');
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 4);
    });

    testWidgets(
        'Profile -> AI Planner -> Explore keeps active tab synchronized', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createNavigationApp(initialRoute: '/profile'));
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 4);

      await tapTab(tester, 'bottom_nav_ai_planner');
      expect(find.byType(AiPlannerScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 2);

      await tapTab(tester, 'bottom_nav_explore');
      expect(find.byType(ArtisanDiscoveryScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 1);
    });

    testWidgets('Android Back navigation from Explore returns to Home active tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(createNavigationApp(initialRoute: '/home'));
      await tester.pump(const Duration(milliseconds: 750));

      expect(activeBottomNavIndex(tester), 0);

      await tapTab(tester, 'bottom_nav_explore');
      expect(find.byType(ArtisanDiscoveryScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 1);

      // Simulate Android system back button
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(activeBottomNavIndex(tester), 0);
    });
  });
}

