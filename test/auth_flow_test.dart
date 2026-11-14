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
  Future<Map<String, dynamic>> requestPasswordReset({required String email}) async {
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
    testWidgets('Renders header, heading with orange underline, and social buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));

      // Header and Trust Footer both render the signature tagline
      expect(find.text('Discover Local. Feel at Home.'), findsNWidgets(2));
      expect(find.byType(AuthTrustFooter), findsOneWidget);
      expect(find.byKey(const Key('auth_trust_shield_icon')), findsOneWidget);
      expect(find.text('Welcome to CeylonGo'), findsOneWidget);
      expect(find.text('Continue with Email'), findsOneWidget);

      // Social buttons: Full-width Google & WhatsApp buttons (Apple removed)
      expect(find.byKey(const Key('social_btn_google')), findsOneWidget);
      expect(find.byKey(const Key('social_btn_apple')), findsNothing);
      expect(find.byKey(const Key('social_btn_whatsapp')), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with WhatsApp'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsNothing);
    });

    testWidgets('Shows honest message when tapping social login buttons',
        (WidgetTester tester) async {
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

    testWidgets('AuthLandingScreen fits on Samsung Galaxy A22 (360x800) without scrolling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
      await tester.pumpAndSettle();

      // Verify Google and WhatsApp buttons are visible
      expect(find.byKey(const Key('social_btn_google')), findsOneWidget);
      expect(find.byKey(const Key('social_btn_whatsapp')), findsOneWidget);
      expect(find.byType(AuthTrustFooter), findsOneWidget);

      // Wave anchored to bottom
      final waveFinder = find.byType(AuthWaveDecoration);
      expect(waveFinder, findsOneWidget);
      final waveRect = tester.getRect(waveFinder);
      expect(waveRect.bottom, equals(800.0));

      // No vertical scrolling in normal view
      final scrollableFinder = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      );
      final scrollableState = tester.state<ScrollableState>(scrollableFinder.first);
      expect(scrollableState.position.maxScrollExtent, equals(0.0));
    });

    testWidgets('Validates email field before continuing',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));

      await tester.tap(find.byKey(const Key('continue_with_email_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('Positions AuthWaveDecoration at bottom of viewport on tall screen without empty space',
        (WidgetTester tester) async {
      // Simulate tall phone screen (400x900)
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
      await tester.pumpAndSettle();

      final waveFinder = find.byType(AuthWaveDecoration);
      expect(waveFinder, findsOneWidget);

      final waveRect = tester.getRect(waveFinder);
      expect(waveRect.bottom, equals(900.0));

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(const AuthLandingScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(AuthLandingScreen), findsOneWidget);
        expect(find.byKey(const Key('continue_with_email_button')), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 3: RegistrationSuccessScreen Tests', () {
    const testUser = UserModel(
      id: 'usr-200',
      fullName: 'Kamal Perera',
      email: 'kamal@example.com',
      role: 'tourist',
    );

    testWidgets('Displays real registered user details',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const RegistrationSuccessScreen(
          user: testUser,
          message: 'Account registered successfully',
        ),
      ));

      expect(find.text('Registration Successful'), findsOneWidget);
      expect(find.text('Kamal Perera'), findsOneWidget);
      expect(find.text('kamal@example.com'), findsOneWidget);
      expect(find.text('Explore CeylonGo'), findsOneWidget);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(
          const RegistrationSuccessScreen(user: testUser),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Registration Successful'), findsOneWidget);
        expect(find.byKey(const Key('explore_ceylongo_button')), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 4: Welcome Back (LoginScreen) Tests', () {
    testWidgets('Renders Welcome Back, prefilled email, and signs in',
        (WidgetTester tester) async {
      bool loginSuccessNavigated = false;

      await tester.pumpWidget(wrapWithTheme(
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
      ));

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('traveler@ceylongo.com'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.byType(AuthTrustFooter), findsOneWidget);
      expect(find.byKey(const Key('auth_trust_shield_icon')), findsOneWidget);

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

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(
          LoginScreen(
            authService: mockAuthService,
            storageService: fakeStorageService,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Welcome Back'), findsOneWidget);
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

    testWidgets('Displays real authenticated user info and Continue to Home',
        (WidgetTester tester) async {
      bool homeNavigated = false;

      await tester.pumpWidget(wrapWithTheme(
        const LoginSuccessScreen(user: user),
        routes: {
          '/home': (context) {
            homeNavigated = true;
            return const Scaffold(body: Text('Home Page'));
          },
        },
      ));

      expect(find.text('Login Successful'), findsOneWidget);
      expect(find.text('Nimal Silva'), findsOneWidget);
      expect(find.text('nimal@ceylongo.com'), findsOneWidget);
      expect(find.byType(AuthTrustFooter), findsOneWidget);
      expect(find.byKey(const Key('auth_trust_shield_icon')), findsOneWidget);

      await tester.tap(find.byKey(const Key('continue_to_home_button')));
      await tester.pumpAndSettle();
      expect(homeNavigated, isTrue);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(
          const LoginSuccessScreen(user: user),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Login Successful'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 6: ForgotPasswordScreen Tests', () {
    testWidgets('Renders Forgot Password with honest backend message on submit',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithTheme(
        ForgotPasswordScreen(authService: mockAuthService),
      ));

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.byType(AuthTrustFooter), findsOneWidget);
      expect(find.byKey(const Key('auth_trust_shield_icon')), findsOneWidget);

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
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(
          ForgotPasswordScreen(authService: mockAuthService),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.byType(AuthTrustFooter), findsOneWidget);
      expect(find.byKey(const Key('auth_trust_shield_icon')), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 7: CheckEmailScreen Tests', () {
    testWidgets('Displays target email address and action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const CheckEmailScreen(email: 'tourist@ceylongo.com'),
      ));

      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.text('tourist@ceylongo.com'), findsOneWidget);
      expect(find.byKey(const Key('open_email_app_button')), findsOneWidget);
      expect(find.byKey(const Key('back_to_signin_button')), findsOneWidget);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(
          const CheckEmailScreen(email: 'tourist@ceylongo.com'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Check Your Email'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 8: CreateNewPasswordScreen Tests', () {
    testWidgets('Validates checklist and shows strength dynamically',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithTheme(
        CreateNewPasswordScreen(authService: mockAuthService),
      ));

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

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(
          CreateNewPasswordScreen(authService: mockAuthService),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Create New Password'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Screen 9: PasswordResetSuccessScreen Tests', () {
    testWidgets('Renders success message and Back to Sign In button',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const PasswordResetSuccessScreen(),
      ));

      expect(find.text('Password Reset Successful'), findsOneWidget);
      expect(find.byKey(const Key('back_to_sign_in_button')), findsOneWidget);
    });

    testWidgets('Responsive at 320px, 375px, and 430px widths',
        (WidgetTester tester) async {
      for (final width in [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(wrapWithTheme(
          const PasswordResetSuccessScreen(),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Password Reset Successful'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
