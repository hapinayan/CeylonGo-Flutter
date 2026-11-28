import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/ai_planner/screens/ai_planner_screen.dart';
import 'package:ceylongo/features/ai_planner/widgets/ai_planner_header.dart';
import 'package:ceylongo/features/ai_planner/widgets/ai_travel_plan_card.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/home/widgets/home_bottom_navigation_bar.dart';

void main() {
  setUp(() {
    ArtisanDemoService.isDemoMode = true;
  });

  tearDown(() {
    ArtisanDemoService.isDemoMode = false;
  });
  Widget createApp({Map<String, WidgetBuilder>? routes}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: routes ??
          {
            '/home': (_) => const Scaffold(body: Text('Home Screen')),
            '/artisan': (_) => const Scaffold(body: Text('Artisan Screen')),
            '/community': (_) => const Scaffold(body: Text('Community Screen')),
            '/profile': (_) => const Scaffold(body: Text('Profile Screen')),
          },
      home: const AiPlannerScreen(),
    );
  }

  group('AiPlannerScreen Widget Tests', () {
    testWidgets(
      'Renders header, initial greeting, suggestion chips, sample chat, and 3-day plan card',
      (WidgetTester tester) async {
        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        expect(find.byType(AiPlannerHeader), findsOneWidget);
        expect(find.text('CeylonGo'), findsOneWidget);
        expect(find.text('Discover Local. Feel at Home.'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(AiPlannerHeader),
            matching: find.byType(Image),
          ),
          findsNothing,
        );
        expect(find.text('AI Travel Planner'), findsOneWidget);
        expect(find.text('AI Chatbot'), findsOneWidget);
        expect(
          find.text('Chat with our AI and plan your perfect Sri Lanka trip.'),
          findsOneWidget,
        );
        expect(find.text('Today'), findsOneWidget);

        // Initial greeting
        expect(
          find.textContaining('Hi! I’m CeylonGo AI Planner.'),
          findsOneWidget,
        );

        // Four quick suggestion chips
        expect(find.text('Plan a trip'), findsOneWidget);
        expect(find.text('Place ideas'), findsOneWidget);
        expect(find.text('Itinerary'), findsOneWidget);
        expect(find.text('Travel tips'), findsOneWidget);

        // Scroll to sample user message, then to 3-Day Travel Plan Card
        await tester.scrollUntilVisible(
          find.text('Plan a 3-day trip in Sri Lanka for culture and nature.'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.text('Plan a 3-day trip in Sri Lanka for culture and nature.'),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.byKey(const Key('ai_plan_customize_btn')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Sure! Here’s a 3-day travel plan for culture and nature in Sri Lanka:',
          ),
          findsOneWidget,
        );

        // 3-Day Travel Plan Card
        expect(find.byType(AiTravelPlanCard), findsOneWidget);
        expect(find.text('3-Day Sri Lanka Travel Plan'), findsOneWidget);
        expect(find.text('Culture & Nature'), findsOneWidget);
        expect(find.text('Day 1 – Sigiriya & Dambulla'), findsOneWidget);
        expect(find.text('Day 2 – Kandy'), findsOneWidget);
        expect(find.text('Day 3 – Nuwara Eliya'), findsOneWidget);

        // Plan action buttons
        expect(find.byKey(const Key('ai_plan_save_btn')), findsOneWidget);
        expect(find.byKey(const Key('ai_plan_share_btn')), findsOneWidget);
        expect(find.byKey(const Key('ai_plan_customize_btn')), findsOneWidget);

        // Composer & Bottom Nav
        expect(
          find.text('Ask anything about your Sri Lanka trip...'),
          findsOneWidget,
        );
        expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
      },
    );

    testWidgets(
      'Suggestion chip and send button append messages and ignore empty input',
      (WidgetTester tester) async {
        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        // Tapping send with empty text does nothing
        await tester.tap(find.byKey(const Key('ai_planner_send_btn')));
        await tester.pump();
        expect(find.text('Planning your trip...'), findsNothing);

        // Tap "Travel tips" suggestion chip
        await tester.tap(find.byKey(const Key('ai_chip_travel_tips')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Sri Lanka Travel Tips (Offline Demo)'),
          findsOneWidget,
        );

        // Type custom message and send
        await tester.enterText(
          find.byKey(const Key('ai_planner_input')),
          'Best beaches in south?',
        );
        await tester.tap(find.byKey(const Key('ai_planner_send_btn')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(find.text('Best beaches in south?'), findsOneWidget);
        expect(
          find.textContaining('Offline Demo Suggestion: For "Best beaches in south?"'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AI Planner tab is selected and other bottom nav destinations work',
      (WidgetTester tester) async {
        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();

        final bottomNav = tester.widget<HomeBottomNavigationBar>(
          find.byType(HomeBottomNavigationBar),
        );
        expect(bottomNav.currentIndex, 2);

        // Home -> /home
        await tester.tap(find.byKey(const Key('bottom_nav_home')));
        await tester.pumpAndSettle();
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );

    testWidgets('Bottom nav Explore tab navigates from AI Planner to /artisan',
        (WidgetTester tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_explore')));
      await tester.pumpAndSettle();
      expect(find.text('Artisan Screen'), findsOneWidget);
    });

    testWidgets(
      'Fits Samsung Galaxy A22 (360x800) and keyboard inset without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewInsets();
        });

        await tester.pumpWidget(createApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Simulate soft keyboard opening
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('ai_planner_input')), findsOneWidget);
      },
    );
  });
}

