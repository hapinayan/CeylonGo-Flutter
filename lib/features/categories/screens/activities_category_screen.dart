import 'package:flutter/material.dart';

import '../data/category_demo_data.dart';
import '../widgets/category_page_scaffold.dart';

class ActivitiesCategoryScreen extends StatefulWidget {
  const ActivitiesCategoryScreen({super.key});

  @override
  State<ActivitiesCategoryScreen> createState() =>
      _ActivitiesCategoryScreenState();
}

class _ActivitiesCategoryScreenState extends State<ActivitiesCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'Hiking',
    'Surfing',
    'Cycling',
    'Cultural Experiences',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityDemo> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return CategoryDemoData.activities.where((item) {
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
      title: 'Activities',
      subtitle: 'Adventures & cultural experiences',
      searchHint: 'Search hiking, surfing, cycling...',
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
          location: '${item.location} • ${item.duration}',
          imageUrl: item.imageUrl,
          fallbackIcon: Icons.terrain_rounded,
          badgeText: item.category,
          badgeColor: const Color(0xFF0284C7),
          metaText: item.description,
          priceText: CategoryDemoData.formatLkr(item.priceLkr),
          primaryButtonLabel: 'View Details',
          onPrimaryTap: () => showCategoryDemoNotice(
            context,
            title: item.name,
            subtitle:
                '${item.location} • ${item.duration} • ${CategoryDemoData.formatLkr(item.priceLkr)}',
            description: item.description,
            icon: Icons.terrain_rounded,
          ),
          secondaryButtonLabel: 'Book Activity',
          onSecondaryTap: () => showCategoryDemoNotice(
            context,
            title: 'Activity Booking Preview',
            subtitle: '${item.name} • ${CategoryDemoData.formatLkr(item.priceLkr)}',
            description:
                'Activity slot selection and payment will be enabled when backend booking is connected.',
            icon: Icons.event_available_outlined,
          ),
        );
      },
    );
  }
}

