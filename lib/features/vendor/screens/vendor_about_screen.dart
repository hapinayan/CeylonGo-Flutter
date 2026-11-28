import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// About CeylonGo Screen
/// Displays official branding, pubspec version/build, Vendor Portal overview,
/// and honest status for unlinked Privacy Policy & Terms documents.
class VendorAboutScreen extends StatelessWidget {
  const VendorAboutScreen({super.key});

  /// Matches `version: 1.0.0+1` in pubspec.yaml.
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  void _showUnlinkedPolicyNotice(BuildContext context, String docName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$docName document is not linked in this demo build.',
        ),
        backgroundColor: AppTheme.primaryNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: const Text(
          'About CeylonGo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/ceylongo_logo.png',
                    height: 64,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.travel_explore_rounded,
                      size: 56,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CeylonGo Vendor Portal',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Version $appVersion (Build $appBuild)',
                    key: Key('about_app_version'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A4DF5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CeylonGo connects Sri Lankan homestays, eco-tourism hosts, activity providers, local guides, rentals, and artisans with travelers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFDBEAFE)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    key: const Key('about_privacy_policy_tile'),
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppTheme.primaryNavy,
                    ),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Not yet linked in this demo build'),
                    trailing: const Icon(Icons.info_outline_rounded),
                    onTap: () =>
                        _showUnlinkedPolicyNotice(context, 'Privacy Policy'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('about_terms_tile'),
                    leading: const Icon(
                      Icons.description_outlined,
                      color: AppTheme.primaryNavy,
                    ),
                    title: const Text('Terms & Conditions'),
                    subtitle: const Text('Not yet linked in this demo build'),
                    trailing: const Icon(Icons.info_outline_rounded),
                    onTap: () => _showUnlinkedPolicyNotice(
                      context,
                      'Terms & Conditions',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

