import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../data/category_demo_data.dart';
import '../models/discovery_models.dart';
import '../services/discovery_service.dart';
import '../widgets/category_page_scaffold.dart';
import 'activity_detail_screen.dart';

class ActivitiesCategoryScreen extends StatefulWidget {
  final DiscoveryService? discoveryService;
  final SecureStorageService? storageService;

  const ActivitiesCategoryScreen({
    super.key,
    this.discoveryService,
    this.storageService,
  });

  @override
  State<ActivitiesCategoryScreen> createState() =>
      _ActivitiesCategoryScreenState();
}

class _ActivitiesCategoryScreenState extends State<ActivitiesCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final DiscoveryService _discoveryService;
  late final SecureStorageService _storage;

  String _selectedCategory = 'All';
  List<ActivityListingModel> _items = [];
  final Set<int> _favoriteIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  static const _categories = [
    'All',
    'Hiking',
    'Surfing',
    'Cycling',
    'Wildlife',
    'Cultural',
    'Water Sports',
  ];

  static const Map<String, String> _categoryParamMap = {
    'Hiking': 'hiking',
    'Surfing': 'surfing',
    'Cycling': 'cycling',
    'Wildlife': 'wildlife',
    'Cultural': 'cultural',
    'Water Sports': 'water_sports',
  };

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _storage = widget.storageService ?? SecureStorageService();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    if (ArtisanDemoService.isDemoMode) {
      setState(() {
        _items = CategoryDemoData.activities
            .asMap()
            .entries
            .map(
              (entry) => ActivityListingModel(
                id: entry.key + 1,
                title: entry.value.name,
                description: entry.value.description,
                district: entry.value.location,
                locality: entry.value.location,
                pricePerParticipant: entry.value.priceLkr.toString(),
                providerName: 'Demo Provider',
                category: entry.value.category,
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
      final items = await _discoveryService.searchActivities(
        destination: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        category: _categoryParamMap[_selectedCategory],
      );

      final savedIds = <int>{};
      if (await _storage.hasToken()) {
        try {
          final wl = await _discoveryService.getActivityWishlist();
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
        _errorMessage = 'Unable to load adventure activities.';
      });
    }
  }

  Future<void> _toggleFavorite(ActivityListingModel item) async {
    if (ArtisanDemoService.isDemoMode) return;
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to save activities.'),
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
      await _discoveryService.setActivityWishlist(item.id, save: !currentlyFav);
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

  List<ActivityListingModel> get _filteredItems {
    if (!ArtisanDemoService.isDemoMode) return _items;
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      if (_selectedCategory != 'All' &&
          item.category.toLowerCase() != _selectedCategory.toLowerCase()) {
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

  void _openDetail(ActivityListingModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailScreen(
          listingId: item.id,
          initialListing: item,
        ),
      ),
    ).then((_) => _loadActivities());
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    return CategoryPageScaffold(
      title: 'Activities',
      subtitle: 'Adventures & cultural experiences',
      searchHint: 'Search by destination (e.g. Ella, Kandy)...',
      searchController: _searchController,
      onSearchChanged: (_) {
        if (ArtisanDemoService.isDemoMode) setState(() {});
      },
      onSearchSubmitted: (_) => _loadActivities(),
      onClearFilters: () {
        setState(() {
          _searchController.clear();
          _selectedCategory = 'All';
        });
        _loadActivities();
      },
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadActivities,
      onRefresh: _loadActivities,
      isDemoPreview: ArtisanDemoService.isDemoMode,
      filterBars: [
        CategoryChipFilterRow(
          options: _categories,
          selected: _selectedCategory,
          onSelected: (val) {
            setState(() => _selectedCategory = val);
            if (!ArtisanDemoService.isDemoMode) _loadActivities();
          },
        ),
      ],
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFav = _favoriteIds.contains(item.id);
        return CategoryListingCard(
          title: item.title,
          location: '${item.locationLabel} • ${item.durationMinutes} min',
          imageUrl: item.coverImageUrl,
          fallbackIcon: Icons.terrain_rounded,
          badgeText: item.category,
          badgeColor: const Color(0xFF0284C7),
          metaText: item.description,
          priceText: formatLkrAmount(item.pricePerParticipant),
          showFavorite: !ArtisanDemoService.isDemoMode,
          isFavorite: isFav,
          onFavoriteTap: () => _toggleFavorite(item),
          primaryButtonLabel: 'View Details',
          onPrimaryTap: () => _openDetail(item),
          secondaryButtonLabel: 'Book Activity',
          onSecondaryTap: () => _openDetail(item),
        );
      },
    );
  }
}
