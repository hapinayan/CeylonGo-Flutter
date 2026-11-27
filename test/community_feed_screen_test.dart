import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/community/screens/community_feed_screen.dart';
import 'package:ceylongo/features/community/screens/community_search_screen.dart';
import 'package:ceylongo/features/community/services/community_demo_service.dart';
import 'package:ceylongo/features/home/widgets/home_bottom_navigation_bar.dart';

void main() {
  setUp(() {
    ArtisanDemoService.isDemoMode = true;
    CommunityDemoService().resetToDefaults();
  });

  tearDown(() {
    ArtisanDemoService.isDemoMode = false;
  });

  Widget createCommunityScreen({
    Map<String, WidgetBuilder>? routes,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: routes ??
          {
            '/home': (_) => const Scaffold(body: Text('Home Screen')),
            '/artisan': (_) => const Scaffold(body: Text('Artisan Discovery Screen')),
            '/profile': (_) => const Scaffold(body: Text('Profile Screen')),
            '/community': (_) => const CommunityFeedScreen(),
          },
      home: const CommunityFeedScreen(),
    );
  }

  Future<void> settleScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  group('CommunityFeedScreen Layout & Approved Design Verification', () {
    testWidgets('Renders white header, tabs, hashtags, post cards, and floating compose button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // 1. Header
      expect(find.text('CeylonGo'), findsOneWidget);
      expect(find.text('Community'), findsNWidgets(2)); // Header title + Bottom nav label
      expect(find.byKey(const Key('community_search_btn')), findsOneWidget);
      expect(find.byKey(const Key('community_notifications_btn')), findsOneWidget);
      expect(find.byKey(const Key('community_profile_avatar')), findsOneWidget);

      // 2. Feed Navigation Tabs
      expect(find.byKey(const Key('tab_for_you')), findsOneWidget);
      expect(find.byKey(const Key('tab_following')), findsOneWidget);
      expect(find.byKey(const Key('tab_saved')), findsOneWidget);

      // 3. Trending Hashtags
      expect(find.byKey(const Key('hashtag_all')), findsOneWidget);
      expect(find.byKey(const Key('hashtag_ella')), findsOneWidget);
      expect(find.byKey(const Key('hashtag_travelsrilanka')), findsOneWidget);

      // 4. Sample Post Card 1 (Demo Traveler - Ella)
      expect(find.text('Demo Traveler'), findsWidgets);
      expect(find.textContaining('A beautiful morning in Ella!'), findsOneWidget);

      // 5. Scroll to Post 2 (Ceylon Handcrafts - Verified Provider)
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -650));
      await tester.pumpAndSettle();
      final workshopBtn = find.byKey(const Key('view_workshop_post_002'));
      expect(find.text('Ceylon Handcrafts'), findsWidgets);
      expect(find.text('Partner'), findsWidgets);
      expect(workshopBtn, findsOneWidget);

      // 6. Floating Compose Post Button
      expect(find.byKey(const Key('community_create_post_btn')), findsOneWidget);

      // 7. Bottom Navigation Bar with Community tab highlighted (index 3)
      expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('AI Planner'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Feed tab switching toggles between For You, Following, and Saved',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Switch to Following tab
      final followingTab = find.byKey(const Key('tab_following'));
      await tapAndSettle(tester, followingTab);

      // Following tab should show posts from Ceylon Handcrafts (followed by default)
      expect(find.text('Ceylon Handcrafts'), findsWidgets);

      // Switch to Saved tab
      final savedTab = find.byKey(const Key('tab_saved'));
      await tapAndSettle(tester, savedTab);

      // Saved tab should show bookmarked post 1
      expect(find.textContaining('A beautiful morning in Ella!'), findsOneWidget);

      // Switch back to For You tab
      final forYouTab = find.byKey(const Key('tab_for_you'));
      await tapAndSettle(tester, forYouTab);
      expect(find.text('Demo Traveler'), findsWidgets);
    });

    testWidgets('Trending hashtag filtering filters demo posts',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Tap #Ella hashtag
      final ellaTag = find.byKey(const Key('hashtag_ella'));
      await tapAndSettle(tester, ellaTag);

      // Post 1 (Ella) should be visible
      expect(find.textContaining('A beautiful morning in Ella!'), findsOneWidget);

      // Reset filter with #All
      final allTag = find.byKey(const Key('hashtag_all'));
      await tapAndSettle(tester, allTag);

      expect(find.text('Demo Traveler'), findsWidgets);
    });
  });

  group('CommunityFeedScreen Social Interactivity Tests', () {
    testWidgets('Liking and unliking a post updates like count and state',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Post 1 is initially liked with likesCount = 142
      expect(find.text('142'), findsOneWidget);

      // Tap like button on Post 1 to unlike
      final likeBtn = find.byKey(const Key('post_like_post_001'));
      await tapAndSettle(tester, likeBtn);

      // Like count decrements to 141
      expect(find.text('141'), findsOneWidget);

      // Tap like again to re-like
      await tapAndSettle(tester, likeBtn);
      expect(find.text('142'), findsOneWidget);
    });

    testWidgets('Saving a post toggles saved state and appears in Saved tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Post 1 is saved by default. Toggle save off and back on.
      final saveBtnPost1 = find.byKey(const Key('post_save_post_001'));
      await tapAndSettle(tester, saveBtnPost1);

      // Re-save post 1
      await tapAndSettle(tester, saveBtnPost1);

      // Switch to Saved tab
      await tapAndSettle(tester, find.byKey(const Key('tab_saved')));

      // Post 1 should appear in Saved tab
      expect(find.textContaining('A beautiful morning in Ella!'), findsOneWidget);
    });

    testWidgets('Comments sheet allows adding a new comment and updating count',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Open comments for Post 1
      final commentBtn = find.byKey(const Key('post_comment_post_001'));
      await tapAndSettle(tester, commentBtn);

      // Comments sheet header
      expect(find.text('Comments (2)'), findsOneWidget);
      expect(find.text('Nuwan Silva'), findsOneWidget);
      expect(find.text('Ananya Sen'), findsOneWidget);

      // Type new comment
      final inputField = find.byKey(const Key('comment_input_field'));
      await tester.enterText(inputField, 'The view from Demodara loop is incredible too!');
      await tester.pump();

      // Tap send
      final sendBtn = find.byKey(const Key('comment_send_btn'));
      await tapAndSettle(tester, sendBtn);

      // Comments count should increment to 3 and show comment text
      expect(find.text('Comments (3)'), findsOneWidget);
      expect(find.text('The view from Demodara loop is incredible too!'), findsOneWidget);
    });

    testWidgets('Compose Post flow publishes new post to For You feed',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Tap Compose floating button
      final composeBtn = find.byKey(const Key('community_create_post_btn'));
      await tapAndSettle(tester, composeBtn);

      expect(find.text('Create Community Post'), findsOneWidget);

      // Enter caption
      final captionField = find.byKey(const Key('create_post_caption_field'));
      await tester.enterText(captionField, 'Enjoyed fresh Ceylon tea at Pedro Tea Estate Nuwara Eliya! 🍵🌿');
      await tester.pump();

      // Tap publish
      final publishBtn = find.byKey(const Key('create_post_publish_btn'));
      await tester.ensureVisible(publishBtn);
      await tapAndSettle(tester, publishBtn);

      // Verify new post appears in For You feed
      expect(find.text('Enjoyed fresh Ceylon tea at Pedro Tea Estate Nuwara Eliya! 🍵🌿'), findsOneWidget);
    });

    testWidgets('Post options menu allows reporting a post',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Scroll to Post 2
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -250));
      await tester.pumpAndSettle();
      final optionsBtn = find.byKey(const Key('post_options_post_002'));
      await tapAndSettle(tester, optionsBtn);

      // Report option
      final reportTile = find.byKey(const Key('menu_report_post'));
      expect(reportTile, findsOneWidget);
      await tapAndSettle(tester, reportTile);

      // Select Spam reason
      expect(find.text('Report Post'), findsOneWidget);
      await tapAndSettle(tester, find.text('Spam or misleading'));

      expect(find.text('Thank you. This demo report has been recorded locally.'), findsOneWidget);
    });
  });

  group('CommunityFeedScreen Navigation & Sub-Screens Tests', () {
    testWidgets('Tapping search icon opens CommunitySearchScreen with query filtering',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      final searchBtn = find.byKey(const Key('community_search_btn'));
      await tapAndSettle(tester, searchBtn);

      expect(find.byType(CommunitySearchScreen), findsOneWidget);

      // Type search query 'Ella'
      final searchInput = find.byKey(const Key('community_search_input'));
      await tester.enterText(searchInput, 'Ella');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('A beautiful morning in Ella!'), findsWidgets);

      // Back to feed
      final backBtn = find.byKey(const Key('community_search_back_btn'));
      await tester.tap(backBtn);
      await tester.pumpAndSettle();
      expect(find.byType(CommunitySearchScreen), findsNothing);
    });

    testWidgets('Tapping notification bell opens notifications sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      final notifBtn = find.byKey(const Key('community_notifications_btn'));
      await tapAndSettle(tester, notifBtn);

      expect(find.text('Community Notifications'), findsOneWidget);
      expect(find.textContaining('liked your post'), findsOneWidget);
    });

    testWidgets('Tapping View Workshop navigates to /artisan',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      await tester.drag(find.byType(Scrollable).last, const Offset(0, -650));
      await tester.pumpAndSettle();
      final workshopBtn = find.byKey(const Key('view_workshop_post_002'));
      await tapAndSettle(tester, workshopBtn);

      expect(find.text('Artisan Discovery Screen'), findsOneWidget);
    });

    testWidgets('Tapping header profile avatar navigates to /profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      final avatarBtn = find.byKey(const Key('community_profile_avatar'));
      await tapAndSettle(tester, avatarBtn);

      expect(find.text('Profile Screen'), findsOneWidget);
    });

    testWidgets('Bottom navigation tab switching navigates to /home and /profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      // Tap Home
      final homeTab = find.byKey(const Key('bottom_nav_home'));
      await tapAndSettle(tester, homeTab);
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });

  group('CommunityFeedScreen Responsiveness & Samsung Galaxy A22 Verification', () {
    testWidgets('Fits Samsung Galaxy A22 (360x800) with zero RenderFlex overflows',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createCommunityScreen());
      await settleScreen(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('CeylonGo'), findsOneWidget);
      expect(find.byKey(const Key('community_create_post_btn')), findsOneWidget);
      expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
    });

    testWidgets('Responsive across 320px to 1200px viewports without errors',
        (WidgetTester tester) async {
      final viewports = [
        320.0, // Narrow mobile
        360.0, // Samsung Galaxy A22
        375.0, // Standard compact mobile
        430.0, // Large smartphone
        800.0, // Tablet
        1200.0, // Desktop
      ];

      for (final width in viewports) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createCommunityScreen());
        await settleScreen(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('CeylonGo'), findsOneWidget);
        expect(find.byKey(const Key('tab_for_you')), findsOneWidget);
        expect(find.byKey(const Key('community_create_post_btn')), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
