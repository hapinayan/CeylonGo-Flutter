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

    testWidgets('Renders all required elements in simplified register UI', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Circular Back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byKey(const Key('register_back_button')), findsOneWidget);

      // 2. Verified REMOVED: No top illustration / image
      expect(
        find.byKey(const Key('register_header_illustration')),
        findsNothing,
      );
      expect(find.byType(Image), findsNothing);

      // 3. Heading & Subtitle
      expect(find.text('Create Your Account'), findsOneWidget);
      expect(
        find.text('Join CeylonGo and start exploring Sri Lanka.'),
        findsOneWidget,
      );

      // 4. Form Field Labels
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Contact Phone Number'), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(
        find.byKey(const Key('register_country_code_dropdown')),
        findsOneWidget,
      );

      // 5. Verified REMOVED: Confirm Password
      expect(find.text('Confirm Password'), findsNothing);
      expect(
        find.byKey(const Key('register_confirm_password_field')),
        findsNothing,
      );

      // 6. Password Helper Information Row
      expect(
        find.text('Minimum 8 characters, including a letter and number.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      // 7. Checkbox & Terms
      expect(find.byKey(const Key('register_terms_checkbox')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Terms and Privacy Notice'),
        ),
        findsOneWidget,
      );

      // 8. Primary button with arrow icon
      expect(
        find.widgetWithText(ElevatedButton, 'Create Account'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // 9. Bottom navigation
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // 10. Password placeholder
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

      // Check validation error messages for present fields
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);

      // Check that removed fields do NOT trigger validations
      expect(find.text('Please confirm your password'), findsNothing);

      expect(
        find.text(
          "You must agree to CeylonGo's Terms and Privacy Notice to continue",
        ),
        findsOneWidget,
      );

      // Service should not have been called
      expect(mockAuthService.registeredFullName, isNull);
    });

    testWidgets('Validates password field rules', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.byKey(const Key('register_password_field'));
      await tester.ensureVisible(passwordField);
      await tester.enterText(passwordField, 'short');

      final submitBtn = find.byKey(const Key('register_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be between 8 and 128 characters'),
        findsOneWidget,
      );
      expect(mockAuthService.registeredFullName, isNull);
    });

    testWidgets('Submits successfully with correct backend contract', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());

      // Fill in all required fields
      final nameField = find.byKey(const Key('register_full_name_field'));
      final emailField = find.byKey(const Key('register_email_field'));
      final passwordField = find.byKey(const Key('register_password_field'));
      final phoneField = find.byKey(const Key('register_phone_field'));

      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, 'Perera Silva');
      await tester.ensureVisible(emailField);
      await tester.enterText(emailField, 'perera@ceylongo.com');
      await tester.ensureVisible(passwordField);
      await tester.enterText(passwordField, 'SecurePass1');
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '771234567');

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
      // fullName, email, password are sent to API
      expect(mockAuthService.registeredFullName, 'Perera Silva');
      expect(mockAuthService.registeredEmail, 'perera@ceylongo.com');
      expect(mockAuthService.registeredPassword, 'SecurePass1');
    });

    testWidgets('Responsive on narrow 320px mobile screen without overflow', (
      WidgetTester tester,
    ) async {
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

      final nameField = find.byKey(const Key('register_full_name_field'));
      final emailField = find.byKey(const Key('register_email_field'));
      final passwordField = find.byKey(const Key('register_password_field'));
      expect(nameField, findsOneWidget);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      final submitBtn = find.byKey(const Key('register_submit_button'));
      await tester.ensureVisible(submitBtn);
      expect(submitBtn, findsOneWidget);

      final signInLink = find.text('Sign In');
      await tester.ensureVisible(signInLink);
      expect(signInLink, findsOneWidget);
    });

    testWidgets('Responsive on 375px and 430px mobile viewports', (
      WidgetTester tester,
    ) async {
      for (final width in [375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(RegisterScreen), findsOneWidget);

        final submitBtn = find.byKey(const Key('register_submit_button'));
        await tester.ensureVisible(submitBtn);
        expect(submitBtn, findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
      'Fits within Samsung Galaxy A22 screen (360x800) without scrolling when keyboard is closed',
      (WidgetTester tester) async {
        // Samsung Galaxy A22 logical dimensions: 360 x 800
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // 1. Circular Back button is rendered near top SafeArea
        final backBtnFinder = find.byKey(const Key('register_back_button'));
        expect(backBtnFinder, findsOneWidget);
        final backRect = tester.getRect(backBtnFinder);
        expect(backRect.top, lessThanOrEqualTo(16.0));

        // 2. Headings and fields are properly positioned
        final titleFinder = find.text('Create Your Account');
        final nameFinder = find.byKey(const Key('register_full_name_field'));
        final emailFinder = find.byKey(const Key('register_email_field'));
        final passFinder = find.byKey(const Key('register_password_field'));
        final phoneFinder = find.byKey(const Key('register_phone_field'));
        final termsFinder = find.byKey(const Key('register_terms_checkbox'));

        final titleRect = tester.getRect(titleFinder);
        final nameRect = tester.getRect(nameFinder);
        final emailRect = tester.getRect(emailFinder);
        final passRect = tester.getRect(passFinder);
        final phoneRect = tester.getRect(phoneFinder);
        final termsRect = tester.getRect(termsFinder);

        expect(backRect.bottom, lessThan(titleRect.top));
        expect(titleRect.bottom, lessThan(nameRect.top));
        expect(nameRect.bottom, lessThan(emailRect.top));
        expect(emailRect.bottom, lessThan(passRect.top));
        expect(passRect.bottom, lessThan(phoneRect.top));
        expect(phoneRect.bottom, lessThan(termsRect.top));

        // 3. Submit button is directly visible in viewport without scrolling
        final submitBtn = find.byKey(const Key('register_submit_button'));
        expect(submitBtn, findsOneWidget);
        final btnRect = tester.getRect(submitBtn);
        expect(termsRect.bottom, lessThan(btnRect.top));
        expect(btnRect.top, greaterThan(0.0));
        expect(btnRect.bottom, lessThan(800.0));

        // 4. Sign In link is positioned near the bottom SafeArea
        final signInFinder = find.text('Sign In');
        expect(signInFinder, findsOneWidget);
        final signInRect = tester.getRect(signInFinder);
        expect(btnRect.bottom, lessThan(signInRect.top));
        expect(signInRect.top, greaterThan(0.0));
        expect(signInRect.bottom, lessThan(800.0));
        expect(signInRect.bottom, greaterThan(720.0));

        // 5. Scroll position has zero extent (no scrolling required)
        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        final scrollableState = tester.state<ScrollableState>(
          scrollableFinder.first,
        );
        expect(scrollableState.position.pixels, equals(0.0));
        expect(scrollableState.position.maxScrollExtent, equals(0.0));
      },
    );

    testWidgets(
      'Fits within Samsung Galaxy A22 with SafeArea insets (360x728 usable height) without scrolling',
      (WidgetTester tester) async {
        // Usable height inside SafeArea on Galaxy A22 (800 - 24 status bar - 48 nav bar = 728)
        tester.view.physicalSize = const Size(360, 728);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Back button is positioned near the top SafeArea
        final backBtn = find.byKey(const Key('register_back_button'));
        expect(backBtn, findsOneWidget);
        final backRect = tester.getRect(backBtn);
        expect(backRect.top, lessThanOrEqualTo(16.0));

        // Form fields including Contact Phone Number are fully visible
        final phoneFinder = find.byKey(const Key('register_phone_field'));
        expect(phoneFinder, findsOneWidget);

        // Submit button is fully visible
        final submitBtn = find.byKey(const Key('register_submit_button'));
        expect(submitBtn, findsOneWidget);
        final btnRect = tester.getRect(submitBtn);
        expect(btnRect.bottom, lessThan(728.0));

        // Sign In link is fully visible and positioned near the bottom SafeArea
        final signInFinder = find.text('Sign In');
        expect(signInFinder, findsOneWidget);
        final signInRect = tester.getRect(signInFinder);
        expect(signInRect.bottom, lessThan(728.0));
        expect(signInRect.bottom, greaterThan(680.0));

        // Max scroll extent is 0 (no vertical scrolling in normal view)
        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        final scrollableState = tester.state<ScrollableState>(
          scrollableFinder.first,
        );
        expect(scrollableState.position.maxScrollExtent, equals(0.0));
      },
    );

    testWidgets(
      'Preserves vertical scrolling when screen is constrained or keyboard opens',
      (WidgetTester tester) async {
        // Constrained height (e.g. keyboard open: 360 x 420)
        tester.view.physicalSize = const Size(360, 420);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // When constrained, scroll extent expands smoothly
        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        final scrollableState = tester.state<ScrollableState>(
          scrollableFinder.first,
        );
        expect(scrollableState.position.maxScrollExtent, greaterThan(0.0));

        // Elements remain accessible via scrolling
        final submitBtn = find.byKey(const Key('register_submit_button'));
        await tester.ensureVisible(submitBtn);
        expect(submitBtn, findsOneWidget);
      },
    );
  });

  group('FormValidators Unit Tests', () {
    test('Phone number validator tests', () {
      expect(
        FormValidators.validatePhoneNumber(null),
        'Phone number is required',
      );
      expect(
        FormValidators.validatePhoneNumber(''),
        'Phone number is required',
      );
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
      expect(
        FormValidators.validateCountryCode(null),
        'Country code is required',
      );
      expect(
        FormValidators.validateCountryCode(''),
        'Country code is required',
      );
      expect(FormValidators.validateCountryCode('LK +94'), isNull);
    });
  });
}
