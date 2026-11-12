import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ceylongo/features/auth/models/api_error.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';

void main() {
  group('AuthService - Registration Tests (Section 4.1)', () {
    test('1. Register HTTP 201 returns exact message and UserModel', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/register');
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

      final authService = AuthService(client: client);
      final response = await authService.register(
        fullName: '  Test Traveler  ',
        email: '  traveler@example.com  ',
        password: 'ExamplePassword123',
      );

      expect(
        response.message,
        equals('Account created successfully. Please sign in.'),
      );
      expect(response.user.id, equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(response.user.fullName, equals('Test Traveler'));
      expect(response.user.email, equals('traveler@example.com'));
      expect(response.user.role, equals('traveler'));
    });

    test(
      '2. Register payload sends strictly full_name, email, and password',
      () async {
        final client = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.keys.toSet(), equals({'full_name', 'email', 'password'}));
          expect(body['full_name'], equals('Test Traveler'));
          expect(body['email'], equals('traveler@example.com'));
          expect(body['password'], equals('ExamplePassword123'));
          // confirm_password, accept_terms, and role must never be sent
          expect(body.containsKey('confirm_password'), isFalse);
          expect(body.containsKey('accept_terms'), isFalse);
          expect(body.containsKey('role'), isFalse);

          return http.Response(
            jsonEncode({
              'message': 'Account created successfully. Please sign in.',
              'user': {
                'id': 'user-1',
                'full_name': 'Test Traveler',
                'email': 'traveler@example.com',
                'role': 'traveler',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        });

        final authService = AuthService(client: client);
        await authService.register(
          fullName: 'Test Traveler',
          email: 'traveler@example.com',
          password: 'ExamplePassword123',
        );
      },
    );

    test('3. Duplicate email HTTP 409 maps to EMAIL_ALREADY_EXISTS', () async {
      final client = MockClient((request) async {
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

      final authService = AuthService(client: client);

      expect(
        () => authService.register(
          fullName: 'Test Traveler',
          email: 'duplicate@example.com',
          password: 'ExamplePassword123',
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.code, 'code', 'EMAIL_ALREADY_EXISTS')
              .having(
                (e) => e.message,
                'message',
                'An account with this email already exists.',
              )
              .having(
                (e) => e.fields['email'],
                'fields.email',
                'Email is already registered.',
              ),
        ),
      );
    });

    test('4. Invalid registration HTTP 400 maps to VALIDATION_ERROR and field errors', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Invalid submitted values.',
              'fields': {
                'email': 'Enter a valid email address.',
                'password': 'Password must be at least 8 characters.',
              },
            },
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: client);

      expect(
        () => authService.register(
          fullName: 'Test Traveler',
          email: 'invalid-email',
          password: 'short',
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.code, 'code', 'VALIDATION_ERROR')
              .having(
                (e) => e.fields['email'],
                'fields.email',
                'Enter a valid email address.',
              )
              .having(
                (e) => e.fields['password'],
                'fields.password',
                'Password must be at least 8 characters.',
              ),
        ),
      );
    });
  });

  group('AuthService - Login Tests (Section 4.2)', () {
    test(
      '5. Login HTTP 200 parses access_token, token_type, expires_in and user',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/api/v1/auth/login');
          final body = jsonDecode(request.body);
          expect(body['email'], 'traveler@example.com');
          expect(
            body['password'],
            'ExamplePassword123',
          ); // Password never trimmed

          return http.Response(
            jsonEncode({
              'access_token': 'jwt_bearer_token_string',
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

        final authService = AuthService(client: client);
        final response = await authService.login(
          email: 'traveler@example.com',
          password: 'ExamplePassword123',
        );

        expect(response.accessToken, equals('jwt_bearer_token_string'));
        expect(response.tokenType, equals('bearer'));
        expect(response.expiresIn, equals(3600));
        expect(response.user.fullName, equals('Test Traveler'));
        expect(response.user.email, equals('traveler@example.com'));
        expect(response.user.role, equals('traveler'));
      },
    );

    test('6. Wrong credentials HTTP 401 maps to INVALID_CREDENTIALS', () async {
      final client = MockClient((request) async {
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

      final authService = AuthService(client: client);

      expect(
        () => authService.login(
          email: 'traveler@example.com',
          password: 'WrongPassword123',
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')
              .having(
                (e) => e.message,
                'message',
                'Invalid email or password.',
              ),
        ),
      );
    });
  });

  group('AuthService - Current User Tests (Section 4.3)', () {
    test('7. GET /api/v1/auth/me sends Authorization: Bearer token', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/me');
        expect(
          request.headers['authorization'],
          equals('Bearer my_secret_token_123'),
        );

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

      final authService = AuthService(client: client);
      final user = await authService.getMe('my_secret_token_123');

      expect(user.id, equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(user.fullName, equals('Test Traveler'));
      expect(user.email, equals('traveler@example.com'));
      expect(user.role, equals('traveler'));
    });

    test('8. /me HTTP 401 maps to UNAUTHORIZED', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Missing, expired or invalid token.',
              'fields': {},
            },
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: client);

      expect(
        () => authService.getMe('expired_token'),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.code, 'code', 'UNAUTHORIZED')
              .having(
                (e) => e.message,
                'message',
                'Missing, expired or invalid token.',
              ),
        ),
      );
    });
  });

  group('AuthService - Shared Error Envelope & Network Resilience (Section 4.4)', () {
    test('9. HTTP 429 maps to RATE_LIMITED', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'RATE_LIMITED',
              'message': 'Too many attempts. Please try again later.',
              'fields': {},
            },
          }),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: client);

      expect(
        () => authService.login(
          email: 'traveler@example.com',
          password: 'Password123',
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.code, 'code', 'RATE_LIMITED')
              .having(
                (e) => e.message,
                'message',
                'Too many attempts. Please try again later.',
              ),
        ),
      );
    });

    test('10. HTTP 500 maps to INTERNAL_ERROR', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'INTERNAL_ERROR',
              'message': 'An unexpected error occurred.',
              'fields': {},
            },
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = AuthService(client: client);

      expect(
        () => authService.login(
          email: 'traveler@example.com',
          password: 'Password123',
        ),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.code, 'code', 'INTERNAL_ERROR'),
        ),
      );
    });

    test(
      '11. Network errors and timeouts return safe error messages',
      () async {
        // Test SocketException
        final clientOffline = MockClient((request) async {
          throw const SocketException('Connection refused');
        });
        final authOffline = AuthService(client: clientOffline);

        expect(
          () => authOffline.login(
            email: 'traveler@example.com',
            password: 'Password123',
          ),
          throwsA(
            isA<ApiError>()
                .having((e) => e.code, 'code', 'NETWORK_ERROR')
                .having(
                  (e) => e.message,
                  'message',
                  'Unable to connect to CeylonGo server. Please check your connection.',
                ),
          ),
        );

        // Test Request Timeout
        final clientTimeout = MockClient((request) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response('{}', 200);
        });
        final authTimeout = AuthService(
          client: clientTimeout,
          timeoutDuration: const Duration(milliseconds: 10),
        );

        expect(
          () => authTimeout.login(
            email: 'traveler@example.com',
            password: 'Password123',
          ),
          throwsA(
            isA<ApiError>()
                .having((e) => e.code, 'code', 'TIMEOUT')
                .having(
                  (e) => e.message,
                  'message',
                  'Connection timed out. The server took too long to respond.',
                ),
          ),
        );
      },
    );

    test(
      '12. Invalid response data is handled without exposing raw exceptions',
      () async {
        // Test non-JSON HTML or empty response
        final clientHtml = MockClient((request) async {
          return http.Response(
            '<html><body>502 Bad Gateway</body></html>',
            502,
          );
        });
        final authHtml = AuthService(client: clientHtml);

        expect(
          () => authHtml.login(
            email: 'traveler@example.com',
            password: 'Password123',
          ),
          throwsA(
            isA<ApiError>()
                .having((e) => e.statusCode, 'statusCode', 502)
                .having((e) => e.code, 'code', 'INTERNAL_ERROR'),
          ),
        );

        // Test response missing required user object
        final clientMissingUser = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'access_token': 'token_abc',
              'token_type': 'bearer',
              'expires_in': 3600,
              // missing 'user'
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final authMissingUser = AuthService(client: clientMissingUser);

        expect(
          () => authMissingUser.login(
            email: 'traveler@example.com',
            password: 'Password123',
          ),
          throwsA(isA<ApiError>()),
        );
      },
    );
  });
}
