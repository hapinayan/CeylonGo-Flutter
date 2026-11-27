import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../services/vendor_demo_service.dart';
import '../widgets/vendor_bottom_nav_bar.dart';

/// Vendor More Screen hosting Vendor Profile, all 7 working Vendor sub-screens,
/// and Logout.
class VendorMoreScreen extends StatelessWidget {
  final SecureStorageService? storageService;

  const VendorMoreScreen({super.key, this.storageService});

  static const List<({Key key, String title, IconData icon, String route})>
      _featureItems = [
    (
      key: Key('vendor_more_availability_tile'),
      title: 'Availability Calendar',
      icon: Icons.event_available_outlined,
      route: '/vendor/availability',
    ),
    (
      key: Key('vendor_more_earnings_tile'),
      title: 'Earnings & Payments',
      icon: Icons.account_balance_wallet_outlined,
      route: '/vendor/earnings',
    ),
    (
      key: Key('vendor_more_reviews_tile'),
      title: 'Reviews & Ratings',
      icon: Icons.star_outline_rounded,
      route: '/vendor/reviews',
    ),
    (
      key: Key('vendor_more_notifications_tile'),
      title: 'Notifications',
      icon: Icons.notifications_none_rounded,
      route: '/vendor/notifications',
    ),
    (
      key: Key('vendor_more_settings_tile'),
      title: 'App Settings',
      icon: Icons.settings_outlined,
      route: '/vendor/settings',
    ),
    (
      key: Key('vendor_more_support_tile'),
      title: 'Help & Support',
      icon: Icons.help_outline_rounded,
      route: '/vendor/support',
    ),
    (
      key: Key('vendor_more_about_tile'),
      title: 'About CeylonGo',
      icon: Icons.info_outline_rounded,
      route: '/vendor/about',
    ),
    (
      key: Key('vendor_more_weather_tile'),
      title: 'Live Weather',
      icon: Icons.wb_sunny_outlined,
      route: '/weather',
    ),
    (
      key: Key('vendor_more_map_tile'),
      title: 'Interactive Map',
      icon: Icons.map_outlined,
      route: '/map',
    ),
  ];

  Future<void> _onLogout(BuildContext context) async {
    final storage = storageService ?? SecureStorageService();
    try {
      await storage.clear();
    } on SecureStorageException catch (_) {
      // Proceed with local sign-out if secure storage is unavailable.
    }
    VendorDemoService.instance.signOutVendor();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/role-selection',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendor = VendorDemoService.instance.currentVendor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'More',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      bottomNavigationBar: const VendorBottomNavigationBar(currentIndex: 3),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryNavy,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.businessName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        Text(
                          vendor.isDemoSession
                              ? '${vendor.category.label} • Demo Mode'
                              : vendor.category.label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _MoreMenuTile(
              key: const Key('vendor_more_profile_tile'),
              icon: Icons.person_outline_rounded,
              title: 'Vendor Profile',
              onTap: () => Navigator.pushNamed(context, '/vendor/profile'),
            ),
            const SizedBox(height: 8),
            ..._featureItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MoreMenuTile(
                  key: item.key,
                  icon: item.icon,
                  title: item.title,
                  onTap: () => Navigator.pushNamed(context, item.route),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('vendor_more_logout_btn'),
                onPressed: () => _onLogout(context),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorRed,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _MoreMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MoreMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryNavy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

