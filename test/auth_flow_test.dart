import 'package:ceylongo/features/auth/widgets/light_blue_wave_decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/models/auth_response.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/auth_landing_screen.dart';
import 'package:ceylongo/features/auth/screens/check_email_screen.dart';
import 'package:ceylongo/features/auth/screens/create_new_password_screen.dart';
import 'package:ceylongo/features/auth/screens/forgot_password_screen.dart';
import 'package:ceylongo/features/auth/screens/login_screen.dart';
import 'package:ceylongo/features/auth/screens/login_success_screen.dart';
import 'package:ceylongo/features/auth/screens/password_reset_success_screen.dart';
import 'package:ceylongo/features/auth/screens/registration_success_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/features/auth/widgets/auth_header.dart';
import 'package:ceylongo/features/auth/widgets/auth_heading.dart';
import 'package:ceylongo/features/auth/widgets/auth_trust_footer.dart';
import 'package:ceylongo/features/auth/widgets/auth_wave_decoration.dart';

class FakeSecureStorageService extends SecureStorageService {
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

class MockFlowAuthService extends AuthService {
  String? registeredFullName;
  String? registeredEmail;
  String? registeredPassword;
  String? loggedInEmail;
  String? loggedInPassword;

  @override
  Future<RegisterResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registeredFullName = fullName;
    registeredEmail = email;
    registeredPassword = password;

    return RegisterResponse(
      message: 'Account registered successfully',
      user: UserModel(
        id: 'usr-101',
        fullName: fullName,
        email: email,
        role: 'tourist',
      ),
    );
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    loggedInEmail = email;
    loggedInPassword = password;

    return LoginResponse(
      accessToken: 'valid-mock-jwt-token',
      tokenType: 'bearer',
      expiresIn: 3600,
      user: UserModel(
        id: 'usr-101',
        fullName: 'Test Traveler',
        email: email,
        role: 'tourist',
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    throw const ApiError(
      statusCode: 501,
      code: 'BACKEND_NOT_CONFIGURED',
      message: 'Password reset is not yet supported by the CeylonGo backend server. Please contact support@ceylongo.com for assistance.',
    );
  }

  @override
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    throw const ApiError(
      statusCode: 501,
      code: 'BACKEND_NOT_CONFIGURED',
      message: 'Password reset update is not yet supported by the CeylonGo backend server.',
    );
  }
}

void main() {
  late MockFlowAuthService mockAuthService;
  late FakeSecureStorageService fakeStorageService;

  setUp(() {
    mockAuthService = MockFlowAuthService();
    fakeStorageService = FakeSecureStorageService();
  });

  Widget wrapWithTheme(Widget child, {Map<String, WidgetBuilder>? routes}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: routes ?? {},
      home: child,
    );
  }

  group('Screen 1: AuthLandingScreen Tests', () {
    testWidgets(
      'Renders 3D cartoon tourist header, organic curved wave, white panel, and social buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));

        // New Header heading & subtitle & back button
        expect(find.byKey(const Key('auth_back_button')), findsOneWidget);
        expect(find.text('Sign In /\nCreate Account'), findsOneWidget);
        expect(
          find.text('Your gateway to authentic Sri Lankan experiences.'),
          findsOneWidget,
        );

        // Email field with outlined icon and placeholder (NO separate label)
        expect(find.text('Email Address'), findsNothing);
        expect(find.byKey(const Key('entry_email_field')), findsOneWidget);
        expect(find.text('Enter your email address'), findsOneWidget);

        // Continue with Email button with trailing arrow
        expect(
          find.byKey(const Key('continue_with_email_button')),
          findsOneWidget,
        );
        expect(find.text('Continue with Email'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

        // Divider with 'or continue with'
        expect(find.text('or continue with'), findsOneWidget);

        // Social buttons: Full-width Google & WhatsApp buttons (Apple removed)
        expect(find.byKey(const Key('social_btn_google')), findsOneWidget);
        expect(find.byKey(const Key('social_btn_apple')), findsNothing);
        expect(find.byKey(const Key('social_btn_whatsapp')), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with WhatsApp'), findsOneWidget);
        expect(find.text('Continue with Apple'), findsNothing);

        // Create Account path and legal notice
        expect(find.text('New to CeylonGo? '), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.textContaining('Terms & Conditions'), findsOneWidget);
        expect(find.textContaining('Privacy Policy'), findsOneWidget);

        // Old auth header, heading, wave, and trust footer removed from landing screen
        expect(find.byType(AuthHeader), findsNothing);
        expect(find.byType(AuthHeading), findsNothing);
        expect(find.byType(AuthTrustFooter), findsNothing);
        expect(find.byType(AuthWaveDecoration), findsNothing);
      },
    );

    testWidgets('Shows honest message when tapping social login buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));

      // Tap Google button
      await tester.tap(find.byKey(const Key('social_btn_google')));
      await tester.pump();
      expect(
        find.text(
          'Google sign-in is not yet configured on this server. Please use email.',
        ),
        findsOneWidget,
      );

      // Tap WhatsApp button
      await tester.tap(find.byKey(const Key('social_btn_whatsapp')));
      await tester.pump();
      expect(
        find.text(
          'WhatsApp sign-in is not yet configured on this server. Please use email.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'AuthLandingScreen fits on Samsung Galaxy A22 (360x800) without scrolling',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
        await tester.pumpAndSettle();

        // Verify header, email field, buttons, and legal text are visible
        expect(find.byKey(const Key('auth_back_button')), findsOneWidget);
        expect(find.text('Sign In /\nCreate Account'), findsOneWidget);
        expect(find.byKey(const Key('entry_email_field')), findsOneWidget);
        expect(
          find.byKey(const Key('continue_with_email_button')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('social_btn_google')), findsOneWidget);
        expect(find.byKey(const Key('social_btn_whatsapp')), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);
        expect(find.textContaining('Terms & Conditions'), findsOneWidget);

        // No Spacer gap between Create Account and Disclaimer
        expect(
          find.descendant(
            of: find.byType(AuthLandingScreen),
            matching: find.byType(Spacer),
          ),
          findsNothing,
        );

        // Verify heading is anchored near top of white panel (12-20px distance)
        final panelBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('auth_content_panel')),
        );
        final headingBox = tester.renderObject<RenderBox>(
          find.text('Sign In /\nCreate Account'),
        );
        final emailBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('entry_email_field')),
        );
        final panelTop = panelBox.localToGlobal(Offset.zero).dy;
        final headingTop = headingBox.localToGlobal(Offset.zero).dy;
        final emailTop = emailBox.localToGlobal(Offset.zero).dy;
        final distanceFromPanelTop = headingTop - panelTop;
        expect(distanceFromPanelTop, inInclusiveRange(12.0, 20.0));
        expect(emailTop, greaterThan(headingTop));

        // Verify dynamic header absorbs surplus vertical space
        final headerBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('auth_header_container')),
        );
        expect(headerBox.size.height, greaterThanOrEqualTo(240.0));

        // Verify reduced unused space below the legal disclaimer (< 160px vs > 250px previously)
        final disclaimerBox = tester.renderObject<RenderBox>(
          find.textContaining('Terms & Conditions'),
        );
        final disclaimerBottom =
            disclaimerBox.localToGlobal(Offset.zero).dy +
            disclaimerBox.size.height;
        final spaceBelowDisclaimer = 800.0 - disclaimerBottom;
        expect(spaceBelowDisclaimer, lessThan(160.0));
        expect(spaceBelowDisclaimer, greaterThanOrEqualTo(10.0));

        // No vertical scrolling in normal view on 360x800
        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        final scrollableState = tester.state<ScrollableState>(
          scrollableFinder.first,
        );
        expect(scrollableState.position.maxScrollExtent, equals(0.0));
        expect(
          scrollableState.position.physics,
          isA<NeverScrollableScrollPhysics>(),
        );
      },
    );

    testWidgets(
      'AuthLandingScreen fits on Samsung Galaxy A22 with SafeArea insets (360x728) without scrolling',
      (WidgetTester tester) async {
        // Usable height inside SafeArea on Galaxy A22 (800 - 24 status bar - 48 nav bar = 728)
        tester.view.physicalSize = const Size(360, 728);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
        await tester.pumpAndSettle();

        // Verify header dynamically scales to usable height
        final headerBox = tester.renderObject<RenderBox>(
          find.byKey(const Key('auth_header_container')),
        );
        expect(headerBox.size.height, greaterThanOrEqualTo(180.0));

        // Verify space below disclaimer is reduced on 728 usable height
        final disclaimerBox = tester.renderObject<RenderBox>(
          find.textContaining('Terms & Conditions'),
        );
        final disclaimerBottom =
            disclaimerBox.localToGlobal(Offset.zero).dy +
            disclaimerBox.size.height;
        final spaceBelowDisclaimer = 728.0 - disclaimerBottom;
        expect(spaceBelowDisclaimer, lessThan(130.0));
        expect(spaceBelowDisclaimer, greaterThanOrEqualTo(10.0));

        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        final scrollableState = tester.state<ScrollableState>(
          scrollableFinder.first,
        );
        expect(scrollableState.position.maxScrollExtent, equals(0.0));
        expect(
          scrollableState.position.physics,
          isA<NeverScrollableScrollPhysics>(),
        );
      },
    );

    testWidgets(
      'AuthLandingScreen enables scrolling when keyboard opens or screen is constrained',
      (WidgetTester tester) async {
        // Constrained height simulating open keyboard or short display
        tester.view.physicalSize = const Size(360, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
        await tester.pumpAndSettle();

        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        final scrollableState = tester.state<ScrollableState>(
          scrollableFinder.first,
        );
        expect(scrollableState.position.physics, isA<ClampingScrollPhysics>());
      },
    );

    testWidgets('Validates email field before continuing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));

      // Empty submission
      await tester.tap(find.byKey(const Key('continue_with_email_button')));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);

      // Invalid email
      await tester.enterText(
        find.byKey(const Key('entry_email_field')),
        'not-an-email',
      );
      await tester.tap(find.byKey(const Key('continue_with_email_button')));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets(
      'Navigates to /login with prefilled email on valid submission',
      (WidgetTester tester) async {
        String? pushedEmail;
        await tester.pumpWidget(
          wrapWithTheme(
            const AuthLandingScreen(),
            routes: {
              '/login': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                pushedEmail = args?['email'] as String?;
                return const Scaffold(body: Text('Login Mock'));
              },
            },
          ),
        );

        await tester.enterText(
          find.byKey(const Key('entry_email_field')),
          'traveler@example.com',
        );
        await tester.tap(find.byKey(const Key('continue_with_email_button')));
        await tester.pumpAndSettle();

        expect(pushedEmail, equals('traveler@example.com'));
        expect(find.text('Login Mock'), findsOneWidget);
      },
    );

    testWidgets(
      'Navigates to /register when tapping Create Account text link',
      (WidgetTester tester) async {
        String? pushedEmail;
        await tester.pumpWidget(
          wrapWithTheme(
            const AuthLandingScreen(),
            routes: {
              '/register': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                pushedEmail = args?['email'] as String?;
                return const Scaffold(body: Text('Register Mock'));
              },
            },
          ),
        );

        await tester.enterText(
          find.byKey(const Key('entry_email_field')),
          'newuser@example.com',
        );
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        expect(pushedEmail, equals('newuser@example.com'));
        expect(find.text('Register Mock'), findsOneWidget);
      },
    );

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(AuthLandingScreen), findsOneWidget);
        expect(
          find.byKey(const Key('continue_with_email_button')),
          findsOneWidget,
        );
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets(
      'Email input gains and retains focus when tapped and user types',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
        await tester.pumpAndSettle();

        final emailFieldFinder = find.byKey(const Key('entry_email_field'));
        expect(emailFieldFinder, findsOneWidget);

        // Initially no focus
        final textFieldFinder = find.descendant(
          of: emailFieldFinder,
          matching: find.byType(TextField),
        );
        final initialTextField = tester.widget<TextField>(textFieldFinder);
        expect(initialTextField.focusNode?.hasFocus ?? false, isFalse);

        // Tap the email field to focus
        await tester.tap(emailFieldFinder);
        await tester.pumpAndSettle();

        final focusedTextField = tester.widget<TextField>(textFieldFinder);
        expect(focusedTextField.focusNode?.hasFocus, isTrue);

        // Type characters sequentially and confirm focus is retained
        await tester.enterText(emailFieldFinder, 'tourist@ceylongo.com');
        await tester.pumpAndSettle();

        final typedTextField = tester.widget<TextField>(textFieldFinder);
        expect(typedTextField.focusNode?.hasFocus, isTrue);
        expect(find.text('tourist@ceylongo.com'), findsOneWidget);
      },
    );

    testWidgets(
      'Email input retains focus when keyboard opens and screen height shrinks',
      (WidgetTester tester) async {
        // Start on Samsung Galaxy A22 full screen (360x800)
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
        await tester.pumpAndSettle();

        final emailFieldFinder = find.byKey(const Key('entry_email_field'));
        await tester.tap(emailFieldFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.descendant(
          of: emailFieldFinder,
          matching: find.byType(TextField),
        );
        expect(
          tester.widget<TextField>(textFieldFinder).focusNode?.hasFocus,
          isTrue,
        );

        // Simulate software keyboard opening (screen height reduces to 480px)
        tester.view.physicalSize = const Size(360, 480);
        await tester.pumpAndSettle();

        // Field MUST retain focus and input connection without closing keyboard
        expect(
          tester.widget<TextField>(textFieldFinder).focusNode?.hasFocus,
          isTrue,
        );

        // Typing works seamlessly while keyboard is up
        await tester.enterText(emailFieldFinder, 'test@example.com');
        await tester.pumpAndSettle();

        expect(
          tester.widget<TextField>(textFieldFinder).focusNode?.hasFocus,
          isTrue,
        );
        expect(find.text('test@example.com'), findsOneWidget);

        // ScrollViewKeyboardDismissBehavior is manual so typing/scrolling does not drop keyboard
        final scrollable = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(
          scrollable.keyboardDismissBehavior,
          equals(ScrollViewKeyboardDismissBehavior.manual),
        );
      },
    );
  });

  group('Screen 3: RegistrationSuccessScreen Tests', () {
    const testUser = UserModel(
      id: 'usr-200',
      fullName: 'Kamal Perera',
      email: 'kamal@example.com',
      role: 'tourist',
    );

    testWidgets('Displays Account Created confirmation and Continue to Home', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const RegistrationSuccessScreen(
            user: testUser,
            message: 'Account registered successfully',
          ),
        ),
      );

      expect(find.text('Account Created!'), findsOneWidget);
      expect(
        find.text('Your CeylonGo account has been created successfully.'),
        findsOneWidget,
      );
      expect(find.text('Continue to Home'), findsOneWidget);
      expect(find.byType(LightBlueWaveDecoration), findsOneWidget);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapWithTheme(const RegistrationSuccessScreen(user: testUser)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Account Created!'), findsOneWidget);
        expect(
          find.byKey(const Key('continue_to_home_button')),
          findsOneWidget,
        );
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 4: Welcome Back (LoginScreen) Tests', () {
    testWidgets('Renders Sign In to CeylonGo, prefilled email, and signs in', (
      WidgetTester tester,
    ) async {
      bool loginSuccessNavigated = false;

      await tester.pumpWidget(
        wrapWithTheme(
          LoginScreen(
            authService: mockAuthService,
            storageService: fakeStorageService,
            initialEmail: 'traveler@ceylongo.com',
          ),
          routes: {
            '/login-success': (context) {
              loginSuccessNavigated = true;
              return const Scaffold(body: Text('Login Success Page'));
            },
          },
        ),
      );

      expect(find.text('Sign In to CeylonGo'), findsOneWidget);
      expect(
        find.text('Welcome back! Please sign in to your account.'),
        findsOneWidget,
      );
      expect(find.text('traveler@ceylongo.com'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Enter password
      final passwordField = find.byKey(const Key('login_password_field'));
      await tester.enterText(passwordField, 'SecurePass1');

      // Submit
      final submitBtn = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockAuthService.loggedInEmail, 'traveler@ceylongo.com');
      expect(mockAuthService.loggedInPassword, 'SecurePass1');
      expect(loginSuccessNavigated, isTrue);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapWithTheme(
            LoginScreen(
              authService: mockAuthService,
              storageService: fakeStorageService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sign In to CeylonGo'), findsOneWidget);
        expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 5: LoginSuccessScreen Tests', () {
    const user = UserModel(
      id: 'usr-300',
      fullName: 'Nimal Silva',
      email: 'nimal@ceylongo.com',
      role: 'tourist',
    );

    testWidgets('Displays real authenticated user info and Continue to Home', (
      WidgetTester tester,
    ) async {
      bool homeNavigated = false;

      await tester.pumpWidget(
        wrapWithTheme(
          const LoginSuccessScreen(user: user),
          routes: {
            '/home': (context) {
              homeNavigated = true;
              return const Scaffold(body: Text('Home Page'));
            },
          },
        ),
      );

      expect(find.text('Login Successful'), findsOneWidget);
      expect(find.text('Nimal Silva'), findsOneWidget);
      expect(find.text('nimal@ceylongo.com'), findsOneWidget);
      expect(find.byType(AuthTrustFooter), findsOneWidget);
      expect(find.byKey(const Key('auth_trust_shield_icon')), findsOneWidget);

      await tester.tap(find.byKey(const Key('continue_to_home_button')));
      await tester.pumpAndSettle();
      expect(homeNavigated, isTrue);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapWithTheme(const LoginSuccessScreen(user: user)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Login Successful'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 6: ForgotPasswordScreen Tests', () {
    testWidgets(
      'Renders Forgot Password? with honest backend message on submit',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapWithTheme(ForgotPasswordScreen(authService: mockAuthService)),
        );

        expect(find.text('Forgot Password?'), findsOneWidget);
        expect(
          find.text('Enter your email address to reset your password.'),
          findsOneWidget,
        );
        expect(find.byType(LightBlueWaveDecoration), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('forgot_email_field')),
          'user@ceylongo.com',
        );

        await tester.tap(find.byKey(const Key('send_reset_link_button')));
        await tester.pumpAndSettle();

        // Does not fake success; displays honest backend status
        expect(
          find.textContaining('Password reset is not yet supported'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapWithTheme(ForgotPasswordScreen(authService: mockAuthService)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Forgot Password?'), findsOneWidget);
        expect(find.byType(LightBlueWaveDecoration), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 7: CheckEmailScreen Tests', () {
    testWidgets('Displays Reset Email Sent! and Back to Sign In', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(const CheckEmailScreen(email: 'tourist@ceylongo.com')),
      );

      expect(find.text('Reset Email Sent!'), findsOneWidget);
      expect(
        find.text(
          "We've sent a password reset link to your email address. Please check your inbox.",
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('back_to_signin_button')), findsOneWidget);
      expect(find.byType(LightBlueWaveDecoration), findsOneWidget);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapWithTheme(const CheckEmailScreen(email: 'tourist@ceylongo.com')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Reset Email Sent!'), findsOneWidget);
        expect(find.byType(LightBlueWaveDecoration), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 8: CreateNewPasswordScreen Tests', () {
    testWidgets('Validates checklist and shows strength dynamically', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(CreateNewPasswordScreen(authService: mockAuthService)),
      );

      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('At least one uppercase letter (A-Z)'), findsOneWidget);

      // Type weak password
      final passField = find.byKey(const Key('new_password_field'));
      await tester.enterText(passField, 'pass');
      await tester.pump();
      expect(find.text('Weak'), findsOneWidget);

      // Type strong password
      await tester.enterText(passField, 'StrongPassword1');
      await tester.pump();
      expect(find.text('Strong'), findsOneWidget);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapWithTheme(CreateNewPasswordScreen(authService: mockAuthService)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Create New Password'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 9: PasswordResetSuccessScreen Tests', () {
    testWidgets('Renders success message and Back to Sign In button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWithTheme(const PasswordResetSuccessScreen()),
      );

      expect(find.text('Password Reset Successful'), findsOneWidget);
      expect(find.byKey(const Key('back_to_sign_in_button')), findsOneWidget);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          wrapWithTheme(const PasswordResetSuccessScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Password Reset Successful'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
