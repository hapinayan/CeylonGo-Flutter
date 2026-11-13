import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';

/// CeylonGo Traveler Home Screen
/// Conforms to Sections 1, 2, 4 and 7 of Common Development Specification v1.0
class HomeScreen extends StatefulWidget {
  final UserModel? initialUser;
  final AuthService? authService;
  final SecureStorageService? storageService;

  const HomeScreen({
    super.key,
    this.initialUser,
    this.authService,
    this.storageService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService _authService;
  late final SecureStorageService _storageService;

  UserModel? _user;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _storageService = widget.storageService ?? SecureStorageService();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.initialUser != null) {
      if (mounted) {
        setState(() {
          _user = widget.initialUser;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final cachedUser = await _storageService.getUser();
      if (cachedUser != null && mounted) {
        setState(() {
          _user = cachedUser;
          _isLoading = false;
        });
      }

      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        final verifiedUser = await _authService.getMe(token);
        if (mounted) {
          setState(() {
            _user = verifiedUser;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onSignOut() async {
    // Prevent multiple logout clicks and race conditions
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Securely clear access token and user profile
      await _storageService.clear();

      if (mounted) {
        // Clear entire navigation stack and return to Login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign out safely. Please try again.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    // Increased logo size by ~28-30% and shifted ~10-12px downward with proportional toolbar
    final toolbarHeight = isDesktop ? 106.0 : (screenWidth < 360 ? 84.0 : 94.0);
    final logoHeight = isDesktop ? 78.0 : (screenWidth < 360 ? 59.0 : 70.0);
    final logoTopShift = isDesktop ? 12.0 : (screenWidth < 360 ? 10.0 : 11.0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: toolbarHeight,
        automaticallyImplyLeading: false,
        leading: const SizedBox(width: 48),
        leadingWidth: 48,
        title: Padding(
          padding: EdgeInsets.only(top: logoTopShift),
          child: Center(
            child: Image.asset(
              'assets/images/ceylongo_original_logo.jpg',
              height: logoHeight,
              fit: BoxFit.contain,
              semanticLabel: 'CeylonGo Logo',
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryNavy,
                    ),
                  )
                : const Icon(Icons.logout, color: AppTheme.primaryNavy),
            tooltip: 'Sign Out',
            onPressed: _isLoggingOut ? null : _onSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: AppTheme.accentOrange)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.primarySubtle,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 54,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Welcome, ${_user?.fullName ?? "Traveler"}!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_user?.email.isNotEmpty ?? false) ...[
                              Text(
                                _user!.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withAlpha(30),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                (_user?.role ?? 'Traveler').toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.accentOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Divider(color: AppTheme.borderSlate),
                            const SizedBox(height: 16),
                            const Text(
                              'Discover Local. Feel at Home.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: _isLoggingOut ? null : _onSignOut,
                              icon: _isLoggingOut
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.backgroundWhite,
                                      ),
                                    )
                                  : const Icon(Icons.logout),
                              label: const Text('Sign Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryNavy,
                                foregroundColor: AppTheme.backgroundWhite,
                                disabledBackgroundColor: AppTheme.primaryNavy
                                    .withAlpha(150),
                              ),
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
