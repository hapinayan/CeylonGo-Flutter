import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/artisan_listing_model.dart';
import '../services/artisan_demo_service.dart';
import '../services/artisan_location_service.dart';
import '../services/artisan_service.dart';
import '../widgets/artisan_demo_banner.dart';
import '../widgets/artisan_listing_card.dart';
import 'artisan_business_detail_screen.dart';
import 'artisan_product_catalog_screen.dart';
import 'artisan_reservation_history_screen.dart';
import 'artisan_wishlist_screen.dart';

class ArtisanDiscoveryScreen extends StatefulWidget {
  final ArtisanService? artisanService;
  final ArtisanLocationService? locationService;

  const ArtisanDiscoveryScreen({
    super.key,
    this.artisanService,
    this.locationService,
  });

  @override
  State<ArtisanDiscoveryScreen> createState() => _ArtisanDiscoveryScreenState();
}

class _ArtisanDiscoveryScreenState extends State<ArtisanDiscoveryScreen> {
  late final ArtisanService _artisanService;
  late final ArtisanLocationService _locationService;

  // Filter State
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedDistrict = 'All';
  bool _featuredOnly = false;
  bool _isNearbyMode = false;
  bool _isAcquiringLocation = false;
  double? _userLatitude;
  double? _userLongitude;
  final double _searchRadiusKm = 50.0;

  // Data State
  List<ArtisanListingSummary> _listings = [];
  List<ArtisanListingSummary> _featuredListings = [];
  List<String> _categories = ['All'];
  List<String> _districts = ['All'];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _artisanService = widget.artisanService ??
        (ArtisanDemoService.isDemoMode
            ? ArtisanDemoService.instance
            : ArtisanService());
    _locationService = widget.locationService ?? ArtisanLocationService();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _artisanService.getCategories().catchError((_) => <String>[]),
        _artisanService.getDistricts().catchError((_) => <String>[]),
        _artisanService.getFeaturedListings(pageSize: 6).catchError((_) => const ArtisanListingPagination(
              items: [],
              total: 0,
              page: 1,
              pageSize: 6,
              totalPages: 0,
            )),
        _fetchListingsPage(1),
      ]);

      final fetchedCategories = futures[0] as List<String>;
      final fetchedDistricts = futures[1] as List<String>;
      final featuredPagination = futures[2] as ArtisanListingPagination;
      final listingsPagination = futures[3] as ArtisanListingPagination;

      if (mounted) {
        setState(() {
          _categories = ['All', ...fetchedCategories];
          _districts = ['All', ...fetchedDistricts];
          _featuredListings = featuredPagination.items;
          _listings = listingsPagination.items;
          _currentPage = listingsPagination.page;
          _totalPages = listingsPagination.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<ArtisanListingPagination> _fetchListingsPage(int page) async {
    if (_isNearbyMode && _userLatitude != null && _userLongitude != null) {
      final nearbyResult = await _artisanService.getNearbyListings(
        latitude: _userLatitude!,
        longitude: _userLongitude!,
        radiusKm: _searchRadiusKm,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: page,
        pageSize: 12,
      );
      return ArtisanListingPagination(
        items: nearbyResult.items,
        total: nearbyResult.total,
        page: nearbyResult.page,
        pageSize: nearbyResult.pageSize,
        totalPages: nearbyResult.totalPages,
      );
    }
    return _artisanService.getListings(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      district: _selectedDistrict == 'All' ? null : _selectedDistrict,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      isFeatured: _featuredOnly ? true : null,
      page: page,
      pageSize: 12,
    );
  }

  Future<void> _toggleNearbyMode() async {
    if (_isNearbyMode) {
      setState(() {
        _isNearbyMode = false;
        _userLatitude = null;
        _userLongitude = null;
      });
      _applyFilters();
      return;
    }

    final consent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.accentOrange),
            SizedBox(width: 8),
            Text('Find Nearby Artisans'),
          ],
        ),
        content: const Text(
          'CeylonGo requests access to your device location to discover traditional craft workshops and artisan businesses near you.\n\nDo you want to share your location for nearby discovery?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Deny'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow Location'),
          ),
        ],
      ),
    );

    if (consent != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission was not granted. Showing all workshops by district.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Traveler granted consent: query actual device hardware GPS via ArtisanLocationService
    setState(() {
      _isAcquiringLocation = true;
    });

    final locationResult = await _locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _isAcquiringLocation = false;
    });

    if (locationResult.isSuccess) {
      setState(() {
        _userLatitude = locationResult.latitude;
        _userLongitude = locationResult.longitude;
        _isNearbyMode = true;
      });
      _applyFilters();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationResult.errorMessage ?? 'Unable to obtain GPS location. Showing all workshops.'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final result = await _fetchListingsPage(1);
      if (mounted) {
        setState(() {
          _listings = result.items;
          _currentPage = result.page;
          _totalPages = result.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _fetchListingsPage(nextPage);
      if (mounted) {
        setState(() {
          _listings.addAll(result.items);
          _currentPage = result.page;
          _totalPages = result.totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategory = 'All';
      _selectedDistrict = 'All';
      _featuredOnly = false;
      _isNearbyMode = false;
      _userLatitude = null;
      _userLongitude = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Artisan Discovery'),
        actions: [
          IconButton(
            key: const Key('nav_wishlist_btn'),
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Saved Workshops',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtisanWishlistScreen(
                    artisanService: _artisanService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('nav_reservations_btn'),
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'My Reservations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtisanReservationHistoryScreen(
                    artisanService: _artisanService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            tooltip: 'Browse All Products',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtisanProductCatalogScreen(
                    artisanService: _artisanService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ArtisanDemoBanner(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.accentOrange,
              onRefresh: _loadInitialData,
              child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search and Filter Bar
            SliverToBoxAdapter(
              child: Container(
                color: AppTheme.backgroundWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search craft, workshop, or city...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                    const SizedBox(height: 12),

                    // Category Filter Pills
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryNavy,
                            backgroundColor: AppTheme.backgroundLight,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryNavy : AppTheme.borderSlate,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                                _applyFilters();
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // District & Featured Controls
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderSlate),
                              borderRadius: BorderRadius.circular(10),
                              color: AppTheme.backgroundWhite,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _districts.contains(_selectedDistrict)
                                    ? _selectedDistrict
                                    : 'All',
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                                items: _districts.map((d) {
                                  return DropdownMenuItem(
                                    value: d,
                                    child: Text(d == 'All' ? 'All Districts' : d),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedDistrict = val;
                                    });
                                    _applyFilters();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          key: const Key('featured_filter_chip'),
                          label: const Text('Featured'),
                          selected: _featuredOnly,
                          selectedColor: const Color(0xFFFEF3C7),
                          checkmarkColor: const Color(0xFF92400E),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: _featuredOnly ? FontWeight.bold : FontWeight.normal,
                            color: _featuredOnly ? const Color(0xFF92400E) : AppTheme.textSecondary,
                          ),
                          side: BorderSide(
                            color: _featuredOnly ? const Color(0xFFFDE68A) : AppTheme.borderSlate,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _featuredOnly = val;
                            });
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          key: const Key('nearby_filter_chip'),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isAcquiringLocation)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange),
                                )
                              else
                                const Icon(Icons.near_me, size: 13),
                              const SizedBox(width: 4),
                              Text(_isAcquiringLocation ? 'Locating...' : 'Nearby'),
                            ],
                          ),
                          selected: _isNearbyMode,
                          selectedColor: const Color(0xFFFFEDD5),
                          checkmarkColor: AppTheme.accentOrange,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: _isNearbyMode ? FontWeight.bold : FontWeight.normal,
                            color: _isNearbyMode ? AppTheme.accentOrange : AppTheme.textSecondary,
                          ),
                          side: BorderSide(
                            color: _isNearbyMode ? AppTheme.accentOrange : AppTheme.borderSlate,
                          ),
                          onSelected: (_) => _toggleNearbyMode(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Featured Spotlights (Visible when not filtering by specific category/search)
            if (_featuredListings.isNotEmpty &&
                !_featuredOnly &&
                _searchController.text.isEmpty &&
                _selectedCategory == 'All') ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Featured Spotlights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Curated Artisans',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _featuredListings.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = _featuredListings[index];
                      return SizedBox(
                        width: 240,
                        child: ArtisanListingCard(
                          listing: item,
                          isCompact: true,
                          onTap: () => _navigateToDetail(item.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Main Listing Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _featuredOnly
                      ? 'Featured Workshops (${_listings.length})'
                      : 'All Artisan Workshops (${_listings.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ),

            // Content or Loading or Empty
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accentOrange),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to Load Artisans',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadInitialData,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_listings.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No Artisan Workshops Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try adjusting your search query, craft category, or district filter.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _resetFilters,
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _listings[index];
                      return ArtisanListingCard(
                        listing: item,
                        onTap: () => _navigateToDetail(item.id),
                      );
                    },
                    childCount: _listings.length,
                  ),
                ),
              ),

            // Pagination loader at bottom
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accentOrange),
                  ),
                ),
              ),
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanBusinessDetailScreen(
          listingId: id,
          artisanService: _artisanService,
        ),
      ),
    );
  }
}
