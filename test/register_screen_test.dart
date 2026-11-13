import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/core/utils/validators.dart';
import 'package:ceylongo/features/auth/models/auth_response.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/register_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';

class MockAuthService extends AuthService {
  String? registeredFullName;
  String? registeredEmail;
  String? registeredPassword;
  bool shouldSucceed = true;

  @override
  Future<RegisterResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registeredFullName = fullName;
    registeredEmail = email;
    registeredPassword = password;

    if (shouldSucceed) {
      return const RegisterResponse(
        message: 'Account created successfully. Please sign in.',
        user: UserModel(
          id: 'user-123',
          email: 'test@example.com',
          fullName: 'Test Traveler',
          role: 'traveler',
        ),
      );
    } else {
      throw Exception('Server error');
    }
  }
}

void main() {
  group('RegisterScreen UI & Layout Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: RegisterScreen(authService: mockAuthService),
      );
    }

    testWidgets('Renders all required elements including unified phone input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // 2. Logo & Tagline
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Discover Local. Feel at Home.'), findsOneWidget);

      // 3. Heading & Subtitle
      expect(find.text('Create Your CeylonGo Account'), findsOneWidget);
      expect(
        find.text(
          "Join CeylonGo and start exploring Sri Lanka's local stays, experiences, and more.",
        ),
        findsOneWidget,
      );

      // 4. Form Field Labels (Single label for Contact Phone Number)
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Contact Phone Number'), findsOneWidget);
      expect(find.text('Country Code'), findsNothing); // Combined into one field
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // 5. Unified Phone Field Elements
      expect(find.byKey(const Key('register_country_code_dropdown')), findsOneWidget);
      expect(find.text('LK +94'), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);

      // 6. Checkbox & Terms
      expect(find.byKey(const Key('register_terms_checkbox')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains("Terms and Privacy Notice"),
        ),
        findsOneWidget,
      );

      // 7. Primary button
      expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);

      // 8. Bottom navigation
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // 9. Wave decoration
      expect(find.byType(CeylonGoWaveDecoration), findsOneWidget);

      // 10. Shorter password placeholder "Enter your password"
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('Validates required fields when submitted empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final submitBtn = find.byKey(const Key('register_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
      expect(
        find.text("You must agree to CeylonGo's Terms and Privacy Notice to continue"),
        findsOneWidget,
      );

      // Service should not have been called
      expect(mockAuthService.registeredFullName, isNull);
    });

    testWidgets('Validates password confirmation match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter mismatched passwords
      final passwordField = find.byKey(const Key('register_password_field'));
      final confirmField = find.byKey(const Key('register_confirm_password_field'));

      await tester.ensureVisible(passwordField);
      await tester.enterText(passwordField, 'ValidPass1');
      await tester.ensureVisible(confirmField);
      await tester.enterText(confirmField, 'DifferentPass2');

      final submitBtn = find.byKey(const Key('register_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(mockAuthService.registeredFullName, isNull);
    });

    testWidgets(
      'Submits successfully with correct backend contract (no phone sent to API)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());

        // Fill in all valid fields
        final nameField = find.byKey(const Key('register_full_name_field'));
        final emailField = find.byKey(const Key('register_email_field'));
        final phoneField = find.byKey(const Key('register_phone_field'));
        final passwordField = find.byKey(const Key('register_password_field'));
        final confirmField = find.byKey(const Key('register_confirm_password_field'));

        await tester.ensureVisible(nameField);
        await tester.enterText(nameField, 'Perera Silva');
        await tester.ensureVisible(emailField);
        await tester.enterText(emailField, 'perera@ceylongo.com');
        await tester.ensureVisible(phoneField);
        await tester.enterText(phoneField, '771234567');
        await tester.ensureVisible(passwordField);
        await tester.enterText(passwordField, 'SecurePass1');
        await tester.ensureVisible(confirmField);
        await tester.enterText(confirmField, 'SecurePass1');

        // Check terms checkbox
        final checkbox = find.byKey(const Key('register_terms_checkbox'));
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // Submit form
        final submitBtn = find.byKey(const Key('register_submit_button'));
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Backend contract verification:
        // fullName, email, password are sent; phone is kept separate on client
        expect(mockAuthService.registeredFullName, 'Perera Silva');
        expect(mockAuthService.registeredEmail, 'perera@ceylongo.com');
        expect(mockAuthService.registeredPassword, 'SecurePass1');
      },
    );

    testWidgets(
      'Responsive on narrow 320px mobile screen with unified phone input on single row',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 568); // iPhone SE 1st gen size
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verify elements render without throwing Flutter overflow exceptions
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Verify unified field elements are visible together on the same row
        final dropdownFinder = find.byKey(const Key('register_country_code_dropdown'));
        final phoneFinder = find.byKey(const Key('register_phone_field'));
        expect(dropdownFinder, findsOneWidget);
        expect(phoneFinder, findsOneWidget);

        // Verify that dropdown and phone field centers are vertically aligned on the same horizontal row
        final dropdownCenter = tester.getCenter(dropdownFinder);
        final phoneCenter = tester.getCenter(phoneFinder);
        expect((dropdownCenter.dy - phoneCenter.dy).abs(), lessThan(10.0));

        // Test typing into unified phone field
        await tester.enterText(phoneFinder, '771234567');
        expect(find.text('771234567'), findsOneWidget);

        // Verify bottom elements are accessible through vertical scrolling
        final submitBtn = find.byKey(const Key('register_submit_button'));
        await tester.ensureVisible(submitBtn);
        expect(submitBtn, findsOneWidget);

        final signInLink = find.text('Sign In');
        await tester.ensureVisible(signInLink);
        expect(signInLink, findsOneWidget);
      },
    );

    testWidgets(
      'Responsive on 375px and 430px mobile viewports with unified phone field',
      (WidgetTester tester) async {
        for (final width in [375.0, 430.0]) {
          tester.view.physicalSize = Size(width, 812);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(createWidgetUnderTest());
          await tester.pumpAndSettle();

          expect(find.byType(RegisterScreen), findsOneWidget);

          final dropdownFinder = find.byKey(const Key('register_country_code_dropdown'));
          final phoneFinder = find.byKey(const Key('register_phone_field'));
          expect(dropdownFinder, findsOneWidget);
          expect(phoneFinder, findsOneWidget);

          // Verify horizontal alignment on the same row
          final dropdownCenter = tester.getCenter(dropdownFinder);
          final phoneCenter = tester.getCenter(phoneFinder);
          expect((dropdownCenter.dy - phoneCenter.dy).abs(), lessThan(10.0));

          final submitBtn = find.byKey(const Key('register_submit_button'));
          await tester.ensureVisible(submitBtn);
          expect(submitBtn, findsOneWidget);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });

  group('FormValidators Unit Tests', () {
    test('Phone number validator tests', () {
      expect(FormValidators.validatePhoneNumber(null), 'Phone number is required');
      expect(FormValidators.validatePhoneNumber(''), 'Phone number is required');
      expect(
        FormValidators.validatePhoneNumber('abc12345'),
        'Phone number must contain only digits',
      );
      expect(
        FormValidators.validatePhoneNumber('123'),
        'Phone number must be between 7 and 15 digits',
      );
      expect(FormValidators.validatePhoneNumber('771234567'), isNull);
      expect(FormValidators.validatePhoneNumber('077 123 4567'), isNull);
    });

    test('Country code validator tests', () {
      expect(FormValidators.validateCountryCode(null), 'Country code is required');
      expect(FormValidators.validateCountryCode(''), 'Country code is required');
      expect(FormValidators.validateCountryCode('LK +94'), isNull);
    });
  });
}
