import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../data/category_demo_data.dart';
import '../models/discovery_models.dart';
import '../services/discovery_service.dart';
import '../widgets/category_page_scaffold.dart';
import 'homestay_detail_screen.dart';

class HomestaysCategoryScreen extends StatefulWidget {
  final String? initialDestination;
  final DiscoveryService? discoveryService;
  final SecureStorageService? storageService;

  const HomestaysCategoryScreen({
    super.key,
    this.initialDestination,
    this.discoveryService,
    this.storageService,
  });

  @override
  State<HomestaysCategoryScreen> createState() =>
      _HomestaysCategoryScreenState();
}

class _HomestaysCategoryScreenState extends State<HomestaysCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final DiscoveryService _discoveryService;
  late final SecureStorageService _storage;

  String _selectedLocation = 'All';
  String _selectedPriceRange = 'All Prices';
  final Set<int> _favoriteIds = {};

  List<HomestayListingModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const _locations = ['All', 'Jaffna', 'Ella', 'Kandy', 'Galle'];
  static const _priceRanges = [
    'All Prices',
    'Under 10k',
    '10k - 20k',
    '20k+',
  ];

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _storage = widget.storageService ?? SecureStorageService();
    if (widget.initialDestination != null &&
        widget.initialDestination!.trim().isNotEmpty) {
      final dest = widget.initialDestination!.trim();
      if (_locations.contains(dest)) {
        _selectedLocation = dest;
      } else {
        _searchController.text = dest;
      }
    }
    _loadHomestays();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHomestays() async {
    if (ArtisanDemoService.isDemoMode) {
      setState(() {
        _items = CategoryDemoData.homestays
            .asMap()
            .entries
            .map(
              (entry) => HomestayListingModel(
                id: entry.key + 1,
                providerId: 1,
                title: entry.value.name,
                description: entry.value.description,
                district: entry.value.location,
                locality: entry.value.location,
                price: entry.value.priceLkr.toString(),
                imageUrls: [entry.value.imageUrl],
              ),
            )
            .toList();
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? minPrice;
      String? maxPrice;
      if (_selectedPriceRange == 'Under 10k') {
        maxPrice = '9999';
      } else if (_selectedPriceRange == '10k - 20k') {
        minPrice = '10000';
        maxPrice = '20000';
      } else if (_selectedPriceRange == '20k+') {
        minPrice = '20001';
      }

      final destination = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : (_selectedLocation != 'All' ? _selectedLocation : null);

      final items = await _discoveryService.searchHomestays(
        destination: destination,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      final savedIds = <int>{};
      if (await _storage.hasToken()) {
        try {
          final wl = await _discoveryService.getHomestayWishlist();
          savedIds.addAll(wl.map((e) => e.id));
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _favoriteIds
          ..clear()
          ..addAll(savedIds);
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load homestays from server.';
      });
    }
  }

  List<HomestayListingModel> get _filteredListings {
    if (!ArtisanDemoService.isDemoMode) {
      final query = _searchController.text.trim().toLowerCase();
      if (_selectedLocation != 'All' && query.isNotEmpty) {
        return _items.where((item) {
          return item.district.toLowerCase().contains(_selectedLocation.toLowerCase()) ||
              item.locality.toLowerCase().contains(_selectedLocation.toLowerCase());
        }).toList();
      }
      return _items;
    }

    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final priceVal = double.tryParse(item.price) ?? 0;
      if (_selectedLocation != 'All' && item.district != _selectedLocation) {
        return false;
      }
      if (_selectedPriceRange == 'Under 10k' && priceVal >= 10000) {
        return false;
      }
      if (_selectedPriceRange == '10k - 20k' &&
          (priceVal < 10000 || priceVal > 20000)) {
        return false;
      }
      if (_selectedPriceRange == '20k+' && priceVal <= 20000) {
        return false;
      }
      if (query.isNotEmpty &&
          !item.title.toLowerCase().contains(query) &&
          !item.district.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedLocation = 'All';
      _selectedPriceRange = 'All Prices';
    });
    _loadHomestays();
  }

  Future<void> _toggleFavorite(HomestayListingModel item) async {
    if (ArtisanDemoService.isDemoMode) {
      setState(() {
        if (_favoriteIds.contains(item.id)) {
          _favoriteIds.remove(item.id);
        } else {
          _favoriteIds.add(item.id);
        }
      });
      return;
    }

    if (!await _storage.hasToken()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to save homestays.'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
        ),
      );
      return;
    }

    final currentlyFav = _favoriteIds.contains(item.id);
    setState(() {
      if (currentlyFav) {
        _favoriteIds.remove(item.id);
      } else {
        _favoriteIds.add(item.id);
      }
    });

    try {
      await _discoveryService.setHomestayWishlist(item.id, save: !currentlyFav);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        if (currentlyFav) {
          _favoriteIds.add(item.id);
        } else {
          _favoriteIds.remove(item.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  void _openDetail(HomestayListingModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomestayDetailScreen(
          listingId: item.id,
          initialListing: item,
        ),
      ),
    ).then((_) => _loadHomestays());
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredListings;
    return CategoryPageScaffold(
      title: 'Homestays',
      subtitle: 'Authentic local stays across Sri Lanka',
      searchHint: 'Search homestays or locations...',
      searchController: _searchController,
      onSearchChanged: (_) {
        if (ArtisanDemoService.isDemoMode) {
          setState(() {});
        }
      },
      onSearchSubmitted: (_) => _loadHomestays(),
      onClearFilters: _clearFilters,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadHomestays,
      onRefresh: _loadHomestays,
      isDemoPreview: ArtisanDemoService.isDemoMode,
      filterBars: [
        CategoryChipFilterRow(
          options: _locations,
          selected: _selectedLocation,
          onSelected: (val) {
            setState(() => _selectedLocation = val);
            if (!ArtisanDemoService.isDemoMode) _loadHomestays();
          },
        ),
        CategoryChipFilterRow(
          options: _priceRanges,
          selected: _selectedPriceRange,
          onSelected: (val) {
            setState(() => _selectedPriceRange = val);
            if (!ArtisanDemoService.isDemoMode) _loadHomestays();
          },
        ),
      ],
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFav = _favoriteIds.contains(item.id);
        return CategoryListingCard(
          title: item.title,
          location: item.locationLabel,
          imageUrl: item.coverImageUrl,
          fallbackIcon: Icons.home_outlined,
          badgeText: item.propertyType,
          metaText: item.hostName.isNotEmpty
              ? 'Hosted by ${item.hostName}'
              : item.description,
          priceText: '${formatLkrAmount(item.price)} / night',
          showFavorite: true,
          isFavorite: isFav,
          onFavoriteTap: () => _toggleFavorite(item),
          primaryButtonLabel: 'View Details',
          onPrimaryTap: () => _openDetail(item),
          secondaryButtonLabel: 'Book Stay',
          onSecondaryTap: () => _openDetail(item),
        );
      },
    );
  }
}
