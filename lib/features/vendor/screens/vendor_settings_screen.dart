import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../services/vendor_demo_service.dart';

/// Vendor App Settings Screen
/// Clearly distinguishes supported local demo preferences from unsupported
/// localization, push, and dark-theme options.
class VendorSettingsScreen extends StatefulWidget {
  final SecureStorageService? storageService;

  const VendorSettingsScreen({super.key, this.storageService});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  bool _demoBookingAlerts = true;
  bool _demoAvailabilityReminders = true;

  Future<void> _onLogout() async {
    final storage = widget.storageService ?? SecureStorageService();
    try {
      await storage.clear();
    } on SecureStorageException catch (_) {
      // Proceed with local sign-out if secure storage is unavailable.
    }
    VendorDemoService.instance.signOutVendor();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/vendor/login',
      (route) => false,
    );
  }

  void _showUnsupportedInfo(String label) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label is not supported in this demo build yet.'),
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
          'App Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _SectionTitle('Language'),
            const SizedBox(height: 6),
            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.language_rounded,
                    color: Color(0xFF0A4DF5),
                  ),
                  title: const Text('English'),
                  subtitle: const Text('Currently active application language'),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('settings_sinhala_coming_soon'),
                  leading: const Icon(
                    Icons.translate_rounded,
                    color: Color(0xFF64748B),
                  ),
                  title: const Text('සිංහල (Sinhala)'),
                  subtitle: const Text('Coming Soon — localization not yet bundled'),
                  onTap: () => _showUnsupportedInfo('Sinhala localization'),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('settings_tamil_coming_soon'),
                  leading: const Icon(
                    Icons.translate_rounded,
                    color: Color(0xFF64748B),
                  ),
                  title: const Text('தமிழ் (Tamil)'),
                  subtitle: const Text('Coming Soon — localization not yet bundled'),
                  onTap: () => _showUnsupportedInfo('Tamil localization'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Notification Preferences (Demo Only)'),
            const SizedBox(height: 6),
            _SettingsCard(
              children: [
                SwitchListTile(
                  key: const Key('settings_booking_alerts_switch'),
                  title: const Text('Booking Request Alerts'),
                  subtitle: const Text(
                    'Local demo toggle only (push notifications not configured)',
                  ),
                  value: _demoBookingAlerts,
                  onChanged: (val) => setState(() => _demoBookingAlerts = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const Key('settings_availability_switch'),
                  title: const Text('Availability Reminders'),
                  subtitle: const Text(
                    'Local demo toggle only (no background push)',
                  ),
                  value: _demoAvailabilityReminders,
                  onChanged: (val) =>
                      setState(() => _demoAvailabilityReminders = val),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Theme'),
            const SizedBox(height: 6),
            _SettingsCard(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.light_mode_outlined,
                    color: Color(0xFF0A4DF5),
                  ),
                  title: Text('Light Theme'),
                  subtitle: Text('Active CeylonGo Vendor blue-and-white theme'),
                  trailing: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('settings_dark_theme_unsupported'),
                  leading: const Icon(
                    Icons.dark_mode_outlined,
                    color: Color(0xFF64748B),
                  ),
                  title: const Text('Dark Theme'),
                  subtitle: const Text('Coming Soon — not yet supported'),
                  onTap: () => _showUnsupportedInfo('Dark theme'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Account'),
            const SizedBox(height: 6),
            _SettingsCard(
              children: [
                ListTile(
                  key: const Key('settings_vendor_profile_tile'),
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryNavy,
                  ),
                  title: const Text('Vendor Profile'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(context, '/vendor/profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('settings_logout_btn'),
                onPressed: _onLogout,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryNavy,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDBEAFE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

