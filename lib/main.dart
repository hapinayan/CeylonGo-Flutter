import 'package:flutter/material.dart';

import 'core/services/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/models/api_error.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/screens/auth_landing_screen.dart';
import 'features/auth/screens/check_email_screen.dart';
import 'features/auth/screens/create_new_password_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/login_success_screen.dart';
import 'features/auth/screens/password_reset_success_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/registration_success_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const CeylonGoApp());
}

/// CeylonGo Root Application
/// Supports dependency injection for testing authentication and storage
class CeylonGoApp extends StatefulWidget {
  final AuthService? authService;
  final SecureStorageService? storageService;
  final String? initialRoute;
  final GlobalKey<NavigatorState>? navigatorKey;

  const CeylonGoApp({
    super.key,
    this.authService,
    this.storageService,
    this.initialRoute,
    this.navigatorKey,
  });

  /// Evaluates whether a given URI is a CeylonGo password reset request.
  /// Handles:
  /// - Custom scheme with host: ceylongo://create-new-password?token=...
  /// - Custom scheme with path: ceylongo:///create-new-password?token=...
  /// - Relative path: /create-new-password?token=... or create-new-password?token=...
  /// - Fallback path: /?token=... (when Flutter framework strips host on Android pushRouteInformation)
  static bool isPasswordResetUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (scheme == 'ceylongo') {
      if (host == 'create-new-password' ||
          path == '/create-new-password' ||
          path == 'create-new-password') {
        return true;
      }
    }

    if (scheme.isEmpty) {
      if (path == '/create-new-password' || path == 'create-new-password') {
        return true;
      }
      if (path == '/' && uri.queryParameters.containsKey('token')) {
        return true;
      }
    }

    return false;
  }

  /// Extracts the reset token from query parameters safely.
  static String? extractTokenFromUri(Uri uri) {
    final token = uri.queryParameters['token'];
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return null;
  }

  /// Static routes table for constant-named routes without parameters
  static Map<String, WidgetBuilder> getRoutes({
    AuthService? authService,
    SecureStorageService? storageService,
  }) {
    return {
      '/auth': (context) => const AuthLandingScreen(),
      '/login': (context) => LoginScreen(
            authService: authService,
            storageService: storageService,
          ),
      '/register': (context) => RegisterScreen(authService: authService),
      '/registration-success': (context) => const RegistrationSuccessScreen(),
      '/login-success': (context) => const LoginSuccessScreen(),
      '/forgot-password': (context) =>
          ForgotPasswordScreen(authService: authService),
      '/check-email': (context) => const CheckEmailScreen(),
      '/create-new-password': (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final token = args?['token'] as String?;
        return CreateNewPasswordScreen(
          authService: authService,
          resetToken: token,
        );
      },
      '/password-reset-success': (context) =>
          const PasswordResetSuccessScreen(),
      '/home': (context) => HomeScreen(
            authService: authService,
            storageService: storageService,
          ),
    };
  }

  /// Parses deep link URIs and dynamic route paths.
  /// Supports:
  /// - ceylongo://create-new-password?token=...
  /// - ceylongo:///create-new-password?token=...
  /// - /create-new-password?token=...
  /// - /create-new-password
  /// - /?token=...
  static Route<dynamic>? parseRoute(
    RouteSettings settings, {
    AuthService? authService,
  }) {
    final rawName = settings.name;
    if (rawName == null || rawName.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(rawName);
    if (uri == null) {
      return null;
    }

    if (isPasswordResetUri(uri)) {
      var token = extractTokenFromUri(uri);

      // If token not present in query, check route arguments
      if (token == null && settings.arguments is Map) {
        final map = settings.arguments as Map;
        final argToken = map['token'] as String?;
        if (argToken != null && argToken.trim().isNotEmpty) {
          token = argToken.trim();
        }
      }

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => CreateNewPasswordScreen(
          authService: authService,
          resetToken: token,
        ),
      );
    }

    return null;
  }

  @override
  State<CeylonGoApp> createState() => _CeylonGoAppState();
}

class _CeylonGoAppState extends State<CeylonGoApp> with WidgetsBindingObserver {
  late GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant CeylonGoApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigatorKey != null &&
        widget.navigatorKey != oldWidget.navigatorKey) {
      _navigatorKey = widget.navigatorKey!;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(
      RouteInformation routeInformation) async {
    return _handleIncomingUri(routeInformation.uri);
  }

  @override
  Future<bool> didPushRoute(String route) async {
    final uri = Uri.tryParse(route);
    if (uri != null) {
      return _handleIncomingUri(uri);
    }
    return false;
  }

  bool _handleIncomingUri(Uri uri) {
    if (!CeylonGoApp.isPasswordResetUri(uri)) {
      return false;
    }

    final cleanToken = CeylonGoApp.extractTokenFromUri(uri);
    final nav = _navigatorKey.currentState;
    if (nav != null) {
      // Pop any active CreateNewPasswordScreen or intermediate modal so the new token
      // reliably mounts with fresh state and without dead duplicated back stacks.
      nav.pushNamedAndRemoveUntil(
        '/create-new-password',
        (route) =>
            route.settings.name == '/login' ||
            route.settings.name == '/auth' ||
            route.isFirst,
        arguments: {'token': cleanToken},
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final staticRoutes = CeylonGoApp.getRoutes(
      authService: widget.authService,
      storageService: widget.storageService,
    );

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CeylonGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: widget.initialRoute,
      onGenerateInitialRoutes: (initialRouteName) {
        // Handle deep link / dynamic route on cold start
        final dynamicRoute = CeylonGoApp.parseRoute(
          RouteSettings(name: initialRouteName),
          authService: widget.authService,
        );
        if (dynamicRoute != null) {
          // If opened via cold-start deep link, anchor with LoginScreen underneath
          // so user can navigate back to login instead of exiting.
          return [
            MaterialPageRoute(
              settings: const RouteSettings(name: '/login'),
              builder: (context) => LoginScreen(
                authService: widget.authService,
                storageService: widget.storageService,
              ),
            ),
            dynamicRoute,
          ];
        }

        // Match against known static routes (e.g. during testing with initialRoute)
        final staticBuilder = staticRoutes[initialRouteName];
        if (staticBuilder != null) {
          return [
            MaterialPageRoute(
              settings: RouteSettings(name: initialRouteName),
              builder: staticBuilder,
            ),
          ];
        }

        // Default app entry point: Session verification gate
        return [
          MaterialPageRoute(
            settings: const RouteSettings(name: '/'),
            builder: (context) => AuthGate(
              authService: widget.authService,
              storageService: widget.storageService,
            ),
          ),
        ];
      },
      onGenerateRoute: (settings) {
        return CeylonGoApp.parseRoute(
          settings,
          authService: widget.authService,
        );
      },
      routes: staticRoutes,
    );
  }
}

/// Authentication Gate Widget
/// Handles app startup session restoration and JWT validation per Section 7
class AuthGate extends StatefulWidget {
  final AuthService? authService;
  final SecureStorageService? storageService;

  const AuthGate({super.key, this.authService, this.storageService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

enum AuthStatus { checking, authenticated, unauthenticated, networkError }

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  late final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.checking;
  UserModel? _authenticatedUser;
  String? _networkErrorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _storageService = widget.storageService ?? SecureStorageService();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() {
      _status = AuthStatus.checking;
      _networkErrorMessage = null;
    });

    try {
      final token = await _storageService.getToken();

      // If no token exists, immediately show LoginScreen
      if (token == null || token.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _status = AuthStatus.unauthenticated;
          });
        }
        return;
      }

      // If token exists, validate it using GET /api/v1/auth/me
      final user = await _authService.getMe(token);

      // Save verified user profile
      await _storageService.saveUser(user);

      if (mounted) {
        setState(() {
          _authenticatedUser = user;
          _status = AuthStatus.authenticated;
        });
      }
    } on ApiError catch (e) {
      if (e.statusCode == 401) {
        // HTTP 401: Token invalid or expired. Clear storage and show LoginScreen
        await _storageService.clear();
        if (mounted) {
          setState(() {
            _status = AuthStatus.unauthenticated;
          });
        }
      } else if (e.code == 'NETWORK_ERROR' ||
          e.code == 'TIMEOUT' ||
          e.statusCode == 0) {
        // Network failure / timeout: Do NOT delete token. Show safe retry state
        if (mounted) {
          setState(() {
            _status = AuthStatus.networkError;
            _networkErrorMessage = e.message;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _status = AuthStatus.networkError;
            _networkErrorMessage = e.message;
          });
        }
      }
    } catch (_) {
      await _storageService.clear();
      if (mounted) {
        setState(() {
          _status = AuthStatus.unauthenticated;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AuthStatus.checking:
        return const Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.accentOrange),
          ),
        );

      case AuthStatus.authenticated:
        return HomeScreen(
          initialUser: _authenticatedUser,
          authService: _authService,
          storageService: _storageService,
        );

      case AuthStatus.unauthenticated:
        return const AuthLandingScreen();

      case AuthStatus.networkError:
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 0,
                    color: AppTheme.backgroundWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderSlate),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: AppTheme.primaryNavy,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Connection Issue',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _networkErrorMessage ?? 'Unable to connect to CeylonGo server to verify your session.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _checkSession,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry Connection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: AppTheme.backgroundWhite,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _status = AuthStatus.unauthenticated;
                              });
                            },
                            child: const Text('Go to Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
