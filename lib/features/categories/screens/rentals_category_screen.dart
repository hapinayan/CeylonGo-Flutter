import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../data/category_demo_data.dart';
import '../models/discovery_models.dart';
import '../services/discovery_service.dart';
import '../widgets/category_page_scaffold.dart';
import 'rental_detail_screen.dart';

class RentalsCategoryScreen extends StatefulWidget {
  final DiscoveryService? discoveryService;
  final SecureStorageService? storageService;

  const RentalsCategoryScreen({
    super.key,
    this.discoveryService,
    this.storageService,
  });

  @override
  State<RentalsCategoryScreen> createState() => _RentalsCategoryScreenState();
}

class _RentalsCategoryScreenState extends State<RentalsCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final DiscoveryService _discoveryService;
  late final SecureStorageService _storage;

  String _selectedCategory = 'All';
  List<RentalVehicleModel> _items = [];
  final Set<int> _favoriteIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  static const _categories = ['All', 'Bikes', 'Bicycles'];
  static const Map<String, String> _typeParamMap = {
    'Bikes': 'bike',
    'Bicycles': 'bicycle',
  };

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _storage = widget.storageService ?? SecureStorageService();
    _loadRentals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRentals() async {
    if (ArtisanDemoService.isDemoMode) {
      setState(() {
        _items = CategoryDemoData.rentals
            .asMap()
            .entries
            .map(
              (entry) => RentalVehicleModel(
                id: entry.key + 1,
                providerId: 1,
                vehicleType: 'bike',
                category: entry.value.category,
                vehicleName: entry.value.name,
                description: entry.value.description,
                pricePerDay: entry.value.pricePerDayLkr.toString(),
                transmission: entry.value.transmission,
                district: entry.value.location,
                city: entry.value.location,
                primaryImageUrl: entry.value.imageUrl,
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
      final items = await _discoveryService.searchRentals(
        district: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        vehicleType: _typeParamMap[_selectedCategory],
      );

      final savedIds = <int>{};
      if (await _storage.hasToken()) {
        try {
          final wl = await _discoveryService.getRentalWishlist();
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
        _errorMessage = 'Unable to load rental vehicles.';
      });
    }
  }

  Future<void> _toggleFavorite(RentalVehicleModel item) async {
    if (ArtisanDemoService.isDemoMode) return;
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to save rental vehicles.'),
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
      await _discoveryService.setRentalWishlist(item.id, save: !currentlyFav);
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

  List<RentalVehicleModel> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) {
      return item.vehicleName.toLowerCase().contains(query) ||
          item.locationLabel.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  void _openDetail(RentalVehicleModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RentalDetailScreen(
          vehicleId: item.id,
          initialVehicle: item,
        ),
      ),
    ).then((_) => _loadRentals());
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    return CategoryPageScaffold(
      title: 'Bike & Bicycle Rentals',
      subtitle: 'Motorbikes, scooters & bicycles for island travel',
      searchHint: 'Search districts or vehicle names...',
      searchController: _searchController,
      onSearchChanged: (_) => setState(() {}),
      onSearchSubmitted: (_) => _loadRentals(),
      onClearFilters: () {
        setState(() {
          _searchController.clear();
          _selectedCategory = 'All';
        });
        _loadRentals();
      },
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadRentals,
      onRefresh: _loadRentals,
      isDemoPreview: ArtisanDemoService.isDemoMode,
      filterBars: [
        CategoryChipFilterRow(
          options: _categories,
          selected: _selectedCategory,
          onSelected: (val) {
            setState(() => _selectedCategory = val);
            if (!ArtisanDemoService.isDemoMode) _loadRentals();
          },
        ),
      ],
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFav = _favoriteIds.contains(item.id);
        return CategoryListingCard(
          title: item.vehicleName,
          location:
              '${item.locationLabel}${item.transmission != null ? ' • ${item.transmission}' : ''}',
          imageUrl: item.primaryImageUrl,
          fallbackIcon: Icons.directions_bike_outlined,
          badgeText: item.vehicleType.toUpperCase(),
          badgeColor: const Color(0xFF0A4DF5),
          metaText: item.description ??
              (item.requiresDrivingLicense
                  ? 'Driving license required'
                  : 'No driving license required'),
          priceText: '${formatLkrAmount(item.pricePerDay)} / day',
          showFavorite: !ArtisanDemoService.isDemoMode,
          isFavorite: isFav,
          onFavoriteTap: () => _toggleFavorite(item),
          primaryButtonLabel: 'Vehicle Details',
          onPrimaryTap: () => _openDetail(item),
          secondaryButtonLabel: 'Rent Vehicle',
          onSecondaryTap: () => _openDetail(item),
        );
      },
    );
  }
}
