import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/auth_response.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/login_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';

class MockLoginAuthService extends AuthService {
  String? loggedInEmail;
  String? loggedInPassword;
  bool shouldSucceed = true;

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    loggedInEmail = email;
    loggedInPassword = password;

    if (shouldSucceed) {
      return LoginResponse(
        accessToken: 'mock-valid-access-token-12345',
        tokenType: 'bearer',
        expiresIn: 3600,
        user: UserModel(
          id: 'usr-login-test',
          email: email,
          fullName: 'Test Traveler',
          role: 'tourist',
        ),
      );
    } else {
      throw Exception('Invalid email or password');
    }
  }
}

class FakeLoginStorageService extends SecureStorageService {
  String? token;
  UserModel? user;

  @override
  Future<void> saveToken(String token) async {
    this.token = token;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveUser(UserModel user) async {
    this.user = user;
  }

  @override
  Future<UserModel?> getUser() async => user;

  @override
  Future<void> clear() async {
    token = null;
    user = null;
  }
}

void main() {
  group('LoginScreen UI & Layout Tests', () {
    late MockLoginAuthService mockAuthService;
    late FakeLoginStorageService fakeStorageService;

    setUp(() {
      mockAuthService = MockLoginAuthService();
      fakeStorageService = FakeLoginStorageService();
    });

    Widget createWidgetUnderTest({
      String? initialEmail,
      Map<String, WidgetBuilder>? routes,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        routes: routes ?? {},
        home: LoginScreen(
          authService: mockAuthService,
          storageService: fakeStorageService,
          initialEmail: initialEmail,
        ),
      );
    }

    testWidgets('Renders all required elements in full-screen clean white UI', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Circular Outlined Back button near top SafeArea
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byKey(const Key('login_back_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_back_button')), findsOneWidget);

      // 2. Verified REMOVED: No images, cards, or social login elements
      expect(find.byType(Image), findsNothing);
      expect(find.text('Google'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('Or continue with'), findsNothing);
      expect(find.text('or continue with'), findsNothing);
      expect(find.text('100% Secure & Verified'), findsNothing);

      // 3. Bold Dark Navy Heading & Subtitle
      expect(find.text('Sign In to CeylonGo'), findsOneWidget);
      expect(
        find.text('Welcome back! Please sign in to your account.'),
        findsOneWidget,
      );

      // 4. Form Field Labels
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // 5. Input Fields with keys and placeholders
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.text('name@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      // 6. Working password visibility toggle
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // 7. Blue Forgot Password link below password field, aligned right
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_link')), findsOneWidget);

      // 8. Royal-blue gradient pill-shaped primary action button with arrow
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // 9. Bottom navigation link near bottom SafeArea
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(
        find.byKey(const Key('login_create_account_link')),
        findsOneWidget,
      );
    });

    testWidgets('Toggles password visibility between obscured and plain text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final toggleFinder = find.byTooltip('Show password');
      expect(toggleFinder, findsOneWidget);

      // Tap toggle to show password
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap toggle again to hide password
      await tester.tap(find.byTooltip('Hide password'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Show password'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Validates required fields when submitted empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final submitBtn = find.byKey(const Key('login_submit_button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);

      expect(mockAuthService.loggedInEmail, isNull);
    });

    testWidgets('Validates invalid email address format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.byKey(const Key('login_email_field'));
      await tester.enterText(emailField, 'not-an-email');

      final submitBtn = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(mockAuthService.loggedInEmail, isNull);
    });

    testWidgets(
      'Submits successfully with valid credentials and stores token',
      (WidgetTester tester) async {
        bool loginSuccessNavigated = false;

        await tester.pumpWidget(
          createWidgetUnderTest(
            routes: {
              '/login-success': (context) {
                loginSuccessNavigated = true;
                return const Scaffold(body: Text('Login Success Screen'));
              },
            },
          ),
        );

        final emailField = find.byKey(const Key('login_email_field'));
        final passwordField = find.byKey(const Key('login_password_field'));

        await tester.enterText(emailField, 'traveler@ceylongo.com');
        await tester.enterText(passwordField, 'SecurePass1');

        final submitBtn = find.byKey(const Key('login_submit_button'));
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(mockAuthService.loggedInEmail, 'traveler@ceylongo.com');
        expect(mockAuthService.loggedInPassword, 'SecurePass1');
        expect(fakeStorageService.token, 'mock-valid-access-token-12345');
        expect(fakeStorageService.user?.email, 'traveler@ceylongo.com');
        expect(loginSuccessNavigated, isTrue);
      },
    );

    testWidgets('Navigates to Forgot Password screen with prefilled email', (
      WidgetTester tester,
    ) async {
      String? passedEmail;

      await tester.pumpWidget(
        createWidgetUnderTest(
          routes: {
            '/forgot-password': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              passedEmail = args?['email'] as String?;
              return const Scaffold(body: Text('Forgot Password Screen'));
            },
          },
        ),
      );

      final emailField = find.byKey(const Key('login_email_field'));
      await tester.enterText(emailField, 'reset@ceylongo.com');

      final forgotLink = find.byKey(const Key('forgot_password_link'));
      await tester.tap(forgotLink);
      await tester.pumpAndSettle();

      expect(passedEmail, 'reset@ceylongo.com');
    });

    testWidgets('Navigates to Register screen with prefilled email', (
      WidgetTester tester,
    ) async {
      String? passedEmail;

      await tester.pumpWidget(
        createWidgetUnderTest(
          routes: {
            '/register': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              passedEmail = args?['email'] as String?;
              return const Scaffold(body: Text('Register Screen'));
            },
          },
        ),
      );

      final emailField = find.byKey(const Key('login_email_field'));
      await tester.enterText(emailField, 'newuser@ceylongo.com');

      final createAccountLink = find.byKey(
        const Key('login_create_account_link'),
      );
      await tester.tap(createAccountLink);
      await tester.pumpAndSettle();

      expect(passedEmail, 'newuser@ceylongo.com');
    });

    testWidgets('Responsive on narrow 320px mobile screen without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final submitBtn = find.byKey(const Key('login_submit_button'));

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(submitBtn, findsOneWidget);
    });

    testWidgets('Responsive on 375px and 430px mobile viewports', (
      WidgetTester tester,
    ) async {
      for (final width in [375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 812);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);

        final submitBtn = find.byKey(const Key('login_submit_button'));
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
        final backBtnFinder = find.byKey(const Key('login_back_button'));
        expect(backBtnFinder, findsOneWidget);
        final backRect = tester.getRect(backBtnFinder);
        expect(backRect.top, lessThanOrEqualTo(16.0));

        // 2. Headings and fields are properly positioned vertically
        final titleFinder = find.text('Sign In to CeylonGo');
        final emailFinder = find.byKey(const Key('login_email_field'));
        final passFinder = find.byKey(const Key('login_password_field'));
        final forgotFinder = find.byKey(const Key('forgot_password_link'));

        final titleRect = tester.getRect(titleFinder);
        final emailRect = tester.getRect(emailFinder);
        final passRect = tester.getRect(passFinder);
        final forgotRect = tester.getRect(forgotFinder);

        expect(backRect.bottom, lessThan(titleRect.top));
        expect(titleRect.bottom, lessThan(emailRect.top));
        expect(emailRect.bottom, lessThan(passRect.top));
        expect(passRect.bottom, lessThan(forgotRect.top));

        // 3. Submit button is directly visible in viewport without scrolling
        final submitBtn = find.byKey(const Key('login_submit_button'));
        expect(submitBtn, findsOneWidget);
        final btnRect = tester.getRect(submitBtn);
        expect(forgotRect.bottom, lessThan(btnRect.top));
        expect(btnRect.top, greaterThan(0.0));
        expect(btnRect.bottom, lessThan(800.0));

        // 4. Create Account link is positioned near the bottom SafeArea
        final createAccFinder = find.byKey(
          const Key('login_create_account_link'),
        );
        expect(createAccFinder, findsOneWidget);
        final createAccRect = tester.getRect(createAccFinder);
        expect(btnRect.bottom, lessThan(createAccRect.top));
        expect(createAccRect.top, greaterThan(0.0));
        expect(createAccRect.bottom, lessThan(800.0));
        expect(createAccRect.bottom, greaterThan(700.0));

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
        final backBtn = find.byKey(const Key('login_back_button'));
        expect(backBtn, findsOneWidget);
        final backRect = tester.getRect(backBtn);
        expect(backRect.top, lessThanOrEqualTo(16.0));

        // Form fields are fully visible
        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);
        expect(find.byKey(const Key('forgot_password_link')), findsOneWidget);

        // Submit button is fully visible
        final submitBtn = find.byKey(const Key('login_submit_button'));
        expect(submitBtn, findsOneWidget);
        final btnRect = tester.getRect(submitBtn);
        expect(btnRect.bottom, lessThan(728.0));

        // Create Account link is fully visible and positioned near the bottom SafeArea
        final createAccFinder = find.byKey(
          const Key('login_create_account_link'),
        );
        expect(createAccFinder, findsOneWidget);
        final createAccRect = tester.getRect(createAccFinder);
        expect(createAccRect.bottom, lessThan(728.0));
        expect(createAccRect.bottom, greaterThan(660.0));

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
        final submitBtn = find.byKey(const Key('login_submit_button'));
        await tester.ensureVisible(submitBtn);
        expect(submitBtn, findsOneWidget);
      },
    );
  });
}
