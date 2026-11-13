import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/home/screens/home_screen.dart';

void main() {
  const testUser = UserModel(
    id: 'usr-home-001',
    fullName: 'Kamal Perera',
    email: 'kamal@ceylongo.com',
    role: 'tourist',
  );

  Widget createHomeScreen({UserModel? user}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: HomeScreen(
        initialUser: user ?? testUser,
      ),
    );
  }

  group('HomeScreen AppBar Logo & Layout Tests', () {
    testWidgets('Renders original CeylonGo logo with BoxFit.contain in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Find Image.asset in the AppBar
      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/ceylongo_original_logo.jpg' &&
            widget.fit == BoxFit.contain,
      );

      expect(imageFinder, findsOneWidget);

      // Verify AppBar background is white
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(AppTheme.backgroundWhite));
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('Retains Welcome Card, user info, role, and Sign Out button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('Welcome, Kamal Perera!'), findsOneWidget);
      expect(find.text('kamal@ceylongo.com'), findsOneWidget);
      expect(find.text('TOURIST'), findsOneWidget);
      expect(find.text('Discover Local. Feel at Home.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign Out'), findsOneWidget);
      expect(find.byTooltip('Sign Out'), findsOneWidget);
    });

    testWidgets('Logo size is increased by ~25-30% and positioned 10-12px downward',
        (WidgetTester tester) async {
      // Test on standard mobile (375px)
      tester.view.physicalSize = const Size(375, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/ceylongo_original_logo.jpg',
      ));

      // Standard mobile logo height is 70.0 (increased ~29.6% from 54.0)
      expect(image.height, equals(70.0));
      expect(image.fit, equals(BoxFit.contain));

      // Verify downward positioning (top padding: 11px)
      final paddingFinder = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/ceylongo_original_logo.jpg',
        ),
        matching: find.byType(Padding),
      );
      final padding = tester.widget<Padding>(paddingFinder.first);
      expect((padding.padding as EdgeInsets).top, equals(11.0));

      // Verify toolbarHeight increased appropriately (94.0)
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, equals(94.0));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Responsive across small mobile (320px) to desktop (1200px)',
        (WidgetTester tester) async {
      final viewports = [
        320.0, // Small mobile
        375.0, // iPhone / compact
        430.0, // Large mobile
        800.0, // Tablet
        1200.0, // Desktop
      ];

      for (final width in viewports) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Ensure logo is rendered
        final imageFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/ceylongo_original_logo.jpg',
        );
        expect(imageFinder, findsOneWidget);

        // Verify no RenderFlex overflow occurs
        expect(tester.takeException(), isNull);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

