import 'package:flutter/material.dart';

import 'core/services/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/models/api_error.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const CeylonGoApp());
}

/// CeylonGo Root Application
/// Supports dependency injection for testing authentication and storage
class CeylonGoApp extends StatelessWidget {
  final AuthService? authService;
  final SecureStorageService? storageService;
  final String? initialRoute;

  const CeylonGoApp({
    super.key,
    this.authService,
    this.storageService,
    this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CeylonGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialRoute != null
          ? null
          : AuthGate(authService: authService, storageService: storageService),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(
          authService: authService,
          storageService: storageService,
        ),
        '/register': (context) => RegisterScreen(authService: authService),
        '/home': (context) => HomeScreen(
          authService: authService,
          storageService: storageService,
        ),
      },
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
        return LoginScreen(
          authService: _authService,
          storageService: _storageService,
        );

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
