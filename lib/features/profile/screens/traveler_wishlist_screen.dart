import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ceylongo_network_image.dart';
import '../../artisan/models/artisan_wishlist_model.dart';
import '../../auth/models/api_error.dart';
import '../../categories/models/discovery_models.dart';
import '../../categories/screens/activity_detail_screen.dart';
import '../../categories/screens/homestay_detail_screen.dart';
import '../../categories/screens/rental_detail_screen.dart';
import '../../categories/screens/tour_guide_detail_screen.dart';
import '../../categories/services/discovery_service.dart';

/// Unified Traveler Wishlist Screen across Homestays, Activities, Tour Guides,
/// Bike/Bicycle Rentals, and Artisans.
class TravelerWishlistScreen extends StatefulWidget {
  final DiscoveryService? discoveryService;
  final ApiClient? apiClient;

  const TravelerWishlistScreen({
    super.key,
    this.discoveryService,
    this.apiClient,
  });

  @override
  State<TravelerWishlistScreen> createState() => _TravelerWishlistScreenState();
}

class _TravelerWishlistScreenState extends State<TravelerWishlistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final DiscoveryService _discoveryService;
  late final ApiClient _api;

  bool _loading = true;
  String? _error;

  List<HomestayListingModel> _homestays = [];
  List<ActivityListingModel> _activities = [];
  List<TourGuideListingModel> _guides = [];
  List<RentalVehicleModel> _rentals = [];
  List<ArtisanWishlistItemModel> _artisans = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _api = widget.apiClient ?? ApiClient();
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _discoveryService.getHomestayWishlist(),
        _discoveryService.getActivityWishlist(),
        _discoveryService.getTourGuideWishlist(),
        _discoveryService.getRentalWishlist(),
        _fetchArtisanWishlist(),
      ]);
      if (!mounted) return;
      setState(() {
        _homestays = results[0] as List<HomestayListingModel>;
        _activities = results[1] as List<ActivityListingModel>;
        _guides = results[2] as List<TourGuideListingModel>;
        _rentals = results[3] as List<RentalVehicleModel>;
        _artisans = results[4] as List<ArtisanWishlistItemModel>;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load saved items. Please try again.';
      });
    }
  }

  Future<List<ArtisanWishlistItemModel>> _fetchArtisanWishlist() async {
    final data = await _api.get('${ApiConstants.apiV1}/artisan-wishlists/me');
    if (data is Map<String, dynamic> && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ArtisanWishlistItemModel.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> _removeHomestay(HomestayListingModel item) async {
    await _discoveryService.setHomestayWishlist(item.id, save: false);
    if (!mounted) return;
    setState(() => _homestays.removeWhere((e) => e.id == item.id));
  }

  Future<void> _removeActivity(ActivityListingModel item) async {
    await _discoveryService.setActivityWishlist(item.id, save: false);
    if (!mounted) return;
    setState(() => _activities.removeWhere((e) => e.id == item.id));
  }

  Future<void> _removeGuide(TourGuideListingModel item) async {
    await _discoveryService.setTourGuideWishlist(item.id, save: false);
    if (!mounted) return;
    setState(() => _guides.removeWhere((e) => e.id == item.id));
  }

  Future<void> _removeRental(RentalVehicleModel item) async {
    await _discoveryService.setRentalWishlist(item.id, save: false);
    if (!mounted) return;
    setState(() => _rentals.removeWhere((e) => e.id == item.id));
  }

  Future<void> _removeArtisan(ArtisanWishlistItemModel item) async {
    await _api.delete(
      '${ApiConstants.apiV1}/artisan-listings/${item.artisanListingId}/wishlist',
    );
    if (!mounted) return;
    setState(() => _artisans.removeWhere((e) => e.id == item.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Saved Wishlist'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryNavy,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accentOrange,
          tabs: [
            Tab(text: 'Homestays (${_homestays.length})'),
            Tab(text: 'Activities (${_activities.length})'),
            Tab(text: 'Guides (${_guides.length})'),
            Tab(text: 'Rentals (${_rentals.length})'),
            Tab(text: 'Artisans (${_artisans.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadAll,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      isEmpty: _homestays.isEmpty,
                      emptyLabel: 'No saved homestays yet.',
                      count: _homestays.length,
                      builder: (i) {
                        final item = _homestays[i];
                        return _WishlistCard(
                          title: item.title,
                          subtitle: item.locationLabel,
                          priceText: '${formatLkrAmount(item.price)} / night',
                          imageUrl: item.coverImageUrl,
                          onRemove: () => _removeHomestay(item),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomestayDetailScreen(
                                listingId: item.id,
                                initialListing: item,
                              ),
                            ),
                          ).then((_) => _loadAll()),
                        );
                      },
                    ),
                    _buildList(
                      isEmpty: _activities.isEmpty,
                      emptyLabel: 'No saved activities yet.',
                      count: _activities.length,
                      builder: (i) {
                        final item = _activities[i];
                        return _WishlistCard(
                          title: item.title,
                          subtitle: item.locationLabel,
                          priceText:
                              '${formatLkrAmount(item.pricePerParticipant)} / person',
                          imageUrl: item.coverImageUrl,
                          onRemove: () => _removeActivity(item),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailScreen(
                                listingId: item.id,
                                initialListing: item,
                              ),
                            ),
                          ).then((_) => _loadAll()),
                        );
                      },
                    ),
                    _buildList(
                      isEmpty: _guides.isEmpty,
                      emptyLabel: 'No saved tour guides yet.',
                      count: _guides.length,
                      builder: (i) {
                        final item = _guides[i];
                        return _WishlistCard(
                          title: item.title,
                          subtitle: item.locationLabel,
                          priceText: '${formatLkrAmount(item.price)} base',
                          imageUrl: item.coverImageUrl,
                          onRemove: () => _removeGuide(item),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TourGuideDetailScreen(
                                listingId: item.id,
                                initialListing: item,
                              ),
                            ),
                          ).then((_) => _loadAll()),
                        );
                      },
                    ),
                    _buildList(
                      isEmpty: _rentals.isEmpty,
                      emptyLabel: 'No saved rentals yet.',
                      count: _rentals.length,
                      builder: (i) {
                        final item = _rentals[i];
                        return _WishlistCard(
                          title: item.vehicleName,
                          subtitle: item.locationLabel,
                          priceText:
                              '${formatLkrAmount(item.pricePerDay)} / day',
                          imageUrl: item.primaryImageUrl,
                          onRemove: () => _removeRental(item),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RentalDetailScreen(
                                vehicleId: item.id,
                                initialVehicle: item,
                              ),
                            ),
                          ).then((_) => _loadAll()),
                        );
                      },
                    ),
                    _buildList(
                      isEmpty: _artisans.isEmpty,
                      emptyLabel: 'No saved artisans yet.',
                      count: _artisans.length,
                      builder: (i) {
                        final item = _artisans[i];
                        final summary = item.listing;
                        return _WishlistCard(
                          title: summary?.title ??
                              'Artisan #${item.artisanListingId}',
                          subtitle: summary != null
                              ? '${summary.city}, ${summary.district}'
                              : 'Local Artisan Showcase',
                          priceText: summary?.craftCategory ?? 'Artisan Showcase',
                          imageUrl: ApiConstants.resolveMediaUrl(
                            summary?.coverImageUrl,
                          ),
                          onRemove: () => _removeArtisan(item),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/artisan/detail',
                            arguments: item.artisanListingId,
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildList({
    required bool isEmpty,
    required String emptyLabel,
    required int count,
    required Widget Function(int index) builder,
  }) {
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              emptyLabel,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: count,
        itemBuilder: (_, index) => builder(index),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String priceText;
  final String imageUrl;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _WishlistCard({
    required this.title,
    required this.subtitle,
    required this.priceText,
    required this.imageUrl,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.borderSlate),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 82,
                  height: 76,
                  child: CeylonGoNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentHover,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.favorite, color: AppTheme.errorRed),
                tooltip: 'Remove from wishlist',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
