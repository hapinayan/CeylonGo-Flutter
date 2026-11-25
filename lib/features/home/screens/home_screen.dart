import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/home_bottom_navigation_bar.dart';
import '../widgets/home_category_filters.dart';
import '../widgets/home_featured_homestays.dart';
import '../widgets/home_header.dart';
import '../widgets/home_popular_destinations.dart';
import '../widgets/home_search_bar.dart';

/// CeylonGo Traveler Home Screen
/// Matches the approved white-theme reference design:
/// A. White Header (Dark navy CeylonGo, Notification bell with dot, Profile button)
/// B. Rounded Search Bar ("Start your search")
/// C. Horizontally Scrollable Category Filter Row (All, Homestays, Eco, Activities, Guides, Rentals)
/// D. Popular Destinations (Jaffna, Ella, Kandy)
/// E. Featured Homestays (Traditional Villa with garden, Ella Mountain Homestay)
/// F. Fixed Floating Bottom Navigation Bar (Home, Explore, AI Planner, Community, Profile)
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late final SecureStorageService _storageService;
  late final AnimationController _entranceController;

  UserModel? _user;
  bool _isLoading = true;
  int _currentNavIndex = 0;
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _storageService = widget.storageService ?? SecureStorageService();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 700),
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
      }

      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        if (token.startsWith('demo-') || ArtisanDemoService.isDemoMode) {
          if (mounted) {
            setState(() {
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

  void _onNotificationTap() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 10),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.stars, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Welcome to CeylonGo! Explore authentic Sri Lankan artisan craft workshops in Galle & Kandy.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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

  void _onProfileTap() {
    Navigator.pushNamed(context, '/profile');
  }

  void _onBottomNavSelected(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    if (index == 0) {
      // Already on Home
    } else if (index == 1) {
      // Explore -> Navigate to Artisan Discovery
      Navigator.pushNamed(context, '/artisan');
    } else if (index == 2) {
      // AI Planner
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AI Trip Planner will be available in the upcoming release.',
          ),
          backgroundColor: Color(0xFF2563EB),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (index == 3) {
      // Community -> Navigate to Community Feed
      Navigator.pushNamed(context, '/community');
    } else if (index == 4) {
      // Profile
      _onProfileTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentOrange),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. Fixed White Header (Dark navy CeylonGo, Notification & Profile)
                  HomeHeader(
                    animation: _entranceController,
                    user: _user,
                    onNotificationTap: _onNotificationTap,
                    onProfileTap: _onProfileTap,
                  ),

                  // B. Fixed Rounded Search Bar ("Start your search")
                  HomeSearchBar(
                    animation: _entranceController,
                    onSearch: (query) {
                      Navigator.pushNamed(context, '/artisan');
                    },
                  ),

                  const SizedBox(height: 8),

                  // C. Horizontally Scrollable Category Filter Row
                  HomeCategoryFilters(
                    animation: _entranceController,
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                    },
                  ),

                  const SizedBox(height: 6),

                  // D-G. Scrollable Home Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // D. Popular Destinations (Jaffna, Ella, Kandy)
                          HomePopularDestinations(
                            animation: _entranceController,
                          ),

                          const SizedBox(height: 14),

                          // E. Featured Homestays
                          HomeFeaturedHomestays(animation: _entranceController),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        // H. Floating Bottom Navigation Bar
        bottomNavigationBar: HomeBottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTabSelected: _onBottomNavSelected,
        ),
      ),
    );
  }
}
