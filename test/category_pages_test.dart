import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/artisan/services/artisan_demo_service.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/categories/screens/activities_category_screen.dart';
import 'package:ceylongo/features/categories/screens/eco_tourism_category_screen.dart';
import 'package:ceylongo/features/categories/screens/homestays_category_screen.dart';
import 'package:ceylongo/features/categories/screens/local_guides_category_screen.dart';
import 'package:ceylongo/features/categories/screens/rentals_category_screen.dart';
import 'package:ceylongo/features/categories/widgets/category_page_scaffold.dart';
import 'package:ceylongo/features/home/screens/home_screen.dart';
import 'package:ceylongo/features/home/widgets/home_bottom_navigation_bar.dart';
import 'package:ceylongo/features/home/widgets/home_category_filters.dart';
import 'package:ceylongo/features/navigation/screens/main_navigation_shell.dart';

void main() {
  const testUser = UserModel(
    id: 'usr-cat-001',
    fullName: 'Kamal Perera',
    email: 'kamal@ceylongo.com',
    role: 'tourist',
  );

  setUp(() {
    ArtisanDemoService.isDemoMode = true;
    ArtisanDemoService.instance.resetToDefaults();
  });

  Widget createRoutedApp() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        '/category/homestays': (_) => const HomestaysCategoryScreen(),
        '/category/eco': (_) => const EcoTourismCategoryScreen(),
        '/category/activities': (_) => const ActivitiesCategoryScreen(),
        '/category/guides': (_) => const LocalGuidesCategoryScreen(),
        '/category/rentals': (_) => const RentalsCategoryScreen(),
      },
      home: MainNavigationShell(
        initialIndex: 0,
        initialUser: testUser,
        artisanService: ArtisanDemoService.instance,
      ),
    );
  }

  group('Home Category Buttons & Back Navigation', () {
    testWidgets(
      'All 5 Home category buttons open their respective pages and Back returns to Home',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createRoutedApp());
        await tester.pump(const Duration(milliseconds: 750));

        final cases = [
          ('category_filter_homestays', 'Homestays'),
          ('category_filter_eco', 'Eco Tourism'),
          ('category_filter_activities', 'Activities'),
          ('category_filter_guides', 'Local Guides'),
          ('category_filter_rentals', 'Rentals'),
        ];

        for (final (keyName, pageTitle) in cases) {
          if (keyName == 'category_filter_guides' ||
              keyName == 'category_filter_rentals') {
            await tester.drag(
              find.byType(HomeCategoryFilters),
              const Offset(-200, 0),
            );
            await tester.pumpAndSettle();
          }
          final chip = find.byKey(Key(keyName));
          await tester.tap(chip);
          await tester.pumpAndSettle();

          expect(find.byType(CategoryPageScaffold), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(CategoryPageScaffold),
              matching: find.text(pageTitle),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(CategoryPageScaffold),
              matching: find.byType(HomeBottomNavigationBar),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);

          // Press Back -> returns to HomeScreen inside MainNavigationShell
          await tester.tap(find.byKey(const Key('category_back_btn')));
          await tester.pumpAndSettle();
          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(HomeBottomNavigationBar), findsOneWidget);
        }
      },
    );
  });

  group('Category Pages Search, Filter, Empty State & Overflow Checks', () {
    testWidgets('Homestays page supports search, filters, and empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomestaysCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Traditional Villa with garden'), findsOneWidget);
      expect(find.text('Ella Mountain Homestay'), findsOneWidget);

      await tester.tap(find.text('Galle'));
      await tester.pumpAndSettle();
      expect(find.text('Galle Fort Colonial Home'), findsOneWidget);
      expect(find.text('Ella Mountain Homestay'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('category_search_field')),
        'zzzzzz',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching listings found'), findsOneWidget);

      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Traditional Villa with garden'), findsOneWidget);
    });

    testWidgets('Eco Tourism, Activities, Local Guides, and Rentals render cleanly on 360x800',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Eco Tourism
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const EcoTourismCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Knuckles Cloud Forest Eco Lodge'), findsOneWidget);
      await tester.tap(find.text('Nature Experiences'));
      await tester.pumpAndSettle();
      expect(find.text('Sinharaja Rainforest Canopy Walk'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Activities
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ActivitiesCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ella Rock Sunrise Hike'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(CategoryChipFilterRow),
          matching: find.text('Surfing'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Weligama Beginner Surf Lesson'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Local Guides
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LocalGuidesCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saman Perera'), findsOneWidget);
      final tamilChip = find.text('Tamil');
      await tester.ensureVisible(tamilChip);
      await tester.tap(tamilChip);
      await tester.pumpAndSettle();
      expect(find.text('Nirosha Selvam'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Rentals
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RentalsCategoryScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Suzuki Alto Compact Car'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(CategoryChipFilterRow),
          matching: find.text('Scooters'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Honda Dio 110cc Scooter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

