import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ceylongo/core/services/secure_storage_service.dart';
import 'package:ceylongo/features/auth/screens/create_new_password_screen.dart';
import 'package:ceylongo/features/auth/screens/login_screen.dart';
import 'package:ceylongo/features/auth/screens/password_reset_success_screen.dart';
import 'package:ceylongo/features/auth/services/auth_service.dart';
import 'package:ceylongo/main.dart';

class MockDeepLinkAuthService extends AuthService {
  String? confirmedToken;
  String? confirmedPassword;
  bool shouldSucceed = true;

  @override
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    confirmedToken = token;
    confirmedPassword = newPassword;
    if (!shouldSucceed) {
      throw Exception('Reset failed');
    }
    return {'message': 'Password has been reset successfully.'};
  }
}

class FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> getToken() async => null;
}

/// Helper function to simulate incoming Android navigation intents through platform channel
Future<void> deliverSystemRouteInformation(
  WidgetTester tester,
  String uriString,
) async {
  final data = SystemChannels.navigation.codec.encodeMethodCall(
    MethodCall('pushRouteInformation', <String, dynamic>{
      'location': uriString,
      'state': null,
    }),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    data,
    (ByteData? reply) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  late MockDeepLinkAuthService mockAuthService;
  late FakeSecureStorageService fakeStorageService;

  setUp(() {
    mockAuthService = MockDeepLinkAuthService();
    fakeStorageService = FakeSecureStorageService();
  });

  group('Deep Link Route Parsing Unit Tests', () {
    test('isPasswordResetUri detects all valid scheme and path formats', () {
      expect(
        CeylonGoApp.isPasswordResetUri(
          Uri.parse('ceylongo://create-new-password?token=abc'),
        ),
        isTrue,
      );
      expect(
        CeylonGoApp.isPasswordResetUri(
          Uri.parse('ceylongo:///create-new-password?token=abc'),
        ),
        isTrue,
      );
      expect(
        CeylonGoApp.isPasswordResetUri(
          Uri.parse('/create-new-password?token=abc'),
        ),
        isTrue,
      );
      expect(
        CeylonGoApp.isPasswordResetUri(
          Uri.parse('create-new-password?token=abc'),
        ),
        isTrue,
      );
      // Fallback path when Android/Flutter strips host
      expect(
        CeylonGoApp.isPasswordResetUri(
          Uri.parse('/?token=abc'),
        ),
        isTrue,
      );

      // Non-password-reset URIs
      expect(
        CeylonGoApp.isPasswordResetUri(Uri.parse('/')),
        isFalse,
      );
      expect(
        CeylonGoApp.isPasswordResetUri(Uri.parse('/login')),
        isFalse,
      );
      expect(
        CeylonGoApp.isPasswordResetUri(Uri.parse('ceylongo://home')),
        isFalse,
      );
      expect(
        CeylonGoApp.isPasswordResetUri(Uri.parse('https://ceylongo.com/other')),
        isFalse,
      );
    });

    test('extractTokenFromUri trims and extracts token safely', () {
      expect(
        CeylonGoApp.extractTokenFromUri(
          Uri.parse('ceylongo://create-new-password?token=valid_token_123'),
        ),
        'valid_token_123',
      );
      expect(
        CeylonGoApp.extractTokenFromUri(
          Uri.parse('ceylongo://create-new-password?token=  spaced_token  '),
        ),
        'spaced_token',
      );
      expect(
        CeylonGoApp.extractTokenFromUri(
          Uri.parse('ceylongo://create-new-password'),
        ),
        isNull,
      );
      expect(
        CeylonGoApp.extractTokenFromUri(
          Uri.parse('ceylongo://create-new-password?token='),
        ),
        isNull,
      );
    });

    testWidgets('Parses custom scheme ceylongo://create-new-password with token',
        (WidgetTester tester) async {
      await tester.pumpWidget(Builder(
        builder: (context) {
          final route = CeylonGoApp.parseRoute(
            const RouteSettings(
              name: 'ceylongo://create-new-password?token=cold_token_123',
            ),
            authService: mockAuthService,
          );

          expect(route, isNotNull);
          expect(route, isA<MaterialPageRoute>());

          final pageRoute = route! as MaterialPageRoute;
          final builtWidget = pageRoute.builder(context);
          expect(builtWidget, isA<CreateNewPasswordScreen>());
          final screen = builtWidget as CreateNewPasswordScreen;
          expect(screen.resetToken, 'cold_token_123');

          return const SizedBox();
        },
      ));
    });

    testWidgets('Parses path-style custom scheme ceylongo:///create-new-password with token',
        (WidgetTester tester) async {
      await tester.pumpWidget(Builder(
        builder: (context) {
          final route = CeylonGoApp.parseRoute(
            const RouteSettings(
              name: 'ceylongo:///create-new-password?token=path_token_456',
            ),
            authService: mockAuthService,
          );

          expect(route, isNotNull);
          final pageRoute = route! as MaterialPageRoute;
          final builtWidget = pageRoute.builder(context);
          expect(builtWidget, isA<CreateNewPasswordScreen>());
          final screen = builtWidget as CreateNewPasswordScreen;
          expect(screen.resetToken, 'path_token_456');

          return const SizedBox();
        },
      ));
    });

    testWidgets('Parses relative path /create-new-password?token=query_token_789',
        (WidgetTester tester) async {
      await tester.pumpWidget(Builder(
        builder: (context) {
          final route = CeylonGoApp.parseRoute(
            const RouteSettings(
              name: '/create-new-password?token=query_token_789',
            ),
            authService: mockAuthService,
          );

          expect(route, isNotNull);
          final pageRoute = route! as MaterialPageRoute;
          final builtWidget = pageRoute.builder(context);
          expect(builtWidget, isA<CreateNewPasswordScreen>());
          final screen = builtWidget as CreateNewPasswordScreen;
          expect(screen.resetToken, 'query_token_789');

          return const SizedBox();
        },
      ));
    });

    testWidgets('Parses fallback route /?token=fallback_123',
        (WidgetTester tester) async {
      await tester.pumpWidget(Builder(
        builder: (context) {
          final route = CeylonGoApp.parseRoute(
            const RouteSettings(
              name: '/?token=fallback_123',
            ),
            authService: mockAuthService,
          );

          expect(route, isNotNull);
          final pageRoute = route! as MaterialPageRoute;
          final builtWidget = pageRoute.builder(context);
          expect(builtWidget, isA<CreateNewPasswordScreen>());
          final screen = builtWidget as CreateNewPasswordScreen;
          expect(screen.resetToken, 'fallback_123');

          return const SizedBox();
        },
      ));
    });

    testWidgets('Parses deep link without token safely',
        (WidgetTester tester) async {
      await tester.pumpWidget(Builder(
        builder: (context) {
          final route = CeylonGoApp.parseRoute(
            const RouteSettings(name: 'ceylongo://create-new-password'),
            authService: mockAuthService,
          );

          expect(route, isNotNull);
          final pageRoute = route! as MaterialPageRoute;
          final builtWidget = pageRoute.builder(context);
          expect(builtWidget, isA<CreateNewPasswordScreen>());
          final screen = builtWidget as CreateNewPasswordScreen;
          expect(screen.resetToken, isNull);

          return const SizedBox();
        },
      ));
    });

    test('Ignores unrelated schemes and routes', () {
      final unrelated1 = CeylonGoApp.parseRoute(
        const RouteSettings(name: 'ceylongo://home'),
        authService: mockAuthService,
      );
      expect(unrelated1, isNull);

      final unrelated2 = CeylonGoApp.parseRoute(
        const RouteSettings(name: 'https://ceylongo.com/other'),
        authService: mockAuthService,
      );
      expect(unrelated2, isNull);

      final unrelated3 = CeylonGoApp.parseRoute(
        const RouteSettings(name: '/login'),
        authService: mockAuthService,
      );
      expect(unrelated3, isNull);

      final emptyRoute = CeylonGoApp.parseRoute(
        const RouteSettings(name: ''),
        authService: mockAuthService,
      );
      expect(emptyRoute, isNull);
    });
  });

  group('Deep Link Widget & Navigation Integration Tests', () {
    testWidgets('Cold start via ceylongo:// opens CreateNewPasswordScreen with prefilled token',
        (WidgetTester tester) async {
      await tester.pumpWidget(CeylonGoApp(
        authService: mockAuthService,
        storageService: fakeStorageService,
        initialRoute: 'ceylongo://create-new-password?token=cold_start_abc',
      ));
      await tester.pumpAndSettle();

      // Verify Create New Password screen is displayed
      expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
      expect(find.text('Create New Password'), findsOneWidget);

      // Verify reset token is prefilled in the text field
      expect(find.text('cold_start_abc'), findsOneWidget);

      // Verify back button is present and navigates back to LoginScreen
      final backButton = find.byKey(const Key('auth_back_button'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Warm start pushes CreateNewPasswordScreen via pushNamed with prefilled token',
        (WidgetTester tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(CeylonGoApp(
        navigatorKey: navKey,
        authService: mockAuthService,
        storageService: fakeStorageService,
        initialRoute: '/login',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Simulate warm-start deep link arrival via pushNamed
      navKey.currentState!.pushNamed(
        'ceylongo://create-new-password?token=warm_start_xyz',
      );
      await tester.pumpAndSettle();

      // Verify Create New Password screen is pushed on top
      expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
      expect(find.text('warm_start_xyz'), findsOneWidget);

      // Verify popping navigates back to original LoginScreen
      final backButton = find.byKey(const Key('auth_back_button'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Warm start via Android system message updates screen with latest token',
        (WidgetTester tester) async {
      await tester.pumpWidget(CeylonGoApp(
        authService: mockAuthService,
        storageService: fakeStorageService,
        initialRoute: '/login',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Deliver warm-start intent through platform channel
      await deliverSystemRouteInformation(
        tester,
        'ceylongo://create-new-password?token=warm_system_123',
      );

      // Verify Create New Password screen is mounted with warm-start token
      expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
      expect(find.text('warm_system_123'), findsOneWidget);
    });

    testWidgets('Consecutive incoming reset links while app is running always update to the latest token',
        (WidgetTester tester) async {
      // 1. Cold start with dummy_test
      await tester.pumpWidget(CeylonGoApp(
        authService: mockAuthService,
        storageService: fakeStorageService,
        initialRoute: 'ceylongo://create-new-password?token=dummy_test',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
      expect(find.text('dummy_test'), findsOneWidget);

      // 2. First warm-start intent arrives with warm_test_123
      await deliverSystemRouteInformation(
        tester,
        'ceylongo://create-new-password?token=warm_test_123',
      );

      // Verify UI has updated to warm_test_123 and dummy_test is gone
      expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
      expect(find.text('dummy_test'), findsNothing);
      expect(find.text('warm_test_123'), findsOneWidget);

      // 3. Second warm-start intent arrives with warm_test_456
      await deliverSystemRouteInformation(
        tester,
        'ceylongo://create-new-password?token=warm_test_456',
      );

      // Verify UI has updated to warm_test_456 and warm_test_123 is gone
      expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
      expect(find.text('warm_test_123'), findsNothing);
      expect(find.text('warm_test_456'), findsOneWidget);

      // 4. Third warm-start intent arrives with stripped fallback /?token=warm_test_789
      await deliverSystemRouteInformation(
        tester,
        '/?token=warm_test_789',
      );

      // Verify UI has updated to warm_test_789
      expect(find.byType(CreateNewPasswordScreen), findsOneWidget);
      expect(find.text('warm_test_456'), findsNothing);
      expect(find.text('warm_test_789'), findsOneWidget);

      // 5. Back navigation cleanly pops to LoginScreen without dead screen accumulation
      final backButton = find.byKey(const Key('auth_back_button'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(CreateNewPasswordScreen), findsNothing);
    });

    testWidgets('Completes password reset flow initiated via deep link',
        (WidgetTester tester) async {
      // Set test viewport size so all fields and button are visible
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(CeylonGoApp(
        authService: mockAuthService,
        storageService: fakeStorageService,
        initialRoute: 'ceylongo://create-new-password?token=valid_token_777',
      ));
      await tester.pumpAndSettle();

      // Token should already be filled from deep link
      expect(find.text('valid_token_777'), findsOneWidget);

      // Fill in new password and confirm password
      final passField = find.byKey(const Key('new_password_field'));
      final confirmField = find.byKey(const Key('confirm_new_password_field'));

      await tester.enterText(passField, 'ValidPassword1!');
      await tester.enterText(confirmField, 'ValidPassword1!');
      await tester.pumpAndSettle();

      // Submit password reset
      final updateBtn = find.byKey(const Key('reset_password_button'));
      expect(updateBtn, findsOneWidget);
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Verify AuthService received the expected token and password
      expect(mockAuthService.confirmedToken, 'valid_token_777');
      expect(mockAuthService.confirmedPassword, 'ValidPassword1!');

      // Verify transition to PasswordResetSuccessScreen
      expect(find.byType(PasswordResetSuccessScreen), findsOneWidget);
      expect(find.text('Password Reset Successful'), findsOneWidget);
    });
  });
}
