import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/main.dart';

void main() {
  testWidgets('CeylonGoApp boots and displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CeylonGoApp(initialRoute: '/login'));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
