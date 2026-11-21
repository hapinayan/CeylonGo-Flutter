import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Section E: Quick Actions Card
/// Displays 4 action shortcuts: My Bookings, Saved, Promotions, Community
/// in a clean white rounded card matching the approved reference screenshot.
class HomeQuickActions extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback? onBookingsTap;
  final VoidCallback? onSavedTap;
  final VoidCallback? onPromotionsTap;
  final VoidCallback? onCommunityTap;

  const HomeQuickActions({
    super.key,
    required this.animation,
    this.onBookingsTap,
    this.onSavedTap,
    this.onPromotionsTap,
    this.onCommunityTap,
  });

  @override
  Widget build(BuildContext context) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.35, 0.8, curve: Curves.easeIn),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    keyName: 'quick_action_bookings',
                    icon: Icons.event_note_outlined,
                    label: 'My Bookings',
                    onTap: onBookingsTap ??
                        () => Navigator.pushNamed(context, '/artisan/reservations'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFF1F5F9),
                ),
                Expanded(
                  child: _QuickActionButton(
                    keyName: 'quick_action_saved',
                    icon: Icons.favorite_border_rounded,
                    label: 'Saved',
                    onTap: onSavedTap ??
                        () => Navigator.pushNamed(context, '/artisan/wishlist'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFF1F5F9),
                ),
                Expanded(
                  child: _QuickActionButton(
                    keyName: 'quick_action_promotions',
                    icon: Icons.percent_rounded,
                    label: 'Promotions',
                    onTap: onPromotionsTap ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Special promotions and seasonal offers are coming soon!'),
                              backgroundColor: AppTheme.primaryNavy,
                            ),
                          );
                        },
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFF1F5F9),
                ),
                Expanded(
                  child: _QuickActionButton(
                    keyName: 'quick_action_community',
                    icon: Icons.people_outline_rounded,
                    label: 'Community',
                    onTap: onCommunityTap ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Traveler community stories & tips are coming soon!'),
                              backgroundColor: AppTheme.primaryNavy,
                            ),
                          );
                        },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        key: Key(widget.keyName),
        onTapDown: (_) => setState(() => _scale = 0.93),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 22,
              color: const Color(0xFF0F172A),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

