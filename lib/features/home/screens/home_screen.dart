import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../../categories/models/discovery_models.dart';
import '../../categories/screens/homestays_category_screen.dart';
import '../../categories/services/discovery_service.dart';
import '../../profile/services/account_service.dart';
import '../../profile/widgets/notifications_sheet.dart';
import '../widgets/home_bottom_navigation_bar.dart';
import '../widgets/home_category_filters.dart';
import '../widgets/home_category_showcase.dart';
import '../widgets/home_featured_homestays.dart';
import '../widgets/home_header.dart';
import '../widgets/home_popular_destinations.dart';
import '../widgets/home_recommended_for_you_card.dart';
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
  final DiscoveryService? discoveryService;
  final AccountService? accountService;
  final bool showBottomNav;

  const HomeScreen({
    super.key,
    this.initialUser,
    this.authService,
    this.storageService,
    this.discoveryService,
    this.accountService,
    this.showBottomNav = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late final SecureStorageService _storageService;
  late final DiscoveryService _discoveryService;
  late final AccountService _accountService;
  late final AnimationController _entranceController;

  UserModel? _user;
  bool _isLoading = true;
  String _selectedCategoryId = 'all';

  bool _isHomeDataLoading = false;
  String? _homeDataError;
  List<HomestayListingModel> _homestays = [];
  List<ActivityListingModel> _activities = [];
  List<TourGuideListingModel> _guides = [];
  List<RentalVehicleModel> _rentals = [];
  Set<int> _favoriteHomestayIds = {};
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _storageService = widget.storageService ?? SecureStorageService();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _accountService = widget.accountService ?? AccountService(storageService: _storageService);

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _loadUser();
    if (!ArtisanDemoService.isDemoMode) {
      _loadHomeData();
    }

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

  Future<void> _loadHomeData() async {
    if (ArtisanDemoService.isDemoMode) return;
    if (mounted) {
      setState(() {
        _isHomeDataLoading = true;
        _homeDataError = null;
      });
    }

    try {
      final results = await Future.wait([
        _discoveryService.searchHomestays(limit: 10),
        _discoveryService.searchActivities(limit: 8).catchError((_) => <ActivityListingModel>[]),
        _discoveryService.searchTourGuides(limit: 8).catchError((_) => <TourGuideListingModel>[]),
        _discoveryService.searchRentals(limit: 8).catchError((_) => <RentalVehicleModel>[]),
      ]);

      final hasToken = await _storageService.hasToken();
      Set<int> favIds = _favoriteHomestayIds;
      int unread = _unreadNotifications;
      if (hasToken) {
        try {
          final wish = await _discoveryService.getHomestayWishlist();
          favIds = wish.map((e) => e.id).toSet();
        } catch (_) {}
        try {
          unread = await _accountService.getUnreadCount();
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _homestays = results[0] as List<HomestayListingModel>;
        _activities = results[1] as List<ActivityListingModel>;
        _guides = results[2] as List<TourGuideListingModel>;
        _rentals = results[3] as List<RentalVehicleModel>;
        _favoriteHomestayIds = favIds;
        _unreadNotifications = unread;
        _isHomeDataLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isHomeDataLoading = false;
        _homeDataError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isHomeDataLoading = false;
        _homeDataError = 'Unable to load listings from backend.';
      });
    }
  }

  Future<void> _toggleFavoriteHomestay(HomestayListingModel item) async {
    if (ArtisanDemoService.isDemoMode) return;
    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save homestays.')),
        );
      }
      return;
    }
    final nextSaved = !_favoriteHomestayIds.contains(item.id);
    try {
      await _discoveryService.setHomestayWishlist(item.id, save: nextSaved);
      if (!mounted) return;
      setState(() {
        if (nextSaved) {
          _favoriteHomestayIds = {..._favoriteHomestayIds, item.id};
        } else {
          _favoriteHomestayIds =
              _favoriteHomestayIds.where((id) => id != item.id).toSet();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update wishlist: $e')),
      );
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final hasToken = await _storageService.hasToken();
      if (!hasToken) return;
      final unread = await _accountService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotifications = unread);
      }
    } catch (_) {}
  }

  Future<void> _onNotificationTap() async {
    if (ArtisanDemoService.isDemoMode) {
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
                    'Notifications (Demo)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Demo preview mode is active.',
                style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final hasToken = await _storageService.hasToken();
    if (!hasToken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to view notifications.')),
        );
      }
      return;
    }

    if (!mounted) return;
    await showNotificationsSheet(
      context,
      accountService: _accountService,
      onUpdated: _loadUnreadNotifications,
    );
  }

  void _onProfileTap() {
    Navigator.pushNamed(context, '/profile');
  }

  void _onBottomNavSelected(int index) {
    if (index == 0) {
      // Already on Home
      return;
    } else if (index == 1) {
      // Explore -> Navigate to Artisan Discovery
      Navigator.pushNamed(context, '/artisan');
    } else if (index == 2) {
      // AI Planner
      Navigator.pushNamed(context, '/ai-planner');
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
                    unreadNotifications: _unreadNotifications,
                    onNotificationTap: _onNotificationTap,
                    onProfileTap: _onProfileTap,
                  ),

                  // B. Fixed Rounded Search Bar ("Start your search")
                  HomeSearchBar(
                    animation: _entranceController,
                    onSearch: (query) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomestaysCategoryScreen(
                            initialDestination: query.trim().isEmpty
                                ? null
                                : query.trim(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // C. Horizontally Scrollable Category Filter Row
                  HomeCategoryFilters(
                    animation: _entranceController,
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: (category) {
                      if (category.id == 'all') {
                        setState(() {
                          _selectedCategoryId = 'all';
                        });
                        return;
                      }
                      Navigator.pushNamed(
                        context,
                        '/category/${category.id}',
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // D-G. Scrollable Home Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadHomeData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
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
                            HomeFeaturedHomestays(
                              animation: _entranceController,
                              homestays: ArtisanDemoService.isDemoMode
                                  ? null
                                  : _homestays,
                              favoriteIds: _favoriteHomestayIds,
                              onFavoriteTap: _toggleFavoriteHomestay,
                              isLoading: _isHomeDataLoading,
                              errorMessage: _homeDataError,
                              onRetry: _loadHomeData,
                              onViewAllTap: () => Navigator.pushNamed(
                                context,
                                '/category/homestays',
                              ),
                            ),

                            if (_selectedCategoryId == 'all') ...[
                              const SizedBox(height: 14),
                              HomeCategoryShowcase(
                                activities: _activities,
                                guides: _guides,
                                rentals: _rentals,
                                isLoading: _isHomeDataLoading,
                              ),
                            ],

                            const SizedBox(height: 14),
                            HomeRecommendedForYouCard(
                              onExploreTap: () => Navigator.pushNamed(
                                context,
                                '/recommendations',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        // H. Floating Bottom Navigation Bar
        bottomNavigationBar: widget.showBottomNav
            ? HomeBottomNavigationBar(
                currentIndex: 0,
                onTabSelected: _onBottomNavSelected,
              )
            : null,
      ),
    );
  }
}
