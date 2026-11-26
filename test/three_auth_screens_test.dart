import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/check_email_screen.dart';
import 'package:ceylongo/features/auth/screens/forgot_password_screen.dart';
import 'package:ceylongo/features/auth/screens/registration_success_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/features/auth/widgets/light_blue_wave_decoration.dart';

class MockThreeAuthScreensService extends AuthService {
  String? requestedEmail;
  bool shouldSucceed = true;

  @override
  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    requestedEmail = email;
    if (shouldSucceed) {
      return {
        'message': 'Password reset link sent successfully.',
        'status': 'success',
      };
    } else {
      throw const ApiError(
        statusCode: 501,
        code: 'BACKEND_NOT_CONFIGURED',
        message: 'Password reset is not yet supported by the CeylonGo backend server.',
      );
    }
  }
}

void main() {
  Widget wrapWidget(Widget child, {Map<String, WidgetBuilder>? routes}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      routes: routes ?? {},
      home: child,
    );
  }

  group('Screen 1: Forgot Password Screen Tests', () {
    late MockThreeAuthScreensService mockAuthService;

    setUp(() {
      mockAuthService = MockThreeAuthScreensService();
    });

    testWidgets('Renders all required elements matching reference design', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(ForgotPasswordScreen(authService: mockAuthService)),
      );

      // 1. Circular Outlined Back Button near top-left
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byKey(const Key('forgot_back_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_back_button')), findsOneWidget);

      // 2. Heading and Subtitle
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(
        find.text('Enter your email address to reset your password.'),
        findsOneWidget,
      );

      // 3. Email input field with navy envelope icon and placeholder
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.byKey(const Key('forgot_email_field')), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      // 4. Blue gradient "Send Reset Link →" button
      expect(find.byKey(const Key('send_reset_link_button')), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // 5. Blue "← Back to Sign In" link
      expect(find.byKey(const Key('back_to_signin_link')), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);

      // 6. Light-blue bottom wave
      expect(find.byType(LightBlueWaveDecoration), findsOneWidget);

      // 7. Verified no illustrations, photos, emojis
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Validates email and calls requestPasswordReset API', (
      WidgetTester tester,
    ) async {
      String? navigatedEmail;

      await tester.pumpWidget(
        wrapWidget(
          ForgotPasswordScreen(authService: mockAuthService),
          routes: {
            '/check-email': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              navigatedEmail = args?['email'] as String?;
              return const Scaffold(body: Text('Reset Email Sent Screen'));
            },
          },
        ),
      );

      // Empty submission
      await tester.tap(find.byKey(const Key('send_reset_link_button')));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);
      expect(mockAuthService.requestedEmail, isNull);

      // Valid submission
      await tester.enterText(
        find.byKey(const Key('forgot_email_field')),
        'traveler@ceylongo.com',
      );
      await tester.tap(find.byKey(const Key('send_reset_link_button')));
      await tester.pumpAndSettle();

      expect(mockAuthService.requestedEmail, 'traveler@ceylongo.com');
      expect(navigatedEmail, 'traveler@ceylongo.com');
      expect(find.text('Reset Email Sent Screen'), findsOneWidget);
    });

    testWidgets('Shows honest backend error when API is not configured', (
      WidgetTester tester,
    ) async {
      mockAuthService.shouldSucceed = false;

      await tester.pumpWidget(
        wrapWidget(ForgotPasswordScreen(authService: mockAuthService)),
      );

      await tester.enterText(
        find.byKey(const Key('forgot_email_field')),
        'traveler@ceylongo.com',
      );
      await tester.tap(find.byKey(const Key('send_reset_link_button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Password reset is not yet supported'),
        findsOneWidget,
      );
      // Did NOT navigate to /check-email
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets(
      'Fits Samsung Galaxy A22 (360x800) with zero scrolling when keyboard closed',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWidget(ForgotPasswordScreen(authService: mockAuthService)),
        );
        await tester.pumpAndSettle();

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
      'Fits Samsung Galaxy A22 SafeArea insets (360x728) without scrolling',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 728);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWidget(ForgotPasswordScreen(authService: mockAuthService)),
        );
        await tester.pumpAndSettle();

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
      'Enables smooth scrolling when keyboard opens or screen is constrained',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 420);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWidget(ForgotPasswordScreen(authService: mockAuthService)),
        );
        await tester.pumpAndSettle();

        final scrollableFinder = find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        );
        final scrollableState = tester.state<ScrollableState>(
          scrollableFinder.first,
        );
        expect(scrollableState.position.maxScrollExtent, greaterThan(0.0));
      },
    );
  });

  group('Screen 2: Reset Email Sent Screen Tests', () {
    testWidgets('Renders all required elements matching reference design', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapWidget(const CheckEmailScreen()));

      // 1. Heading and Subtitle
      expect(find.text('Reset Email Sent!'), findsOneWidget);
      expect(
        find.text(
          "We've sent a password reset link to your email address. Please check your inbox.",
        ),
        findsOneWidget,
      );

      // 2. Full-width blue gradient "Back to Sign In →" button
      expect(find.byKey(const Key('back_to_signin_button')), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // 3. Light-blue bottom wave
      expect(find.byType(LightBlueWaveDecoration), findsOneWidget);

      // 4. Verified no illustrations, emojis, or paper planes
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsNothing);
      expect(find.byIcon(Icons.outgoing_mail), findsNothing);
    });

    testWidgets('Back to Sign In button navigates to LoginScreen', (
      WidgetTester tester,
    ) async {
      bool loginNavigated = false;

      await tester.pumpWidget(
        wrapWidget(
          const CheckEmailScreen(),
          routes: {
            '/login': (context) {
              loginNavigated = true;
              return const Scaffold(body: Text('Login Screen Mock'));
            },
          },
        ),
      );

      await tester.tap(find.byKey(const Key('back_to_signin_button')));
      await tester.pumpAndSettle();

      expect(loginNavigated, isTrue);
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets(
      'Fits Samsung Galaxy A22 (360x800 and 360x728) without scrolling',
      (WidgetTester tester) async {
        for (final height in [800.0, 728.0]) {
          tester.view.physicalSize = Size(360, height);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(wrapWidget(const CheckEmailScreen()));
          await tester.pumpAndSettle();

          final scrollableFinder = find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          );
          final scrollableState = tester.state<ScrollableState>(
            scrollableFinder.first,
          );
          expect(scrollableState.position.maxScrollExtent, equals(0.0));
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });

  group('Screen 3: Account Created Screen Tests', () {
    const testUser = UserModel(
      id: 'usr-301',
      fullName: 'Anura Kumara',
      email: 'anura@ceylongo.com',
      role: 'tourist',
    );

    testWidgets('Renders all required elements matching reference design', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapWidget(const RegistrationSuccessScreen(user: testUser)),
      );

      // 1. Heading and Subtitle
      expect(find.text('Account Created!'), findsOneWidget);
      expect(
        find.text('Your CeylonGo account has been created successfully.'),
        findsOneWidget,
      );

      // 2. Full-width blue gradient "Continue to Home →" button
      expect(find.byKey(const Key('continue_to_home_button')), findsOneWidget);
      expect(find.text('Continue to Home'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      // 3. Light-blue bottom wave
      expect(find.byType(LightBlueWaveDecoration), findsOneWidget);

      // 4. Verified no success icons, checkmarks, avatars, user cards
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets(
      'Continue to Home button preserves auth flow and navigates to Login with email',
      (WidgetTester tester) async {
        String? prefilledEmail;

        await tester.pumpWidget(
          wrapWidget(
            const RegistrationSuccessScreen(user: testUser),
            routes: {
              '/login': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                prefilledEmail = args?['email'] as String?;
                return const Scaffold(body: Text('Login Screen Mock'));
              },
            },
          ),
        );

        await tester.tap(find.byKey(const Key('continue_to_home_button')));
        await tester.pumpAndSettle();

        expect(prefilledEmail, 'anura@ceylongo.com');
        expect(find.text('Login Screen Mock'), findsOneWidget);
      },
    );

    testWidgets(
      'Fits Samsung Galaxy A22 (360x800 and 360x728) without scrolling',
      (WidgetTester tester) async {
        for (final height in [800.0, 728.0]) {
          tester.view.physicalSize = Size(360, height);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            wrapWidget(const RegistrationSuccessScreen(user: testUser)),
          );
          await tester.pumpAndSettle();

          final scrollableFinder = find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          );
          final scrollableState = tester.state<ScrollableState>(
            scrollableFinder.first,
          );
          expect(scrollableState.position.maxScrollExtent, equals(0.0));
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
