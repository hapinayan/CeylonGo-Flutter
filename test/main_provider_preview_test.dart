import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/features/provider/screens/provider_dashboard_screen.dart';
import 'package:ceylongo/main_provider_preview.dart';

void main() {
  group('ProviderDashboardPreviewApp — Entry Point Tests', () {
    testWidgets('Boots and renders the complete Provider Dashboard with fixture data', (tester) async {
      await tester.pumpWidget(const ProviderDashboardPreviewApp());
      await tester.pumpAndSettle();

      // 1. MaterialApp setup
      expect(find.byType(MaterialApp), findsOneWidget);
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);

      // 2. ProviderDashboardScreen presence
      expect(find.byType(ProviderDashboardScreen), findsOneWidget);

      // 3. Header
      expect(find.byKey(const Key('provider_header_title')), findsOneWidget);
      expect(find.text('CeylonGo'), findsOneWidget);
      expect(find.byKey(const Key('provider_header_menu_button')), findsOneWidget);
      expect(find.byKey(const Key('provider_header_notifications_button')), findsOneWidget);
      expect(find.byKey(const Key('provider_header_profile_button')), findsOneWidget);

      // 4. Welcome section with fixture business data
      expect(find.text('Welcome Back,'), findsOneWidget);
      expect(find.text('Galle Heritage Villa'), findsOneWidget);
      expect(find.text('Galle, Southern Province'), findsOneWidget);

      // 5. Six management cards in grid
      expect(find.text('Manage Listings'), findsOneWidget);
      expect(find.text('View Bookings'), findsOneWidget);
      expect(find.text('Create Promotion'), findsOneWidget);
      expect(find.text('Manage Availability'), findsOneWidget);
      expect(find.text('Community Feed'), findsOneWidget);
      expect(find.text('Payouts'), findsOneWidget);

      // 6. Booking sections
      expect(find.text("Today's Bookings"), findsOneWidget);
      expect(find.text('Sarah Jenkins'), findsOneWidget);
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(find.text('Kumara Wickramasinghe'), findsOneWidget);
      expect(find.text('Upcoming Bookings'), findsOneWidget);

      // 7. Five-item bottom navigation
      expect(find.byKey(const Key('nav_home')), findsOneWidget);
      expect(find.byKey(const Key('nav_bookings')), findsOneWidget);
      expect(find.byKey(const Key('nav_add_button')), findsOneWidget);
      expect(find.byKey(const Key('nav_reports')), findsOneWidget);
      expect(find.byKey(const Key('nav_profile')), findsOneWidget);
    });

    testWidgets('Pull to refresh interaction reloads fixture data seamlessly', (tester) async {
      await tester.pumpWidget(const ProviderDashboardPreviewApp());
      await tester.pumpAndSettle();

      // Fling down to trigger RefreshIndicator
      await tester.fling(find.text('Welcome Back,'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Dashboard remains intact after reload
      expect(find.text('Galle Heritage Villa'), findsOneWidget);
    });
  });
}
