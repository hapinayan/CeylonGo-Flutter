import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/widgets/ceylongo_network_image.dart';

void main() {
  group('CeylonGoNetworkImage', () {
    testWidgets('Renders fallback icon immediately when imageUrl is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: CeylonGoNetworkImage(
                imageUrl: '',
                fallbackIcon: Icons.person_outline_rounded,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('Renders fallback icon when network image fails (no blank box)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: CeylonGoNetworkImage(
                imageUrl: 'https://example.com/nonexistent.jpg',
                fallbackIcon: Icons.holiday_village_rounded,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.holiday_village_rounded), findsOneWidget);
    });
  });
}

