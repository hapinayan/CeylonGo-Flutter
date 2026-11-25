import 'package:flutter/material.dart';

class CategoryFilterItem {
  final String id;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String keyName;

  const CategoryFilterItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.keyName,
  });
}

/// Section C: Horizontally Scrollable Category Filter Row
/// Displays exactly 6 category filter pills immediately below the search bar:
/// All, Homestays, Eco, Activities, Guides, Rentals.
class HomeCategoryFilters extends StatelessWidget {
  final Animation<double> animation;
  final String selectedCategoryId;
  final ValueChanged<CategoryFilterItem>? onCategorySelected;

  const HomeCategoryFilters({
    super.key,
    required this.animation,
    this.selectedCategoryId = 'all',
    this.onCategorySelected,
  });

  static const Color activeBlue = Color(0xFF0A4DF5);

  static const List<CategoryFilterItem> categories = [
    CategoryFilterItem(
      id: 'all',
      label: 'All',
      icon: Icons.language_rounded,
      backgroundColor: activeBlue,
      iconColor: Colors.white,
      keyName: 'category_filter_all',
    ),
    CategoryFilterItem(
      id: 'homestays',
      label: 'Homestays',
      icon: Icons.home_outlined,
      backgroundColor: Color(0xFFF3F7FF),
      iconColor: Color(0xFF1D4ED8),
      keyName: 'category_filter_homestays',
    ),
    CategoryFilterItem(
      id: 'eco',
      label: 'Eco',
      icon: Icons.eco_outlined,
      backgroundColor: Color(0xFFEDFBF3),
      iconColor: Color(0xFF16A34A),
      keyName: 'category_filter_eco',
    ),
    CategoryFilterItem(
      id: 'activities',
      label: 'Activities',
      icon: Icons.terrain_rounded,
      backgroundColor: Color(0xFFF0F9FF),
      iconColor: Color(0xFF0284C7),
      keyName: 'category_filter_activities',
    ),
    CategoryFilterItem(
      id: 'guides',
      label: 'Guides',
      icon: Icons.people_outline_rounded,
      backgroundColor: Color(0xFFFFF7ED),
      iconColor: Color(0xFFEA580C),
      keyName: 'category_filter_guides',
    ),
    CategoryFilterItem(
      id: 'rentals',
      label: 'Rentals',
      icon: Icons.directions_bike_outlined,
      backgroundColor: Color(0xFFEFF6FF),
      iconColor: Color(0xFF2563EB),
      keyName: 'category_filter_rentals',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.15, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.15, 0.7, curve: Curves.easeIn),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            children: List.generate(categories.length, (index) {
              final item = categories[index];
              final isSelected = item.id == selectedCategoryId;

              return Padding(
                padding: EdgeInsets.only(
                  right: index == categories.length - 1 ? 0.0 : 8.0,
                ),
                child: _CategoryFilterChip(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onCategorySelected?.call(item),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatefulWidget {
  final CategoryFilterItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryFilterChip> createState() => _CategoryFilterChipState();
}

class _CategoryFilterChipState extends State<_CategoryFilterChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final bgColor =
        isSelected ? HomeCategoryFilters.activeBlue : widget.item.backgroundColor;
    final fgColor = isSelected ? Colors.white : widget.item.iconColor;
    final labelColor = isSelected ? Colors.white : const Color(0xFF0F172A);

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        key: Key(widget.item.keyName),
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 52, minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? null
                : Border.all(
                    color: const Color(0xFFE2E8F0).withAlpha(140),
                    width: 1.0,
                  ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? HomeCategoryFilters.activeBlue.withAlpha(45)
                    : Colors.black.withAlpha(12),
                blurRadius: isSelected ? 10 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                color: fgColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

