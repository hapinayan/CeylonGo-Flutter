import 'package:flutter/material.dart';

import '../../artisan/services/artisan_demo_service.dart';
import '../data/category_demo_data.dart';
import '../widgets/category_page_scaffold.dart';

class EcoTourismCategoryScreen extends StatefulWidget {
  const EcoTourismCategoryScreen({super.key});

  @override
  State<EcoTourismCategoryScreen> createState() =>
      _EcoTourismCategoryScreenState();
}

class _EcoTourismCategoryScreenState extends State<EcoTourismCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Eco Stays', 'Nature Experiences'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EcoExperienceDemo> get _filteredItems {
    if (!ArtisanDemoService.isDemoMode) {
      return const [];
    }
    final query = _searchController.text.trim().toLowerCase();
    return CategoryDemoData.ecoExperiences.where((item) {
      if (_selectedCategory != 'All' && item.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty &&
          !item.name.toLowerCase().contains(query) &&
          !item.location.toLowerCase().contains(query) &&
          !item.description.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    return CategoryPageScaffold(
      title: 'Eco Tourism',
      subtitle: 'Sustainable stays & Sri Lankan nature',
      searchHint: 'Search eco destinations...',
      searchController: _searchController,
      onSearchChanged: (_) => setState(() {}),
      onClearFilters: () {
        setState(() {
          _searchController.clear();
          _selectedCategory = 'All';
        });
      },
      isDemoPreview: ArtisanDemoService.isDemoMode,
      emptyTitle: ArtisanDemoService.isDemoMode
          ? 'No matching listings found'
          : 'Eco Tourism is not a separate MVP module',
      emptySubtitle: ArtisanDemoService.isDemoMode
          ? 'Try adjusting your search or filter selections.'
          : 'Explore nature experiences under Adventure Activities or local stays under Homestays.',
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
          location: item.location,
          imageUrl: item.imageUrl,
          fallbackIcon: Icons.eco_outlined,
          badgeText: item.ecoBadge,
          badgeColor: const Color(0xFF16A34A),
          metaText: item.description,
          primaryButtonLabel: 'View Details',
          onPrimaryTap: () => showCategoryDemoNotice(
            context,
            title: item.name,
            subtitle: '${item.category} • ${item.location}',
            description: '${item.ecoBadge}\n\n${item.description}',
            icon: Icons.eco_outlined,
          ),
        );
      },
    );
  }
}
