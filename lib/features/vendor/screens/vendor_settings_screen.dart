import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/provider_profile_model.dart';
import '../services/provider_api_service.dart';
import '../services/vendor_demo_service.dart';

/// Vendor App Settings Screen
/// Combines account info, Edit Business Profile shortcut, real Change Password
/// integration (`POST /api/v1/providers/me/change-password`), Demo Mode guard,
/// and existing language/theme/notification preferences.
class VendorSettingsScreen extends StatefulWidget {
  final ProviderApiService? providerService;
  final SecureStorageService? storageService;

  const VendorSettingsScreen({
    super.key,
    this.providerService,
    this.storageService,
  });

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  late final ProviderApiService _providerService;
  late final SecureStorageService _storageService;

  bool _demoBookingAlerts = true;
  bool _demoAvailabilityReminders = true;

  bool _isCheckingSession = true;
  bool _isDemoMode = true;
  String? _accessToken;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _providerService = widget.providerService ?? ProviderApiService();
    _storageService = widget.storageService ?? SecureStorageService();
    _resolveSession();
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolveSession() async {
    final vendor = VendorDemoService.instance.currentVendor;
    if (vendor.isDemoSession) {
      if (!mounted) return;
      setState(() {
        _isCheckingSession = false;
        _isDemoMode = true;
        _accessToken = null;
      });
      return;
    }

    String? token;
    try {
      token = await _storageService.getToken();
    } on SecureStorageException catch (_) {
      token = null;
    }

    final isDemo =
        token == null || token.trim().isEmpty || token.startsWith('demo-');

    if (!mounted) return;
    setState(() {
      _isCheckingSession = false;
      _isDemoMode = isDemo;
      _accessToken = isDemo ? null : token;
    });
  }

  Future<void> _onChangePassword() async {
    if (_isDemoMode || _isChangingPassword || _accessToken == null) return;
    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
    });
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isChangingPassword = true);

    try {
      final message = await _providerService.changePassword(
        accessToken: _accessToken!,
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
        confirmNewPassword: _confirmPasswordCtrl.text,
      );
      if (!mounted) return;
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      setState(() {
        _isChangingPassword = false;
        _passwordSuccess = message;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _onLogout();
        return;
      }
      setState(() {
        _isChangingPassword = false;
        _passwordError = e.message;
      });
    }
  }

  Future<void> _onLogout() async {
    try {
      await _storageService.clear();
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
    final vendor = VendorDemoService.instance.currentVendor;

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
            const _SectionTitle('Account Information'),
            const SizedBox(height: 6),
            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF0A4DF5),
                  ),
                  title: Text(vendor.businessName),
                  subtitle: Text(
                    _isDemoMode
                        ? '${vendor.email} • Demo Mode'
                        : vendor.email,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('settings_vendor_profile_tile'),
                  leading: const Icon(
                    Icons.edit_note_rounded,
                    color: AppTheme.primaryNavy,
                  ),
                  title: const Text('Edit Business Profile'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(context, '/vendor/profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Security & Password'),
            const SizedBox(height: 6),
            _buildPasswordSection(),
            const SizedBox(height: 16),
            const _SectionTitle('Language'),
            const SizedBox(height: 6),
            _SettingsCard(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.language_rounded,
                    color: Color(0xFF0A4DF5),
                  ),
                  title: Text('English'),
                  subtitle: Text('Currently active application language'),
                  trailing: Icon(
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
                  subtitle: const Text(
                    'Coming Soon — localization not yet bundled',
                  ),
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
                  subtitle: const Text(
                    'Coming Soon — localization not yet bundled',
                  ),
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

  Widget _buildPasswordSection() {
    if (_isCheckingSession) {
      return const _SettingsCard(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_isDemoMode) {
      return _SettingsCard(
        children: const [
          Padding(
            key: Key('settings_password_demo_disabled'),
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Demo Mode: Password changes are disabled. Sign in with an approved provider account to update your password.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_passwordError != null) ...[
                  Container(
                    key: const Key('settings_password_error'),
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _passwordError!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
                if (_passwordSuccess != null) ...[
                  Container(
                    key: const Key('settings_password_success'),
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _passwordSuccess!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                TextFormField(
                  key: const Key('settings_current_password_field'),
                  controller: _currentPasswordCtrl,
                  obscureText: _obscureCurrent,
                  enabled: !_isChangingPassword,
                  validator: ProviderValidators.validateCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('settings_new_password_field'),
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  enabled: !_isChangingPassword,
                  validator: (v) => ProviderValidators.validateNewPassword(
                    v,
                    currentPassword: _currentPasswordCtrl.text,
                  ),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('settings_confirm_password_field'),
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  enabled: !_isChangingPassword,
                  validator: (v) =>
                      ProviderValidators.validateConfirmNewPassword(
                    v,
                    newPassword: _newPasswordCtrl.text,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    key: const Key('settings_change_password_btn'),
                    onPressed: _isChangingPassword ? null : _onChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A4DF5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isChangingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Change Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
