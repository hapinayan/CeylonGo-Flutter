import 'package:flutter/material.dart';

/// Section H: Floating CeylonGo Bottom Navigation Bar
/// Features 5 items: Home, Explore, AI Planner, Community, Profile.
/// Active Home state has rounded light-blue indicator pill.
/// Center AI Planner button is emphasized with elevated blue circle and sparkle star icon.
class HomeBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const HomeBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Home (Active by default)
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  inactiveIcon: Icons.home_outlined,
                  label: 'Home',
                  isActive: currentIndex == 0,
                ),
              ),

              // 2. Explore
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  icon: Icons.explore_rounded,
                  inactiveIcon: Icons.explore_outlined,
                  label: 'Explore',
                  isActive: currentIndex == 1,
                ),
              ),

              // 3. Central AI Planner (Emphasized Button)
              Expanded(
                child: _buildCenterAiPlannerButton(context),
              ),

              // 4. Community
              Expanded(
                child: _buildNavItem(
                  index: 3,
                  icon: Icons.people_rounded,
                  inactiveIcon: Icons.people_outline_rounded,
                  label: 'Community',
                  isActive: currentIndex == 3,
                ),
              ),

              // 5. Profile
              Expanded(
                child: _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  inactiveIcon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isActive: currentIndex == 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      key: Key('bottom_nav_${label.toLowerCase()}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 6 : 4,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? icon : inactiveIcon,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAiPlannerButton(BuildContext context) {
    final isActive = currentIndex == 2;

    return GestureDetector(
      key: const Key('bottom_nav_ai_planner'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(2),
      child: OverflowBox(
        maxHeight: 76,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'AI Planner',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
