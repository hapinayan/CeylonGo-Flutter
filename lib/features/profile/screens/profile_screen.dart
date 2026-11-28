import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../bookings/screens/my_bookings_screen.dart';
import '../../bookings/services/booking_payment_service.dart';
import '../../categories/services/discovery_service.dart';
import '../../home/widgets/home_bottom_navigation_bar.dart';
import '../models/traveler_profile_photo_models.dart';
import '../services/traveler_profile_photo_picker.dart';
import '../services/traveler_profile_photo_storage.dart';
import '../widgets/traveler_photo_editor_sheet.dart';
import '../services/account_service.dart';
import '../widgets/notifications_sheet.dart';
import 'account_subscreens.dart';
import 'traveler_wishlist_screen.dart';

/// CeylonGo Traveler Profile Screen
/// Approved Full White Minimal Profile Page Design.
/// Features:
/// 1. Pure Full White Background (#FFFFFF) throughout the entire screen
/// 2. Minimal White Header with Back arrow on the left, Notification & Settings on the right
/// 3. Dark Navy Blue status bar icons & controls (#082B5C) with NO "Profile" title in header
/// 4. Centered Circular Avatar with Navy initials, light-blue outline, and royal-blue edit button
/// 5. Traveler Identity (Name, Email, and "Demo Traveler" badge)
/// 6. Profile Statistics Card (Bookings, Saved, Places Visited)
/// 7. 5 Staggered Profile Menu Cards with press feedback
/// 8. Accessible Soft-Pink Log Out Button with confirmation dialog
/// 9. Reused Floating HomeBottomNavigationBar with Profile tab active
class ProfileScreen extends StatefulWidget {
  final UserModel? initialUser;
  final AuthService? authService;
  final SecureStorageService? storageService;
  final TravelerProfilePhotoStore? photoStore;
  final TravelerProfilePhotoPicker? photoPicker;
  final AccountService? accountService;
  final BookingPaymentService? bookingService;
  final DiscoveryService? discoveryService;
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.initialUser,
    this.authService,
    this.storageService,
    this.photoStore,
    this.photoPicker,
    this.accountService,
    this.bookingService,
    this.discoveryService,
    this.showBottomNav = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late final SecureStorageService _storageService;
  late final TravelerProfilePhotoStore _photoStore;
  late final TravelerProfilePhotoPicker _photoPicker;
  late final AccountService _accountService;
  late final BookingPaymentService _bookingService;
  late final DiscoveryService _discoveryService;
  late final AnimationController _entranceController;

  UserModel? _user;
  TravelerProfilePhotoData? _savedPhoto;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  int _bookingsCount = 0;
  int _savedCount = 0;
  int _visitedCount = 0;
  int _unreadNotifications = 0;

  double _backScale = 1.0;
  double _notifScale = 1.0;
  double _settingsScale = 1.0;
  double _editAvatarScale = 1.0;
  double _logoutScale = 1.0;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _storageService = widget.storageService ?? SecureStorageService();
    _photoStore = widget.photoStore ?? FileTravelerProfilePhotoStore();
    _photoPicker = widget.photoPicker ?? TravelerProfilePhotoPicker();
    _accountService = widget.accountService ?? AccountService(storageService: _storageService);
    _bookingService = widget.bookingService ?? BookingPaymentService();
    _discoveryService = widget.discoveryService ?? DiscoveryService();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadUser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (MediaQuery.of(context).disableAnimations) {
          _entranceController.value = 1.0;
        } else {
          _entranceController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String get _accountKey {
    final user = _user;
    if (user == null || user.role == 'provider') return '';
    if (user.id.trim().isNotEmpty) return user.id.trim();
    if (user.email.trim().isNotEmpty) return user.email.trim().toLowerCase();
    return '';
  }

  Future<void> _loadAvatarForUser() async {
    final key = _accountKey;
    if (!mounted || key.isEmpty) return;
    final loaded = await _photoStore.loadForAccount(key);
    if (!mounted || key != _accountKey) return;
    setState(() {
      _savedPhoto = loaded;
    });
  }

  Future<void> _loadUser() async {
    if (widget.initialUser != null) {
      if (mounted) {
        setState(() {
          _user = widget.initialUser;
          _isLoading = false;
        });
      }
      await _loadAvatarForUser();
      if (!ArtisanDemoService.isDemoMode) {
        await _loadAccountStats();
      }
      return;
    }

    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        if (token.startsWith('demo-') || ArtisanDemoService.isDemoMode) {
          if (mounted) {
            setState(() {
              _user = const UserModel(
                id: 'demo-user-001',
                fullName: 'Kamal Perera',
                email: 'demo@ceylongo.com',
                role: 'traveler',
              );
              _bookingsCount = 3;
              _savedCount = 5;
              _visitedCount = 8;
              _isLoading = false;
            });
          }
          return;
        }

        try {
          final verifiedUser = await _accountService.getProfile();
          if (mounted) {
            setState(() {
              _user = verifiedUser;
              _isLoading = false;
            });
          }
          await _loadAccountStats();
          return;
        } catch (_) {
          try {
            final verifiedUser = await _authService.getMe(token);
            if (mounted) {
              setState(() {
                _user = verifiedUser;
                _isLoading = false;
              });
            }
            await _loadAccountStats();
            return;
          } catch (_) {
            final cachedUser = await _storageService.getUser();
            if (cachedUser != null && mounted) {
              setState(() {
                _user = cachedUser;
                _isLoading = false;
              });
              return;
            }
          }
        }
      }

      if (ArtisanDemoService.isDemoMode) {
        if (mounted) {
          setState(() {
            _user = const UserModel(
              id: 'demo-user-001',
              fullName: 'Kamal Perera',
              email: 'demo@ceylongo.com',
              role: 'traveler',
            );
            _bookingsCount = 3;
            _savedCount = 5;
            _visitedCount = 8;
            _isLoading = false;
          });
        }
        return;
      }

      final cachedUser = await _storageService.getUser();
      if (mounted) {
        setState(() {
          _user = cachedUser;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _user = ArtisanDemoService.isDemoMode
              ? const UserModel(
                  id: 'demo-user-001',
                  fullName: 'Kamal Perera',
                  email: 'demo@ceylongo.com',
                  role: 'traveler',
                )
              : null;
          _isLoading = false;
        });
      }
    } finally {
      await _loadAvatarForUser();
    }
  }

  Future<void> _loadAccountStats() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty || token.startsWith('demo-')) return;

      int bookingsCount = _bookingsCount;
      int visitedCount = _visitedCount;
      try {
        final bookings = await _bookingService.getMyBookings(limit: 50);
        bookingsCount = bookings.length;
        visitedCount = bookings
            .where((b) => b.status == 'completed' || b.status == 'confirmed')
            .length;
      } catch (_) {}

      int savedCount = _savedCount;
      try {
        final wishlists = await Future.wait([
          _discoveryService.getHomestayWishlist(),
          _discoveryService.getActivityWishlist(),
          _discoveryService.getTourGuideWishlist(),
          _discoveryService.getRentalWishlist(),
        ]);
        savedCount = wishlists.fold<int>(0, (sum, list) => sum + list.length);
      } catch (_) {}

      int unread = _unreadNotifications;
      try {
        unread = await _accountService.getUnreadCount();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _bookingsCount = bookingsCount;
          _savedCount = savedCount;
          _visitedCount = visitedCount;
          _unreadNotifications = unread;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final unread = await _accountService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotifications = unread);
      }
    } catch (_) {}
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'CG';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _onConfirmLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final token = await _storageService.getToken();
      if (token != null &&
          token.isNotEmpty &&
          !token.startsWith('demo-') &&
          !ArtisanDemoService.isDemoMode) {
        try {
          await _authService.logout(token);
        } catch (_) {}
      }
      await _storageService.clear();
    } catch (_) {}

    ArtisanDemoService.isDemoMode = false;

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/role-selection',
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of CeylonGo?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            key: const Key('confirm_logout_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _onConfirmLogout();
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationTap() async {
    if (ArtisanDemoService.isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo mode active — live notifications are disabled.'),
        ),
      );
      return;
    }
    if (_user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    await showNotificationsSheet(
      context,
      accountService: _accountService,
      onUpdated: _loadUnreadNotifications,
    );
  }

  Future<void> _onSettingsTap() async {
    if (ArtisanDemoService.isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo mode — notification settings disabled.')),
      );
      return;
    }
    if (_user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NotificationSettingsScreen(accountService: _accountService),
      ),
    );
  }

  Future<void> _onEditProfile() async {
    if (ArtisanDemoService.isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo profile cannot be edited.')),
      );
      return;
    }
    if (_user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    final updated = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialUser: _user!,
          accountService: _accountService,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  void _onReviewsInfoTap() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reviews & Ratings'),
        content: const Text(
          'Post-trip reviews are not part of the active Academic MVP v1.1 backend. '
          'You can inspect all confirmed and completed trips in My Bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyBookingsScreen(service: _bookingService),
                ),
              );
            },
            child: const Text('Open My Bookings'),
          ),
        ],
      ),
    );
  }

  void _onEditAvatar() {
    final key = _accountKey;
    if (key.isEmpty) return;
    final name = (_user?.fullName.isNotEmpty ?? false)
        ? _user!.fullName
        : 'Kamal Perera';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TravelerPhotoEditorSheet(
        accountKey: key,
        initials: _getInitials(name),
        currentPhoto: _savedPhoto,
        photoStore: _photoStore,
        photoPicker: _photoPicker,
        onPhotoChanged: (updated) {
          if (!mounted || key != _accountKey) return;
          setState(() {
            _savedPhoto = updated;
          });
        },
      ),
    );
  }

  void _onHelpSupportTap() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help with a booking or provider verification?\n\n'
          'Email: support@ceylongo.lk\n'
          'Hours: Daily 8:00 AM - 8:00 PM (IST)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onBottomNavSelected(int index) {
    if (index == 4) return; // Already on Profile

    if (index == 0) {
      // Home
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } else if (index == 1) {
      // Explore -> /artisan
      Navigator.pushReplacementNamed(context, '/artisan');
    } else if (index == 2) {
      // AI Planner -> /ai-planner
      Navigator.pushReplacementNamed(context, '/ai-planner');
    } else if (index == 3) {
      // Community -> /community
      Navigator.pushReplacementNamed(context, '/community');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    final statsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentOrange),
                )
              : FadeTransition(
                  opacity: fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Minimal White Header (Back on left, Notification & Settings on right, NO "Profile" title)
                        _buildHeaderControls(context),

                        const SizedBox(height: 18),

                        // 2. Profile Avatar & User Information Section
                        _buildAvatarSection(),

                        const SizedBox(height: 22),

                        // 3. Profile Statistics Card
                        SlideTransition(
                          position: statsSlideAnimation,
                          child: _buildStatisticsCard(),
                        ),

                        const SizedBox(height: 20),

                        // 4. Account & Activity Menu Cards
                        _buildAnimatedMenuCard(
                          key: const Key('menu_personal_details'),
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Details',
                          subtitle: 'Update your name, phone, country and password',
                          interval: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
                          onTap: _onEditProfile,
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_travel_preferences'),
                          icon: Icons.tune_rounded,
                          title: 'Travel Preferences',
                          subtitle: 'Set your travel interests, budget and style',
                          interval: const Interval(0.28, 0.73, curve: Curves.easeOutCubic),
                          onTap: () {
                            if (_user == null && !ArtisanDemoService.isDemoMode) {
                              Navigator.pushNamed(context, '/login');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TravelPreferencesScreen(
                                  accountService: _accountService,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_travel_history'),
                          icon: Icons.luggage_outlined,
                          title: 'My Bookings & History',
                          subtitle: 'Track reservations, payments and past trips',
                          interval: const Interval(0.36, 0.81, curve: Curves.easeOutCubic),
                          onTap: () {
                            if (_user == null && !ArtisanDemoService.isDemoMode) {
                              Navigator.pushNamed(context, '/login');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MyBookingsScreen(service: _bookingService),
                              ),
                            ).then((_) => _loadAccountStats());
                          },
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_wishlist'),
                          icon: Icons.favorite_border_rounded,
                          title: 'Saved Wishlist',
                          subtitle: 'Homestays, activities, guides, rentals & artisans',
                          interval: const Interval(0.40, 0.85, curve: Curves.easeOutCubic),
                          onTap: () {
                            if (_user == null && !ArtisanDemoService.isDemoMode) {
                              Navigator.pushNamed(context, '/login');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TravelerWishlistScreen(
                                  discoveryService: _discoveryService,
                                ),
                              ),
                            ).then((_) => _loadAccountStats());
                          },
                        ),
                        const SizedBox(height: 10),

                        if (_user?.role == 'provider') ...[
                          _buildAnimatedMenuCard(
                            key: const Key('menu_provider_portal'),
                            icon: Icons.storefront_outlined,
                            title: 'Service Provider Portal',
                            subtitle: 'Manage listings, verification & bookings',
                            interval: const Interval(0.42, 0.87, curve: Curves.easeOutCubic),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/provider/dashboard',
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        _buildAnimatedMenuCard(
                          key: const Key('menu_reviews_ratings'),
                          icon: Icons.star_outline_rounded,
                          title: 'Reviews & Ratings',
                          subtitle: 'View completed trips and MVP status',
                          interval: const Interval(0.44, 0.89, curve: Curves.easeOutCubic),
                          onTap: _onReviewsInfoTap,
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_help_support'),
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: 'Get help or contact our team',
                          interval: const Interval(0.52, 0.97, curve: Curves.easeOutCubic),
                          onTap: _onHelpSupportTap,
                        ),

                        const SizedBox(height: 22),

                        // 5. Full-Width Log Out or Sign In Button
                        if (_user != null || ArtisanDemoService.isDemoMode)
                          _buildLogoutButton()
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/login'),
                              icon: const Icon(Icons.login_rounded, size: 19),
                              label: const Text('Sign In / Create Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: widget.showBottomNav
            ? HomeBottomNavigationBar(
                currentIndex: 4,
                onTabSelected: _onBottomNavSelected,
              )
            : null,
      ),
    );
  }

  /// Minimal White Header Controls:
  /// Left: Circular back button.
  /// Right: Circular notification bell + Settings icon.
  /// NOTE: Pure white background, dark Navy Blue icons (#082B5C), and NO "Profile" title.
  Widget _buildHeaderControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back Button
        AnimatedScale(
          scale: _backScale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            key: const Key('profile_back_btn'),
            onTapDown: (_) => setState(() => _backScale = 0.92),
            onTapUp: (_) => setState(() => _backScale = 1.0),
            onTapCancel: () => setState(() => _backScale = 1.0),
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF082B5C),
                size: 20,
              ),
            ),
          ),
        ),

        // Right Actions: Notification Bell + Settings Icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Notification Bell with Indicator Dot
            AnimatedScale(
              scale: _notifScale,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                key: const Key('profile_notification_btn'),
                onTapDown: (_) => setState(() => _notifScale = 0.92),
                onTapUp: (_) => setState(() => _notifScale = 1.0),
                onTapCancel: () => setState(() => _notifScale = 1.0),
                onTap: _onNotificationTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF082B5C),
                        size: 20,
                      ),
                      if (_unreadNotifications > 0)
                        Positioned(
                          top: 9,
                          right: 10,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF073B91),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Settings Icon
            AnimatedScale(
              scale: _settingsScale,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                key: const Key('profile_settings_btn'),
                onTapDown: (_) => setState(() => _settingsScale = 0.92),
                onTapUp: (_) => setState(() => _settingsScale = 1.0),
                onTapCancel: () => setState(() => _settingsScale = 1.0),
                onTap: _onSettingsTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF082B5C),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Profile Avatar & Information Section:
  /// Centered circular avatar with Navy initials, light-blue outline, and royal-blue edit button.
  /// Followed by bold Traveler Name, muted Email, and light-blue Demo Traveler badge.
  Widget _buildAvatarSection() {
    final isDemo = ArtisanDemoService.isDemoMode;
    final name = (_user?.fullName.isNotEmpty ?? false)
        ? _user!.fullName
        : (isDemo ? 'Kamal Perera' : 'Guest Traveler');
    final email = (_user?.email.isNotEmpty ?? false)
        ? _user!.email
        : (isDemo ? 'demo@ceylongo.com' : 'Sign in to access your bookings');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with Royal-Blue Edit Button
        ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(
              parent: _entranceController,
              curve: Curves.easeOutBack,
            ),
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEEF4FF),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF082B5C).withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _savedPhoto != null
                    ? ClipOval(
                        child: Image.memory(
                          _savedPhoto!.bytes,
                          key: const Key('profile_avatar_image'),
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              _getInitials(name),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF082B5C),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _getInitials(name),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF082B5C),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: AnimatedScale(
                  scale: _editAvatarScale,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    key: const Key('profile_edit_avatar_btn'),
                    onTapDown: (_) => setState(() => _editAvatarScale = 0.90),
                    onTapUp: (_) => setState(() => _editAvatarScale = 1.0),
                    onTapCancel: () => setState(() => _editAvatarScale = 1.0),
                    onTap: _onEditAvatar,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF073B91),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(38),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Traveler Name
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF082B5C),
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 3),

        // Email Address
        Text(
          email,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 8),

        // Light-Blue Role Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 12,
                color: Color(0xFF073B91),
              ),
              const SizedBox(width: 4),
              Text(
                isDemo
                    ? 'Demo Traveler'
                    : (_user?.role.toUpperCase() ?? 'TRAVELER'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF073B91),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section 5: Profile Statistics Card
  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 1. Bookings
            Expanded(
              child: InkWell(
                onTap: () {
                  if (_user == null && !ArtisanDemoService.isDemoMode) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyBookingsScreen(service: _bookingService),
                    ),
                  ).then((_) => _loadAccountStats());
                },
                child: _buildStatItem(
                  icon: Icons.calendar_today_outlined,
                  value: ArtisanDemoService.isDemoMode ? '3' : '$_bookingsCount',
                  label: 'Bookings',
                ),
              ),
            ),

            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),

            // 2. Saved
            Expanded(
              child: InkWell(
                onTap: () {
                  if (_user == null && !ArtisanDemoService.isDemoMode) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TravelerWishlistScreen(
                        discoveryService: _discoveryService,
                      ),
                    ),
                  ).then((_) => _loadAccountStats());
                },
                child: _buildStatItem(
                  icon: Icons.favorite_outline_rounded,
                  value: ArtisanDemoService.isDemoMode ? '5' : '$_savedCount',
                  label: 'Saved',
                ),
              ),
            ),

            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),

            // 3. Completed / Confirmed Trips
            Expanded(
              child: _buildStatItem(
                icon: Icons.location_on_outlined,
                value: ArtisanDemoService.isDemoMode ? '8' : '$_visitedCount',
                label: 'Active/Done',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF073B91)),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  /// Section 6: Animated Staggered Menu Card
  Widget _buildAnimatedMenuCard({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Interval interval,
    required VoidCallback onTap,
  }) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: interval,
      ),
    );

    final fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: interval,
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: _MenuCardItem(
          cardKey: key,
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: onTap,
        ),
      ),
    );
  }

  /// Section 7: Full-Width Log Out Button
  Widget _buildLogoutButton() {
    return AnimatedScale(
      scale: _logoutScale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        key: const Key('profile_logout_btn'),
        onTapDown: (_) => setState(() => _logoutScale = 0.98),
        onTapUp: (_) => setState(() => _logoutScale = 1.0),
        onTapCancel: () => setState(() => _logoutScale = 1.0),
        onTap: _showLogoutDialog,
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCardItem extends StatefulWidget {
  final Key cardKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCardItem({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_MenuCardItem> createState() => _MenuCardItemState();
}

class _MenuCardItemState extends State<_MenuCardItem> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        key: widget.cardKey,
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Light-blue icon container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF073B91),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right-facing Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
