import 'package:flutter/material.dart';

import 'core/services/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/main_navigation_shell.dart';
import 'features/categories/screens/activities_category_screen.dart';
import 'features/categories/screens/eco_tourism_category_screen.dart';
import 'features/categories/screens/homestays_category_screen.dart';
import 'features/categories/screens/local_guides_category_screen.dart';
import 'features/categories/screens/rentals_category_screen.dart';
import 'features/artisan/screens/artisan_business_detail_screen.dart';
import 'features/artisan/screens/artisan_product_catalog_screen.dart';
import 'features/artisan/screens/artisan_product_detail_screen.dart';
import 'features/artisan/screens/artisan_reservation_form_screen.dart';
import 'features/artisan/screens/artisan_reservation_history_screen.dart';
import 'features/artisan/screens/artisan_wishlist_screen.dart';
import 'features/auth/models/api_error.dart';
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
import 'features/vendor/screens/provider_onboarding_screen.dart';
import 'features/vendor/screens/vendor_about_screen.dart';
import 'features/vendor/screens/vendor_availability_screen.dart';
import 'features/vendor/screens/vendor_bookings_screen.dart';
import 'features/vendor/screens/vendor_dashboard_screen.dart';
import 'features/vendor/screens/vendor_earnings_screen.dart';
import 'features/vendor/screens/vendor_identity_upload_screen.dart';
import 'features/vendor/screens/vendor_listings_screen.dart';
import 'features/vendor/screens/vendor_login_screen.dart';
import 'features/vendor/screens/vendor_more_screen.dart';
import 'features/vendor/screens/vendor_notifications_screen.dart';
import 'features/vendor/screens/vendor_profile_screen.dart';
import 'features/vendor/screens/vendor_register_screen.dart';
import 'features/vendor/screens/vendor_reviews_screen.dart';
import 'features/vendor/screens/vendor_settings_screen.dart';
import 'features/vendor/screens/vendor_support_screen.dart';
import 'features/vendor/services/provider_api_service.dart';
import 'features/vendor/services/vendor_demo_service.dart';
import 'features/map/screens/interactive_map_screen.dart';
import 'features/map/services/map_api_service.dart';
import 'features/weather/screens/live_weather_screen.dart';
import 'features/weather/services/weather_api_service.dart';

void main() {
  runApp(const CeylonGoApp());
}

/// CeylonGo Root Application
/// Supports dependency injection for testing authentication and storage
class CeylonGoApp extends StatefulWidget {
  final AuthService? authService;
  final ProviderApiService? providerService;
  final SecureStorageService? storageService;
  final WeatherApiService? weatherService;
  final MapApiService? mapService;
  final String? initialRoute;
  final GlobalKey<NavigatorState>? navigatorKey;

  const CeylonGoApp({
    super.key,
    this.authService,
    this.providerService,
    this.storageService,
    this.weatherService,
    this.mapService,
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
    ProviderApiService? providerService,
    SecureStorageService? storageService,
    WeatherApiService? weatherService,
    MapApiService? mapService,
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
      '/home': (context) => MainNavigationShell(
            initialIndex: 0,
            authService: authService,
            storageService: storageService,
          ),
      '/artisan': (context) => MainNavigationShell(
            initialIndex: 1,
            authService: authService,
            storageService: storageService,
          ),
      '/artisan/products': (context) => const ArtisanProductCatalogScreen(),
      '/artisan/reservations': (context) =>
          const ArtisanReservationHistoryScreen(),
      '/artisan/wishlist': (context) => const ArtisanWishlistScreen(),
      '/community': (context) => MainNavigationShell(
            initialIndex: 3,
            authService: authService,
            storageService: storageService,
          ),
      '/ai-planner': (context) => MainNavigationShell(
            initialIndex: 2,
            authService: authService,
            storageService: storageService,
          ),
      '/category/homestays': (context) => const HomestaysCategoryScreen(),
      '/category/eco': (context) => const EcoTourismCategoryScreen(),
      '/category/activities': (context) => const ActivitiesCategoryScreen(),
      '/category/guides': (context) => const LocalGuidesCategoryScreen(),
      '/category/rentals': (context) => const RentalsCategoryScreen(),
      '/vendor/login': (context) => VendorLoginScreen(
            authService: authService,
            providerService: providerService,
            storageService: storageService,
          ),
      '/vendor/register': (context) => VendorRegisterScreen(
            storageService: storageService,
          ),
      '/vendor/register/onboarding': (context) =>
          const ProviderOnboardingScreen(),
      '/vendor/register/identity': (context) =>
          const VendorIdentityUploadScreen(),
      '/vendor/dashboard': (context) => const VendorDashboardScreen(),
      '/vendor/listings': (context) => const VendorListingsScreen(),
      '/vendor/bookings': (context) => const VendorBookingsScreen(),
      '/vendor/more': (context) => VendorMoreScreen(
            storageService: storageService,
          ),
      '/vendor/availability': (context) => const VendorAvailabilityScreen(),
      '/vendor/earnings': (context) => const VendorEarningsScreen(),
      '/vendor/reviews': (context) => const VendorReviewsScreen(),
      '/vendor/notifications': (context) => const VendorNotificationsScreen(),
      '/vendor/settings': (context) => VendorSettingsScreen(
            providerService: providerService,
            storageService: storageService,
          ),
      '/vendor/support': (context) => const VendorSupportScreen(),
      '/vendor/about': (context) => const VendorAboutScreen(),
      '/vendor/profile': (context) => VendorProfileScreen(
            providerService: providerService,
            storageService: storageService,
          ),
      '/weather': (context) => LiveWeatherScreen(
            weatherService: weatherService,
          ),
      '/map': (context) => InteractiveMapScreen(
            mapService: mapService,
          ),
      '/profile': (context) => MainNavigationShell(
            initialIndex: 4,
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

    if (uri.path == '/artisan/business' || uri.path == 'artisan/business') {
      int? listingId;
      if (uri.queryParameters.containsKey('id')) {
        listingId = int.tryParse(uri.queryParameters['id']!);
      }
      if (listingId == null && settings.arguments is Map) {
        final map = settings.arguments as Map;
        listingId = map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}');
      }
      if (listingId != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => ArtisanBusinessDetailScreen(listingId: listingId!),
        );
      }
    }

    if (uri.path == '/artisan/product' || uri.path == 'artisan/product') {
      int? productId;
      if (uri.queryParameters.containsKey('id')) {
        productId = int.tryParse(uri.queryParameters['id']!);
      }
      if (productId == null && settings.arguments is Map) {
        final map = settings.arguments as Map;
        productId = map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}');
      }
      if (productId != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => ArtisanProductDetailScreen(productId: productId!),
        );
      }
    }

    if (uri.path == '/artisan/reserve' || uri.path == 'artisan/reserve') {
      int? productId;
      if (uri.queryParameters.containsKey('product_id')) {
        productId = int.tryParse(uri.queryParameters['product_id']!);
      }
      if (productId == null && settings.arguments is Map) {
        final map = settings.arguments as Map;
        productId = map['product_id'] is int
            ? map['product_id'] as int
            : int.tryParse('${map['product_id']}');
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => ArtisanReservationFormScreen(productId: productId),
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
            route.settings.name == '/vendor/login' ||
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
      providerService: widget.providerService,
      storageService: widget.storageService,
      weatherService: widget.weatherService,
      mapService: widget.mapService,
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
              providerService: widget.providerService,
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
/// Handles Vendor-only app startup session restoration and JWT + role validation.
class AuthGate extends StatefulWidget {
  final AuthService? authService;
  final ProviderApiService? providerService;
  final SecureStorageService? storageService;

  const AuthGate({
    super.key,
    this.authService,
    this.providerService,
    this.storageService,
  });

  static bool isVerifiedVendorRole(String? role) {
    final normalized = role?.trim().toLowerCase();
    return normalized == 'provider' || normalized == 'vendor';
  }

  @override
  State<AuthGate> createState() => _AuthGateState();
}

enum AuthStatus { checking, authenticated, unauthenticated, networkError }

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  late final ProviderApiService _providerService;
  late final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.checking;
  String? _networkErrorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _providerService = widget.providerService ?? ProviderApiService();
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

      if (token != null && token.trim().isNotEmpty) {
        // Legacy Traveler demo tokens must never authenticate the Vendor app.
        if (token.startsWith('demo-')) {
          await _storageService.clear();
          if (mounted) {
            setState(() {
              _status = AuthStatus.unauthenticated;
            });
          }
          return;
        }

        // Validate real JWT using GET /api/v1/providers/me (or injected AuthService in tests).
        if (widget.authService != null && widget.providerService == null) {
          final user = await _authService.getMe(token);
          if (!AuthGate.isVerifiedVendorRole(user.role)) {
            await _storageService.clear();
            if (mounted) {
              setState(() {
                _status = AuthStatus.unauthenticated;
              });
            }
            return;
          }

          await _storageService.saveUser(user);
          VendorDemoService.instance.setAuthenticatedVendor(
            id: user.id,
            businessName: user.fullName,
            email: user.email,
          );
        } else {
          final profile = await _providerService.getProfile(token);
          if (!AuthGate.isVerifiedVendorRole(profile.role) ||
              profile.approvalStatus.toLowerCase() != 'approved' ||
              !profile.isActive) {
            await _storageService.clear();
            if (mounted) {
              setState(() {
                _status = AuthStatus.unauthenticated;
              });
            }
            return;
          }

          await _storageService.saveUser(profile.toUserModel());
          VendorDemoService.instance.setAuthenticatedVendor(
            id: profile.userId.toString(),
            businessName: profile.businessName.isNotEmpty
                ? profile.businessName
                : profile.fullName,
            email: profile.email,
          );
        }

        if (mounted) {
          setState(() {
            _status = AuthStatus.authenticated;
          });
        }
        return;
      }

      // Check for a clearly labeled offline Demo Vendor session.
      final demoVendorMap = await _storageService.getVendorDemoSession();
      if (demoVendorMap != null && demoVendorMap['is_demo_session'] == true) {
        VendorDemoService.instance.restoreDemoVendorFromMap(demoVendorMap);
        if (mounted) {
          setState(() {
            _status = AuthStatus.authenticated;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _status = AuthStatus.unauthenticated;
        });
      }
    } on ApiError catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Invalid, expired, or unauthorized token: clear storage and show VendorLoginScreen.
        await _storageService.clear();
        if (mounted) {
          setState(() {
            _status = AuthStatus.unauthenticated;
          });
        }
      } else if (e.code == 'NETWORK_ERROR' ||
          e.code == 'TIMEOUT' ||
          e.statusCode == 0) {
        // Network failure / timeout: preserve token and show safe retry state.
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
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryNavy),
          ),
        );

      case AuthStatus.authenticated:
        return const VendorDashboardScreen();

      case AuthStatus.unauthenticated:
        return VendorLoginScreen(
          authService: widget.authService,
          providerService: widget.providerService,
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
                            _networkErrorMessage ??
                                'Unable to connect to CeylonGo server to verify your vendor session.',
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
                              backgroundColor: AppTheme.primaryNavy,
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
                            child: const Text('Go to Vendor Sign In'),
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
