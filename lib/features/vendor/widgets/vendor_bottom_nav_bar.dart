import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Fixed 4-item floating white bottom navigation bar for the Vendor app:
/// 0: Home (/vendor/dashboard)
/// 1: My Listings (/vendor/listings)
/// 2: Bookings (/vendor/bookings)
/// 3: More (/vendor/more)
class VendorBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const VendorBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  static const Color _royalBlue = Color(0xFF0A4DF5);
  static const Color _mutedGray = Color(0xFF64748B);

  static const List<({
    Key key,
    String label,
    IconData activeIcon,
    IconData icon,
    String route,
  })> _items = [
    (
      key: Key('vendor_nav_home'),
      label: 'Home',
      activeIcon: Icons.home_rounded,
      icon: Icons.home_outlined,
      route: '/vendor/dashboard',
    ),
    (
      key: Key('vendor_nav_listings'),
      label: 'My Listings',
      activeIcon: Icons.list_alt_rounded,
      icon: Icons.list_alt_outlined,
      route: '/vendor/listings',
    ),
    (
      key: Key('vendor_nav_bookings'),
      label: 'Bookings',
      activeIcon: Icons.calendar_month_rounded,
      icon: Icons.calendar_month_outlined,
      route: '/vendor/bookings',
    ),
    (
      key: Key('vendor_nav_more'),
      label: 'More',
      activeIcon: Icons.more_horiz_rounded,
      icon: Icons.more_horiz_rounded,
      route: '/vendor/more',
    ),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    final targetRoute = _items[index].route;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        targetRoute,
        (route) => false,
      );
      return;
    }

    if (currentIndex == 0) {
      Navigator.pushNamed(context, targetRoute);
    } else {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(16),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = index == currentIndex;
              final color = isSelected ? _royalBlue : _mutedGray;

              return Expanded(
                child: InkWell(
                  key: item.key,
                  onTap: () => _onTap(context, index),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: 22,
                          color: color,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? _royalBlue
                                : AppTheme.primaryNavy.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

