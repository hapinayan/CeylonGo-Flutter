import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../home/widgets/home_bottom_navigation_bar.dart';

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
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.initialUser,
    this.authService,
    this.storageService,
    this.showBottomNav = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late final SecureStorageService _storageService;
  late final AnimationController _entranceController;

  UserModel? _user;
  bool _isLoading = true;
  bool _isLoggingOut = false;

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
        return;
      }

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
              _isLoading = false;
            });
          }
          return;
        }

        final verifiedUser = await _authService.getMe(token);
        if (mounted) {
          setState(() {
            _user = verifiedUser;
            _isLoading = false;
          });
          return;
        }
      }

      // Default demo traveler session
      if (mounted) {
        setState(() {
          _user = const UserModel(
            id: 'demo-user-001',
            fullName: 'Kamal Perera',
            email: 'demo@ceylongo.com',
            role: 'traveler',
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _user = const UserModel(
            id: 'demo-user-001',
            fullName: 'Kamal Perera',
            email: 'demo@ceylongo.com',
            role: 'traveler',
          );
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'KP';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _onConfirmLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _storageService.clear();
    } catch (_) {}

    ArtisanDemoService.isDemoMode = false;

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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

  void _onNotificationTap() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notifications_active_outlined, color: Color(0xFF073B91)),
                SizedBox(width: 10),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF082B5C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'Welcome to CeylonGo! Explore authentic Sri Lankan artisan craft workshops in Galle & Kandy.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF082B5C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/artisan');
                },
                child: const Text('View Artisan Discoveries'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSettingsTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App settings and preferences coming soon!'),
        backgroundColor: Color(0xFF082B5C),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onEditProfile() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile photo and details editor coming soon!'),
        backgroundColor: Color(0xFF073B91),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onMenuTap(String title) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is coming soon!'),
        backgroundColor: const Color(0xFF082B5C),
        duration: const Duration(seconds: 2),
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

                        // 4. Five Menu Cards with staggered entrance
                        _buildAnimatedMenuCard(
                          key: const Key('menu_personal_details'),
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Details',
                          subtitle: 'Update your name, email and contact info',
                          interval: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
                          onTap: () => _onMenuTap('Personal Details'),
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_travel_preferences'),
                          icon: Icons.tune_rounded,
                          title: 'Travel Preferences',
                          subtitle: 'Set your travel interests and style',
                          interval: const Interval(0.28, 0.73, curve: Curves.easeOutCubic),
                          onTap: () => _onMenuTap('Travel Preferences'),
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_travel_history'),
                          icon: Icons.history_rounded,
                          title: 'Travel History',
                          subtitle: 'View your past trips and activities',
                          interval: const Interval(0.36, 0.81, curve: Curves.easeOutCubic),
                          onTap: () => _onMenuTap('Travel History'),
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_reviews_ratings'),
                          icon: Icons.star_outline_rounded,
                          title: 'Reviews & Ratings',
                          subtitle: 'Your reviews on stays, guides and activities',
                          interval: const Interval(0.44, 0.89, curve: Curves.easeOutCubic),
                          onTap: () => _onMenuTap('Reviews & Ratings'),
                        ),
                        const SizedBox(height: 10),

                        _buildAnimatedMenuCard(
                          key: const Key('menu_help_support'),
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: 'Get help or contact our team',
                          interval: const Interval(0.52, 0.97, curve: Curves.easeOutCubic),
                          onTap: () => _onMenuTap('Help & Support'),
                        ),

                        const SizedBox(height: 22),

                        // 5. Full-Width Log Out Button
                        _buildLogoutButton(),

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
    final name = _user?.fullName.isNotEmpty ?? false
        ? _user!.fullName
        : 'Kamal Perera';
    final email = _user?.email.isNotEmpty ?? false
        ? _user!.email
        : 'demo@ceylongo.com';
    final isDemo = ArtisanDemoService.isDemoMode || email.contains('demo');

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
                child: Center(
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
                    onTap: _onEditProfile,
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
              child: _buildStatItem(
                icon: Icons.calendar_today_outlined,
                value: '3',
                label: 'Bookings',
              ),
            ),

            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),

            // 2. Saved
            Expanded(
              child: _buildStatItem(
                icon: Icons.favorite_outline_rounded,
                value: '5',
                label: 'Saved',
              ),
            ),

            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E8F0),
            ),

            // 3. Places Visited
            Expanded(
              child: _buildStatItem(
                icon: Icons.location_on_outlined,
                value: '8',
                label: 'Places Visited',
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
