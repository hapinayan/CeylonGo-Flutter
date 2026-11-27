import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../services/vendor_demo_service.dart';

/// Dedicated Vendor Profile Screen
class VendorProfileScreen extends StatelessWidget {
  final SecureStorageService? storageService;

  const VendorProfileScreen({super.key, this.storageService});

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
          'Vendor Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryNavy,
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vendor.businessName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${vendor.category.label} • ${vendor.location}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A4DF5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${vendor.email} • ${vendor.phone}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(
                Icons.list_alt_rounded,
                color: AppTheme.primaryNavy,
              ),
              title: const Text('My Listings'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, '/vendor/listings'),
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: AppTheme.primaryNavy,
              ),
              title: const Text('Manage Bookings'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, '/vendor/bookings'),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('vendor_logout_btn'),
                onPressed: () async {
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
                    '/vendor/login',
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                label: const Text(
                  'Log Out Vendor Session',
                  style: TextStyle(color: AppTheme.errorRed),
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

