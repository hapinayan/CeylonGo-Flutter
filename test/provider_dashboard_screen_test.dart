import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/provider/models/provider_dashboard_data.dart';
import 'package:ceylongo/features/provider/screens/provider_dashboard_screen.dart';
import 'package:ceylongo/features/provider/screens/provider_placeholder_screen.dart';

void main() {
  Widget buildDashboard({
    ProviderDashboardData? data,
    bool isLoading = false,
    String? errorMessage,
    Future<void> Function()? onRefresh,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProviderDashboardScreen(
        data: data ?? ProviderDashboardData.fixture(),
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRefresh: onRefresh,
      ),
    );
  }

  group('ProviderDashboardScreen — Header & Welcome Tests', () {
    testWidgets('Renders bright blue header with white CeylonGo wordmark and 3 action icons', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // CeylonGo wordmark in white
      final titleFinder = find.byKey(const Key('provider_header_title'));
      expect(titleFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.data, equals('CeylonGo'));
      expect(textWidget.style?.color, equals(Colors.white));

      // Menu, Notification, and Profile buttons
      expect(find.byKey(const Key('provider_header_menu_button')), findsOneWidget);
      expect(find.byKey(const Key('provider_header_notifications_button')), findsOneWidget);
      expect(find.byKey(const Key('provider_header_profile_button')), findsOneWidget);
    });

    testWidgets('Renders Welcome Back section with business name and location', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('provider_welcome_greeting')), findsOneWidget);
      expect(find.text('Welcome Back,'), findsOneWidget);

      expect(find.byKey(const Key('provider_business_name')), findsOneWidget);
      expect(find.text('Galle Heritage Villa'), findsOneWidget);

      expect(find.byKey(const Key('provider_location_text')), findsOneWidget);
      expect(find.text('Galle, Southern Province'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('Header menu, notification, and profile taps open placeholder screens', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // Tap menu button
      await tester.tap(find.byKey(const Key('provider_header_menu_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Provider Menu'), findsWidgets);

      // Return
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsNothing);

      // Tap notifications button
      await tester.tap(find.byKey(const Key('provider_header_notifications_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Notifications'), findsWidgets);

      // Return
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsNothing);

      // Tap profile button
      await tester.tap(find.byKey(const Key('provider_header_profile_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Provider Profile'), findsWidgets);
    });
  });

  group('ProviderDashboardScreen — Six Management Cards Tests', () {
    testWidgets('Renders all six management action cards in 3x2 grid', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('action_manage_listings')), findsOneWidget);
      expect(find.text('Manage Listings'), findsOneWidget);

      expect(find.byKey(const Key('action_view_bookings')), findsOneWidget);
      expect(find.text('View Bookings'), findsOneWidget);

      expect(find.byKey(const Key('action_create_promotion')), findsOneWidget);
      expect(find.text('Create Promotion'), findsOneWidget);

      expect(find.byKey(const Key('action_manage_availability')), findsOneWidget);
      expect(find.text('Manage Availability'), findsOneWidget);

      expect(find.byKey(const Key('action_community_feed')), findsOneWidget);
      expect(find.text('Community Feed'), findsOneWidget);

      expect(find.byKey(const Key('action_payouts')), findsOneWidget);
      expect(find.text('Payouts'), findsOneWidget);
    });

    testWidgets('Tapping each of the six management cards opens a meaningful placeholder screen', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      // 1. Manage Listings
      await tester.tap(find.byKey(const Key('action_manage_listings')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Manage Listings'), findsWidgets);
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();

      // 2. View Bookings
      await tester.tap(find.byKey(const Key('action_view_bookings')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('View Bookings'), findsWidgets);
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();

      // 3. Create Promotion
      await tester.tap(find.byKey(const Key('action_create_promotion')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Create Promotion'), findsWidgets);
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();

      // 4. Manage Availability
      await tester.tap(find.byKey(const Key('action_manage_availability')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Manage Availability'), findsWidgets);
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();

      // 5. Community Feed
      await tester.tap(find.byKey(const Key('action_community_feed')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Community Feed'), findsWidgets);
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();

      // 6. Payouts
      await tester.tap(find.byKey(const Key('action_payouts')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Payouts'), findsWidgets);
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();
    });
  });

  group('ProviderDashboardScreen — Booking Sections Tests', () {
    testWidgets('Renders Today, Pending, and Upcoming booking sections with View All actions', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('section_today_bookings')), findsOneWidget);
      expect(find.text("Today's Bookings"), findsOneWidget);

      expect(find.byKey(const Key('section_pending_requests')), findsOneWidget);
      expect(find.text('Pending Requests'), findsOneWidget);

      expect(find.byKey(const Key('section_upcoming_bookings')), findsOneWidget);
      expect(find.text('Upcoming Bookings'), findsOneWidget);

      // 3 "View All" buttons (one per section)
      expect(find.text('View All'), findsNWidgets(3));
    });

    testWidgets('Renders booking card items with guest name, service title, and status', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Deluxe Ocean View Villa'), findsWidgets);
      expect(find.text('Check-in Today, 2:00 PM • 2 Nights'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsWidgets);

      expect(find.text('Kumara Wickramasinghe'), findsOneWidget);
      expect(find.text('Private Cinnamon Plantation Tour'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('Tapping a booking card opens Booking Details placeholder screen', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('booking_item_bkg-001')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('booking_item_bkg-001')), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.text('Booking Details'), findsWidgets);
      expect(find.textContaining('Sarah Jenkins'), findsOneWidget);

      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();
    });

    testWidgets('Displays appropriate empty state when booking lists are empty', (tester) async {
      final emptyData = ProviderDashboardData(
        businessName: 'Empty Homestay',
        location: 'Ella, Uva Province',
        todayBookings: [],
        pendingRequests: [],
        upcomingBookings: [],
      );

      await tester.pumpWidget(buildDashboard(data: emptyData));
      await tester.pumpAndSettle();

      expect(find.text('No bookings scheduled for today.'), findsOneWidget);
      expect(find.text('No pending booking requests awaiting review.'), findsOneWidget);
      expect(find.text('No upcoming reservations found.'), findsOneWidget);
    });
  });

  group('ProviderDashboardScreen — Bottom Navigation Tests', () {
    testWidgets('Renders 5 bottom navigation items with blue circular Add button', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav_home')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      expect(find.byKey(const Key('nav_bookings')), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);

      expect(find.byKey(const Key('nav_add_button')), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      expect(find.byKey(const Key('nav_reports')), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      expect(find.byKey(const Key('nav_profile')), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Tapping bottom nav Add button opens Add New Listing placeholder screen', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('nav_add_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderPlaceholderScreen), findsOneWidget);
      expect(find.textContaining('Add New Listing'), findsWidgets);
    });
  });

  group('ProviderDashboardScreen — Strict Exclusions Verification', () {
    testWidgets('Strictly does NOT render any forbidden sections or badges', (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('Monthly Earnings'), findsNothing);
      expect(find.text('Listing Performance'), findsNothing);
      expect(find.text('Verified Provider'), findsNothing);
      expect(find.text('Service Provider'), findsNothing);
      expect(find.text('Quick Actions'), findsNothing);
      expect(find.text('Weather'), findsNothing);
      expect(find.text('Map'), findsNothing);
      expect(find.text('Statistics'), findsNothing);
    });
  });

  group('ProviderDashboardScreen — Loading & Error State Tests', () {
    testWidgets('Renders CircularProgressIndicator when isLoading is true', (tester) async {
      await tester.pumpWidget(buildDashboard(isLoading: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Welcome Back,'), findsNothing);
    });

    testWidgets('Renders error card and Try Again button when errorMessage is provided', (tester) async {
      bool refreshed = false;
      await tester.pumpWidget(
        buildDashboard(
          errorMessage: 'Network timeout occurred',
          onRefresh: () async {
            refreshed = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
      expect(find.text('Network timeout occurred'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(refreshed, isTrue);
    });
  });

  group('ProviderDashboardScreen — Responsive Layout Tests', () {
    testWidgets('Renders without overflow on 320px width (small mobile)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome Back,'), findsOneWidget);
    });

    testWidgets('Renders without overflow on 360px width (Samsung Galaxy A22)', (tester) async {
      tester.view.physicalSize = const Size(360 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome Back,'), findsOneWidget);
    });

    testWidgets('Renders without overflow on 430px width (large mobile)', (tester) async {
      tester.view.physicalSize = const Size(430 * 3.0, 932 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome Back,'), findsOneWidget);
    });
  });
}
