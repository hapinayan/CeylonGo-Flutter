import 'package:flutter/material.dart';

/// Provider Bottom Navigation Bar
/// 5 tabs: Home | Bookings | Add | Reports | Profile
/// Features a prominent elevated blue circular Add button in the center
class ProviderBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  const ProviderBottomNavigation({
    super.key,
    this.currentIndex = 0,
    required this.onTabSelected,
    required this.onAddPressed,
  });

  Widget _buildNavItem({
    required Key key,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        key: key,
        onTap: () => onTabSelected(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Home
              _buildNavItem(
                key: const Key('nav_home'),
                activeIcon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
                index: 0,
              ),

              // 2. Bookings
              _buildNavItem(
                key: const Key('nav_bookings'),
                activeIcon: Icons.calendar_month_rounded,
                inactiveIcon: Icons.calendar_month_outlined,
                label: 'Bookings',
                index: 1,
              ),

              // 3. Circular Blue Add Button in Center
              Expanded(
                child: Center(
                  heightFactor: 1.0,
                  child: GestureDetector(
                    key: const Key('nav_add_button'),
                    onTap: onAddPressed,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF1D4ED8),
                            Color(0xFF2563EB),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x402563EB),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Reports
              _buildNavItem(
                key: const Key('nav_reports'),
                activeIcon: Icons.bar_chart_rounded,
                inactiveIcon: Icons.bar_chart_outlined,
                label: 'Reports',
                index: 2,
              ),

              // 5. Profile
              _buildNavItem(
                key: const Key('nav_profile'),
                activeIcon: Icons.person_rounded,
                inactiveIcon: Icons.person_outline_rounded,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
