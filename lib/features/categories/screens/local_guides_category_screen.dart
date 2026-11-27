import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../../auth/models/api_error.dart';
import '../data/category_demo_data.dart';
import '../models/discovery_models.dart';
import '../services/discovery_service.dart';
import '../widgets/category_page_scaffold.dart';
import 'tour_guide_detail_screen.dart';

class LocalGuidesCategoryScreen extends StatefulWidget {
  final DiscoveryService? discoveryService;
  final SecureStorageService? storageService;

  const LocalGuidesCategoryScreen({
    super.key,
    this.discoveryService,
    this.storageService,
  });

  @override
  State<LocalGuidesCategoryScreen> createState() =>
      _LocalGuidesCategoryScreenState();
}

class _LocalGuidesCategoryScreenState extends State<LocalGuidesCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final DiscoveryService _discoveryService;
  late final SecureStorageService _storage;

  String _selectedLocation = 'All';
  String _selectedLanguage = 'All Languages';
  List<TourGuideListingModel> _items = [];
  final Set<int> _favoriteIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  static const _locations = ['All', 'Kandy', 'Jaffna', 'Ella', 'Galle'];
  static const _languages = [
    'All Languages',
    'English',
    'Sinhala',
    'Tamil',
    'German',
    'French',
  ];

  @override
  void initState() {
    super.initState();
    _discoveryService = widget.discoveryService ?? DiscoveryService();
    _storage = widget.storageService ?? SecureStorageService();
    _loadGuides();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuides() async {
    if (ArtisanDemoService.isDemoMode) {
      setState(() {
        _items = CategoryDemoData.guides
            .asMap()
            .entries
            .map(
              (entry) => TourGuideListingModel(
                id: entry.key + 1,
                title: entry.value.name,
                description: entry.value.bio,
                district: entry.value.region,
                locality: entry.value.region,
                price: '5000',
                providerName: entry.value.name,
                languages: entry.value.languages,
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
      final destination = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : (_selectedLocation != 'All' ? _selectedLocation : null);
      final items = await _discoveryService.searchTourGuides(
        destination: destination,
      );

      final savedIds = <int>{};
      if (await _storage.hasToken()) {
        try {
          final wl = await _discoveryService.getTourGuideWishlist();
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
        _errorMessage = 'Unable to load tour guides.';
      });
    }
  }

  Future<void> _toggleFavorite(TourGuideListingModel item) async {
    if (ArtisanDemoService.isDemoMode) return;
    if (!await _storage.hasToken()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to save tour guides.'),
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
      await _discoveryService.setTourGuideWishlist(item.id, save: !currentlyFav);
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

  List<TourGuideListingModel> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((guide) {
      if (_selectedLocation != 'All' &&
          !guide.district
              .toLowerCase()
              .contains(_selectedLocation.toLowerCase()) &&
          !guide.locality
              .toLowerCase()
              .contains(_selectedLocation.toLowerCase())) {
        return false;
      }
      if (_selectedLanguage != 'All Languages' &&
          !guide.languages.any(
            (l) => l.toLowerCase() == _selectedLanguage.toLowerCase(),
          )) {
        return false;
      }
      if (query.isNotEmpty &&
          !guide.title.toLowerCase().contains(query) &&
          !guide.providerName.toLowerCase().contains(query) &&
          !guide.district.toLowerCase().contains(query) &&
          !guide.languages.join(' ').toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openDetail(TourGuideListingModel guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TourGuideDetailScreen(
          listingId: guide.id,
          initialListing: guide,
        ),
      ),
    ).then((_) => _loadGuides());
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    return CategoryPageScaffold(
      title: 'Local Guides',
      subtitle: 'Experienced Sri Lankan tour hosts',
      searchHint: 'Search guides, regions, languages...',
      searchController: _searchController,
      onSearchChanged: (_) => setState(() {}),
      onSearchSubmitted: (_) => _loadGuides(),
      onClearFilters: () {
        setState(() {
          _searchController.clear();
          _selectedLocation = 'All';
          _selectedLanguage = 'All Languages';
        });
        _loadGuides();
      },
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadGuides,
      onRefresh: _loadGuides,
      isDemoPreview: ArtisanDemoService.isDemoMode,
      filterBars: [
        CategoryChipFilterRow(
          options: _locations,
          selected: _selectedLocation,
          onSelected: (val) {
            setState(() => _selectedLocation = val);
            if (!ArtisanDemoService.isDemoMode) _loadGuides();
          },
        ),
        CategoryChipFilterRow(
          options: _languages,
          selected: _selectedLanguage,
          onSelected: (val) => setState(() => _selectedLanguage = val),
        ),
      ],
      itemCount: items.length,
      itemBuilder: (context, index) {
        final guide = items[index];
        final isFav = _favoriteIds.contains(guide.id);
        return CategoryListingCard(
          title: guide.title,
          location:
              '${guide.locationLabel}${guide.yearsOfExperience > 0 ? ' • ${guide.yearsOfExperience} yrs exp' : ''}',
          imageUrl: guide.coverImageUrl,
          fallbackIcon: Icons.person_outline_rounded,
          badgeText: guide.languages.isNotEmpty
              ? guide.languages.join(' • ')
              : '${guide.packages.length} package(s)',
          badgeColor: const Color(0xFFEA580C),
          metaText: guide.description,
          priceText: guide.packages.isNotEmpty
              ? 'From ${formatLkrAmount(guide.packages.first.price)}'
              : formatLkrAmount(guide.price),
          showFavorite: !ArtisanDemoService.isDemoMode,
          isFavorite: isFav,
          onFavoriteTap: () => _toggleFavorite(guide),
          primaryButtonLabel: 'View Profile',
          onPrimaryTap: () => _openDetail(guide),
          secondaryButtonLabel: 'Book Guide',
          onSecondaryTap: () => _openDetail(guide),
        );
      },
    );
  }
}
