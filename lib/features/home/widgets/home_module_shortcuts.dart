import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../artisan/services/artisan_demo_service.dart';

class ModuleItem {
  final String id;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String? route;
  final String? keyName;

  const ModuleItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.route,
    this.keyName,
  });
}

/// Section C: Six Module Shortcuts
/// Displays 6 pastel-colored rounded icon shortcuts:
/// Homestays, Eco Tourism, Activities, Tour Guides, Rentals, Artisan.
/// Features staggered entrance animations and smooth press feedback.
class HomeModuleShortcuts extends StatelessWidget {
  final Animation<double> animation;

  const HomeModuleShortcuts({super.key, required this.animation});

  static const List<ModuleItem> modules = [
    ModuleItem(
      id: 'homestays',
      label: 'Homestays',
      icon: Icons.home_outlined,
      backgroundColor: Color(0xFFEEF4FF),
      iconColor: Color(0xFF2563EB),
      keyName: 'shortcut_homestays',
    ),
    ModuleItem(
      id: 'eco_tourism',
      label: 'Eco\nTourism',
      icon: Icons.eco_outlined,
      backgroundColor: Color(0xFFECFDF5),
      iconColor: Color(0xFF10B981),
      keyName: 'shortcut_eco_tourism',
    ),
    ModuleItem(
      id: 'activities',
      label: 'Activities',
      icon: Icons.terrain_outlined,
      backgroundColor: Color(0xFFF0F7FF),
      iconColor: Color(0xFF0284C7),
      keyName: 'shortcut_activities',
    ),
    ModuleItem(
      id: 'tour_guides',
      label: 'Tour\nGuides',
      icon: Icons.people_alt_outlined,
      backgroundColor: Color(0xFFFFF7ED),
      iconColor: Color(0xFFF97316),
      keyName: 'shortcut_tour_guides',
    ),
    ModuleItem(
      id: 'rentals',
      label: 'Rentals',
      icon: Icons.directions_bike_outlined,
      backgroundColor: Color(0xFFEFF6FF),
      iconColor: Color(0xFF2563EB),
      keyName: 'shortcut_rentals',
    ),
    ModuleItem(
      id: 'artisan',
      label: 'Artisan',
      icon: Icons.shopping_bag_outlined,
      backgroundColor: Color(0xFFFAF5FF),
      iconColor: Color(0xFFA855F7),
      route: '/artisan',
      keyName: 'shortcut_artisan',
    ),
  ];

  void _onModuleTap(BuildContext context, ModuleItem item) {
    if (item.id == 'artisan') {
      if (ArtisanDemoService.isDemoMode) {
        ArtisanDemoService.instance.resetToDefaults();
      }
      Navigator.pushNamed(context, '/artisan');
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.label.replaceAll('\n', ' ')} module is coming soon!',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryNavy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTiny = screenWidth < 350;
    final isNarrow = screenWidth < 380;
    final iconBoxSize = isTiny ? 36.0 : (isNarrow ? 40.0 : 42.0);
    final iconSize = isTiny ? 19.0 : (isNarrow ? 20.0 : 21.0);
    final fontSize = isTiny ? 9.5 : (isNarrow ? 10.0 : 10.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(modules.length, (index) {
          final item = modules[index];

          // Staggered interval: 0.15 + (index * 0.08)
          final start = (0.15 + (index * 0.08)).clamp(0.0, 0.9);
          final end = (start + 0.3).clamp(0.0, 1.0);

          final itemSlide =
              Tween<Offset>(
                begin: const Offset(0, 0.35),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                ),
              );

          final itemScale = Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(start, end, curve: Curves.easeOutBack),
            ),
          );

          final itemFade = CurvedAnimation(
            parent: animation,
            curve: Interval(start, end, curve: Curves.easeIn),
          );

          return Expanded(
            child: SlideTransition(
              position: itemSlide,
              child: ScaleTransition(
                scale: itemScale,
                child: FadeTransition(
                  opacity: itemFade,
                  child: _ModuleShortcutButton(
                    item: item,
                    iconBoxSize: iconBoxSize,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    onTap: () => _onModuleTap(context, item),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ModuleShortcutButton extends StatefulWidget {
  final ModuleItem item;
  final double iconBoxSize;
  final double iconSize;
  final double fontSize;
  final VoidCallback onTap;

  const _ModuleShortcutButton({
    required this.item,
    required this.iconBoxSize,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
  });

  @override
  State<_ModuleShortcutButton> createState() => _ModuleShortcutButtonState();
}

class _ModuleShortcutButtonState extends State<_ModuleShortcutButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        key: widget.item.keyName != null ? Key(widget.item.keyName!) : null,
        onTapDown: (_) => setState(() => _scale = 0.94),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: widget.iconBoxSize,
              height: widget.iconBoxSize,
              decoration: BoxDecoration(
                color: widget.item.backgroundColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: widget.item.iconColor.withAlpha(20),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.item.iconColor.withAlpha(12),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.item.icon,
                color: widget.item.iconColor,
                size: widget.iconSize,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 24,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: Text(
                  widget.item.label,
                  textAlign: TextAlign.center,
                  maxLines: widget.item.label.contains('\n') ? 2 : 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
