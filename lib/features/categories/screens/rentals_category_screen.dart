import 'package:flutter/material.dart';

import '../data/category_demo_data.dart';
import '../widgets/category_page_scaffold.dart';

class RentalsCategoryScreen extends StatefulWidget {
  const RentalsCategoryScreen({super.key});

  @override
  State<RentalsCategoryScreen> createState() => _RentalsCategoryScreenState();
}

class _RentalsCategoryScreenState extends State<RentalsCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Cars', 'Bikes', 'Scooters'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VehicleRentalDemo> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return CategoryDemoData.rentals.where((item) {
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty &&
          !item.name.toLowerCase().contains(query) &&
          !item.location.toLowerCase().contains(query) &&
          !item.category.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    return CategoryPageScaffold(
      title: 'Rentals',
      subtitle: 'Cars, scooters & bikes for island travel',
      searchHint: 'Search vehicles or cities...',
      searchController: _searchController,
      onSearchChanged: (_) => setState(() {}),
      onClearFilters: () {
        setState(() {
          _searchController.clear();
          _selectedCategory = 'All';
        });
      },
      filterBars: [
        CategoryChipFilterRow(
          options: _categories,
          selected: _selectedCategory,
          onSelected: (val) => setState(() => _selectedCategory = val),
        ),
      ],
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CategoryListingCard(
          title: item.name,
          location: '${item.location} • ${item.transmission}',
          imageUrl: item.imageUrl,
          fallbackIcon: Icons.directions_bike_outlined,
          badgeText: item.category,
          badgeColor: const Color(0xFF0A4DF5),
          metaText: item.description,
          priceText: '${CategoryDemoData.formatLkr(item.pricePerDayLkr)} / day',
          primaryButtonLabel: 'Vehicle Details',
          onPrimaryTap: () => showCategoryDemoNotice(
            context,
            title: item.name,
            subtitle:
                '${item.location} • ${item.transmission} • ${CategoryDemoData.formatLkr(item.pricePerDayLkr)} / day',
            description: item.description,
            icon: Icons.directions_car_outlined,
          ),
          secondaryButtonLabel: 'Rent Vehicle',
          onSecondaryTap: () => showCategoryDemoNotice(
            context,
            title: 'Rental Booking Preview',
            subtitle:
                '${item.name} • ${CategoryDemoData.formatLkr(item.pricePerDayLkr)} / day',
            description:
                'Pickup dates, license verification, and payment are not connected in demo mode.',
            icon: Icons.event_available_outlined,
          ),
        );
      },
    );
  }
}

