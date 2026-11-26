import 'package:flutter/material.dart';

import '../data/category_demo_data.dart';
import '../widgets/category_page_scaffold.dart';

class LocalGuidesCategoryScreen extends StatefulWidget {
  const LocalGuidesCategoryScreen({super.key});

  @override
  State<LocalGuidesCategoryScreen> createState() =>
      _LocalGuidesCategoryScreenState();
}

class _LocalGuidesCategoryScreenState extends State<LocalGuidesCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'All';
  String _selectedLanguage = 'All Languages';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LocalGuideDemo> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return CategoryDemoData.guides.where((guide) {
      if (_selectedLocation != 'All' && guide.region != _selectedLocation) {
        return false;
      }
      if (_selectedLanguage != 'All Languages' &&
          !guide.languages.contains(_selectedLanguage)) {
        return false;
      }
      if (query.isNotEmpty &&
          !guide.name.toLowerCase().contains(query) &&
          !guide.region.toLowerCase().contains(query) &&
          !guide.languages.join(' ').toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
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
      onClearFilters: () {
        setState(() {
          _searchController.clear();
          _selectedLocation = 'All';
          _selectedLanguage = 'All Languages';
        });
      },
      filterBars: [
        CategoryChipFilterRow(
          options: _locations,
          selected: _selectedLocation,
          onSelected: (val) => setState(() => _selectedLocation = val),
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
        return CategoryListingCard(
          title: guide.name,
          location: '${guide.region} • ${guide.experience}',
          imageUrl: guide.imageUrl,
          fallbackIcon: Icons.person_outline_rounded,
          badgeText: guide.languages.join(' • '),
          badgeColor: const Color(0xFFEA580C),
          metaText: '★ ${guide.rating} • ${guide.bio}',
          primaryButtonLabel: 'View Profile',
          onPrimaryTap: () => showCategoryDemoNotice(
            context,
            title: guide.name,
            subtitle:
                '${guide.region} • ${guide.experience} • ★ ${guide.rating}',
            description:
                'Languages: ${guide.languages.join(', ')}\n\n${guide.bio}',
            icon: Icons.person_outline_rounded,
          ),
          secondaryButtonLabel: 'Request Guide',
          onSecondaryTap: () => showCategoryDemoNotice(
            context,
            title: 'Guide Inquiry Preview',
            subtitle: '${guide.name} (${guide.region})',
            description:
                'Direct guide messaging and booking requests are not yet connected in demo mode.',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        );
      },
    );
  }
}

