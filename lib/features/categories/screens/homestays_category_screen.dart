import 'package:flutter/material.dart';

import '../data/category_demo_data.dart';
import '../widgets/category_page_scaffold.dart';

class HomestaysCategoryScreen extends StatefulWidget {
  const HomestaysCategoryScreen({super.key});

  @override
  State<HomestaysCategoryScreen> createState() =>
      _HomestaysCategoryScreenState();
}

class _HomestaysCategoryScreenState extends State<HomestaysCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'All';
  String _selectedPriceRange = 'All Prices';
  final Set<String> _favoriteIds = {};

  static const _locations = ['All', 'Jaffna', 'Ella', 'Kandy', 'Galle'];
  static const _priceRanges = [
    'All Prices',
    'Under 10k',
    '10k - 20k',
    '20k+',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HomestayListingDemo> get _filteredListings {
    final query = _searchController.text.trim().toLowerCase();
    return CategoryDemoData.homestays.where((item) {
      if (_selectedLocation != 'All' && item.location != _selectedLocation) {
        return false;
      }
      if (_selectedPriceRange == 'Under 10k' && item.priceLkr >= 10000) {
        return false;
      }
      if (_selectedPriceRange == '10k - 20k' &&
          (item.priceLkr < 10000 || item.priceLkr > 20000)) {
        return false;
      }
      if (_selectedPriceRange == '20k+' && item.priceLkr <= 20000) {
        return false;
      }
      if (query.isNotEmpty &&
          !item.name.toLowerCase().contains(query) &&
          !item.location.toLowerCase().contains(query)) {
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
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredListings;
    return CategoryPageScaffold(
      title: 'Homestays',
      subtitle: 'Authentic local stays across Sri Lanka',
      searchHint: 'Search homestays or locations...',
      searchController: _searchController,
      onSearchChanged: (_) => setState(() {}),
      onClearFilters: _clearFilters,
      filterBars: [
        CategoryChipFilterRow(
          options: _locations,
          selected: _selectedLocation,
          onSelected: (val) => setState(() => _selectedLocation = val),
        ),
        CategoryChipFilterRow(
          options: _priceRanges,
          selected: _selectedPriceRange,
          onSelected: (val) => setState(() => _selectedPriceRange = val),
        ),
      ],
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFav = _favoriteIds.contains(item.id);
        return CategoryListingCard(
          title: item.name,
          location: item.location,
          imageUrl: item.imageUrl,
          fallbackIcon: Icons.home_outlined,
          metaText: '★ ${item.rating} (${item.reviewCount} reviews)',
          priceText: '${CategoryDemoData.formatLkr(item.priceLkr)} / night',
          showFavorite: true,
          isFavorite: isFav,
          onFavoriteTap: () {
            setState(() {
              if (isFav) {
                _favoriteIds.remove(item.id);
              } else {
                _favoriteIds.add(item.id);
              }
            });
          },
          primaryButtonLabel: 'View Details',
          onPrimaryTap: () => showCategoryDemoNotice(
            context,
            title: item.name,
            subtitle:
                '${item.location} • ${CategoryDemoData.formatLkr(item.priceLkr)} / night',
            description: item.description,
            icon: Icons.home_outlined,
          ),
          secondaryButtonLabel: 'Book Stay',
          onSecondaryTap: () => showCategoryDemoNotice(
            context,
            title: 'Booking Preview: ${item.name}',
            subtitle: '${CategoryDemoData.formatLkr(item.priceLkr)} / night',
            description:
                'Select dates and confirm reservations once homestay booking contracts are connected.',
            icon: Icons.event_available_outlined,
          ),
        );
      },
    );
  }
}

