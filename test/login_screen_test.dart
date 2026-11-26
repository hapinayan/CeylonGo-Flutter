import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/theme/app_theme.dart';
import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/models/auth_response.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/login_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/features/auth/widgets/auth_header.dart';
import 'package:ceylongo/features/auth/widgets/auth_heading.dart';
import 'package:ceylongo/features/auth/widgets/auth_trust_footer.dart';
import 'package:ceylongo/features/auth/widgets/auth_wave_decoration.dart';

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
      throw const ApiError(
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password.',
      );
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
  group('LoginScreen Approved Blue-Theme UI & Flow Tests', () {
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

    testWidgets('Renders approved CeylonGo blue-and-white Login UI', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(AuthHeader), findsOneWidget);
      expect(find.byType(AuthHeading), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(
        find.text('Sign in to continue your CeylonGo journey'),
        findsOneWidget,
      );
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_link')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Offline Demo Flow'), findsOneWidget);
      expect(
        find.byKey(const Key('offline_demo_login_button')),
        findsOneWidget,
      );
      expect(find.byType(AuthTrustFooter), findsOneWidget);
      expect(find.byType(AuthWaveDecoration), findsOneWidget);
    });

    testWidgets('Validates empty email and password fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(mockAuthService.loggedInEmail, isNull);
      expect(find.byKey(const Key('login_success_popup')), findsNothing);
    });

    testWidgets(
      'Shows 1.5s Login Successful! popup and auto-navigates to /home',
      (WidgetTester tester) async {
        bool homeNavigated = false;
        await tester.pumpWidget(
          createWidgetUnderTest(
            initialEmail: 'traveler@ceylongo.com',
            routes: {
              '/home': (_) {
                homeNavigated = true;
                return const Scaffold(body: Text('Home Screen'));
              },
            },
          ),
        );

        await tester.enterText(
          find.byKey(const Key('login_password_field')),
          'SecurePass1',
        );
        await tester.tap(find.byKey(const Key('login_submit_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byKey(const Key('login_success_popup')), findsOneWidget);
        expect(find.text('Login Successful!'), findsOneWidget);
        expect(find.text('Welcome to CeylonGo'), findsOneWidget);
        expect(homeNavigated, isFalse);

        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pumpAndSettle();

        expect(homeNavigated, isTrue);
        expect(find.text('Home Screen'), findsOneWidget);
      },
    );

    testWidgets('Displays error and no popup on failed login', (
      WidgetTester tester,
    ) async {
      mockAuthService.shouldSucceed = false;
      await tester.pumpWidget(
        createWidgetUnderTest(initialEmail: 'traveler@ceylongo.com'),
      );

      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'WrongPass1',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
      expect(find.byKey(const Key('login_success_popup')), findsNothing);
    });

    testWidgets('Responsive on Samsung Galaxy A22 (360x800) without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });
  });
}
