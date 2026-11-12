import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/core/utils/validators.dart';
import 'package:ceylongo/features/auth/models/user_model.dart';
import 'package:ceylongo/features/auth/screens/login_screen.dart';
import 'package:ceylongo/features/auth/screens/register_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/main.dart';

import 'secure_storage_service_test.dart';

void main() {
  group('App Startup & Session Restoration Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStorageService storageService;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      storageService = SecureStorageService(storage: fakeStorage);
    });

    testWidgets('No saved token opens LoginScreen', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 404);
      });
      final authService = AuthService(client: mockClient);

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storageService),
      );
      await tester.pumpAndSettle();

      // Should render LoginScreen
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Valid saved token and mocked /me HTTP 200 open HomeScreen', (
      WidgetTester tester,
    ) async {
      await storageService.saveToken('valid_jwt_token');

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/me');
        expect(request.headers['authorization'], 'Bearer valid_jwt_token');

        return http.Response(
          jsonEncode({
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'full_name': 'Test Traveler',
            'email': 'traveler@example.com',
            'role': 'traveler',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final authService = AuthService(client: mockClient);

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storageService),
      );
      await tester.pumpAndSettle();

      // Should validate token and navigate to HomeScreen
      expect(find.text('Welcome, Test Traveler!'), findsOneWidget);
      expect(find.text('TRAVELER'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Mocked /me HTTP 401 clears token and opens LoginScreen', (
      WidgetTester tester,
    ) async {
      await storageService.saveToken('expired_jwt_token');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Token expired or invalid.',
              'fields': {},
            },
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      final authService = AuthService(client: mockClient);

      await tester.pumpWidget(
        CeylonGoApp(authService: authService, storageService: storageService),
      );
      await tester.pumpAndSettle();

      // Should clear token and render LoginScreen
      expect(await storageService.getToken(), isNull);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets(
      'Network failure preserves stored token and does not open HomeScreen',
      (WidgetTester tester) async {
        await storageService.saveToken('existing_token_xyz');

        final mockClient = MockClient((request) async {
          throw http.ClientException('Network unreachable');
        });
        final authService = AuthService(client: mockClient);

        await tester.pumpWidget(
          CeylonGoApp(authService: authService, storageService: storageService),
        );
        await tester.pumpAndSettle();

        // Token must NOT be deleted
        expect(await storageService.getToken(), equals('existing_token_xyz'));

        // HomeScreen must NOT be opened
        expect(find.text('Welcome, Test Traveler!'), findsNothing);
        expect(find.text('Connection Issue'), findsOneWidget);
        expect(find.text('Retry Connection'), findsOneWidget);
      },
    );
  });

  group('LoginScreen UI & API Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStorageService storageService;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      storageService = SecureStorageService(storage: fakeStorage);
    });

    testWidgets('Initial UI elements smoke test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(storageService: storageService)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.bySemanticsLabel('CeylonGo Logo'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Forgot password shows coming soon notification', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: LoginScreen(storageService: storageService)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      await tester.pump();

      expect(find.text('Password reset is coming soon'), findsOneWidget);
    });

    testWidgets('Client-side validation blocks API call on empty fields', (
      WidgetTester tester,
    ) async {
      bool apiCalled = false;
      final mockClient = MockClient((request) async {
        apiCalled = true;
        return http.Response('{}', 200);
      });

      final authService = AuthService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(
            authService: authService,
            storageService: storageService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(apiCalled, isFalse);
    });

    testWidgets(
      'Successful Login (200) saves token and navigates to HomeScreen',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/login');
          final body = jsonDecode(request.body);
          expect(body['email'], 'traveler@example.com');
          expect(body['password'], 'ValidPass123');

          return http.Response(
            jsonEncode({
              'access_token': 'jwt_access_token_xyz',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': '550e8400-e29b-41d4-a716-446655440000',
                'full_name': 'Test Traveler',
                'email': 'traveler@example.com',
                'role': 'traveler',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final authService = AuthService(client: mockClient);

        await tester.pumpWidget(
          CeylonGoApp(
            initialRoute: '/login',
            authService: authService,
            storageService: storageService,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'name@example.com'),
          'traveler@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '••••••••'),
          'ValidPass123',
        );

        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Verify token is saved
        expect(await storageService.getToken(), equals('jwt_access_token_xyz'));

        // Verify navigated to HomeScreen
        expect(find.text('Welcome, Test Traveler!'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);
      },
    );

    testWidgets(
      'Failed Login (401 INVALID_CREDENTIALS) displays error banner',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'INVALID_CREDENTIALS',
                'message': 'Invalid email or password.',
                'fields': {},
              },
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        });

        final authService = AuthService(client: mockClient);

        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(
              authService: authService,
              storageService: storageService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'name@example.com'),
          'traveler@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '••••••••'),
          'WrongPassword123',
        );

        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid email or password.'), findsOneWidget);
        expect(await storageService.getToken(), isNull);
      },
    );
  });

  group('HomeScreen & Logout Tests', () {
    late FakeFlutterSecureStorage fakeStorage;
    late SecureStorageService storageService;

    setUp(() {
      fakeStorage = FakeFlutterSecureStorage();
      storageService = SecureStorageService(storage: fakeStorage);
    });

    testWidgets(
      'Logout clears authentication data and returns to LoginScreen',
      (WidgetTester tester) async {
        await storageService.saveToken('token_to_clear');
        await storageService.saveUser(
          const UserModel(
            id: 'user-id',
            fullName: 'Test Traveler',
            email: 'traveler@example.com',
            role: 'traveler',
          ),
        );

        final authService = AuthService();

        await tester.pumpWidget(
          CeylonGoApp(
            initialRoute: '/home',
            authService: authService,
            storageService: storageService,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome, Test Traveler!'), findsOneWidget);
        expect(find.text('Sign Out'), findsOneWidget);

        // Tap Sign Out
        await tester.tap(find.text('Sign Out'));
        await tester.pumpAndSettle();

        // Verify token and user are deleted
        expect(await storageService.getToken(), isNull);
        expect(await storageService.getUser(), isNull);

        // Verify LoginScreen is shown
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      },
    );
  });

  group('RegisterScreen UI & API Tests', () {
    testWidgets(
      'Successful Registration (201) displays message and pops screen',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/register');
          final body = jsonDecode(request.body);
          expect(body['full_name'], 'Test Traveler');
          expect(body['email'], 'traveler@example.com');
          expect(body['password'], 'ValidPass123');
          expect(body.containsKey('confirm_password'), isFalse);
          expect(body.containsKey('accept_terms'), isFalse);

          return http.Response(
            jsonEncode({
              'message': 'Account created successfully. Please sign in.',
              'user': {
                'id': '550e8400-e29b-41d4-a716-446655440000',
                'full_name': 'Test Traveler',
                'email': 'traveler@example.com',
                'role': 'traveler',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        });

        final authService = AuthService(client: mockClient);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) =>
                            RegisterScreen(authService: authService),
                      ),
                    );
                  },
                  child: const Text('Go to Register'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Go to Register'));
        await tester.pumpAndSettle();

        expect(find.text('Create Traveler Account'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'e.g. Test Traveler'),
          'Test Traveler',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'name@example.com'),
          'traveler@example.com',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'At least 8 chars (upper, lower, digit)',
          ),
          'ValidPass123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Re-enter your password'),
          'ValidPass123',
        );

        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        final createBtn = find.text('Create Account');
        await tester.ensureVisible(createBtn);
        await tester.tap(createBtn);
        await tester.pumpAndSettle();

        expect(find.text('Create Traveler Account'), findsNothing);
        expect(
          find.text('Account created successfully. Please sign in.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Duplicate Email Registration (409) displays field error', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'EMAIL_ALREADY_EXISTS',
              'message': 'An account with this email already exists.',
              'fields': {'email': 'Email is already registered.'},
            },
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(authService: authService)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Test Traveler'),
        'Test Traveler',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'duplicate@example.com',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'At least 8 chars (upper, lower, digit)',
        ),
        'ValidPass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Re-enter your password'),
        'ValidPass123',
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final createBtn = find.text('Create Account');
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('An account with this email already exists.'),
        findsOneWidget,
      );
      expect(find.text('Email is already registered.'), findsOneWidget);
    });
  });

  group('Section 3 Exact Validator Unit Tests', () {
    test('Full Name validation rules', () {
      expect(FormValidators.validateFullName(''), 'Full name is required');
      expect(FormValidators.validateFullName('   '), 'Full name is required');
      expect(
        FormValidators.validateFullName('A'),
        'Full name must be between 2 and 100 characters',
      );
      expect(FormValidators.validateFullName('John Doe'), isNull);
    });

    test('Email validation rules', () {
      expect(FormValidators.validateEmail(''), 'Email is required');
      expect(
        FormValidators.validateEmail('invalid-email'),
        'Please enter a valid email address',
      );
      expect(
        FormValidators.validateEmail('traveler@'),
        'Please enter a valid email address',
      );
      expect(FormValidators.validateEmail('traveler@example.com'), isNull);
    });

    test('Password validation rules', () {
      expect(FormValidators.validatePassword(''), 'Password is required');
      expect(
        FormValidators.validatePassword('Short1'),
        'Password must be between 8 and 128 characters',
      );
      expect(
        FormValidators.validatePassword('nouppercase1'),
        'Password must contain at least one uppercase letter',
      );
      expect(
        FormValidators.validatePassword('NOLOWERCASE1'),
        'Password must contain at least one lowercase letter',
      );
      expect(
        FormValidators.validatePassword('NoDigitsHere'),
        'Password must contain at least one digit',
      );
      expect(FormValidators.validatePassword('ValidPass123'), isNull);
    });

    test('Confirm Password validation rules', () {
      expect(
        FormValidators.validateConfirmPassword('', 'ValidPass123'),
        'Please confirm your password',
      );
      expect(
        FormValidators.validateConfirmPassword('Different123', 'ValidPass123'),
        'Passwords do not match',
      );
      expect(
        FormValidators.validateConfirmPassword('ValidPass123', 'ValidPass123'),
        isNull,
      );
    });
  });
}
