import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../../auth/models/user_model.dart';
import '../services/account_service.dart';

/// Edit Profile & Change Password Screen
class EditProfileScreen extends StatefulWidget {
  final UserModel initialUser;
  final AccountService? accountService;

  const EditProfileScreen({
    super.key,
    required this.initialUser,
    this.accountService,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AccountService _service;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _countryController;

  final _currentPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _service = widget.accountService ?? AccountService();
    _nameController = TextEditingController(text: widget.initialUser.fullName);
    _phoneController = TextEditingController(text: widget.initialUser.phone ?? '');
    _countryController =
        TextEditingController(text: widget.initialUser.country ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _currentPwdController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required.')),
      );
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final updated = await _service.updateProfile(
        fullName: fullName,
        phone: _phoneController.text,
        country: _countryController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.pop(context, updated);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile.')),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final cur = _currentPwdController.text;
    final next = _newPwdController.text;
    final conf = _confirmPwdController.text;
    if (cur.isEmpty || next.isEmpty || conf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all password fields.')),
      );
      return;
    }
    if (next != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    setState(() => _savingPassword = true);
    try {
      final msg = await _service.changePassword(
        currentPassword: cur,
        newPassword: next,
        confirmPassword: conf,
      );
      if (!mounted) return;
      _currentPwdController.clear();
      _newPwdController.clear();
      _confirmPwdController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password.')),
      );
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Personal Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.borderSlate),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: widget.initialUser.email,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _savingProfile ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: _savingProfile
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.borderSlate),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentPwdController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPwdController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPwdController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _savingPassword ? null : _changePassword,
                      child: Text(
                        _savingPassword ? 'Updating...' : 'Update Password',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Travel Preferences Screen (GET/PUT /api/v1/traveler/preferences)
class TravelPreferencesScreen extends StatefulWidget {
  final AccountService? accountService;

  const TravelPreferencesScreen({super.key, this.accountService});

  @override
  State<TravelPreferencesScreen> createState() =>
      _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  late final AccountService _service;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _destinationsCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  final _accommodationCtrl = TextEditingController();
  final _transportCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();
  String? _travelStyle;

  static const _styles = ['budget', 'balanced', 'comfort', 'adventure', 'luxury'];

  @override
  void initState() {
    super.initState();
    _service = widget.accountService ?? AccountService();
    _load();
  }

  @override
  void dispose() {
    _destinationsCtrl.dispose();
    _interestsCtrl.dispose();
    _accommodationCtrl.dispose();
    _transportCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await _service.getPreferences();
      if (!mounted) return;
      _destinationsCtrl.text = prefs.preferredDestinations.join(', ');
      _interestsCtrl.text = prefs.interests.join(', ');
      _accommodationCtrl.text = prefs.accommodationPreferences.join(', ');
      _transportCtrl.text = prefs.transportPreferences.join(', ');
      _budgetMinCtrl.text = prefs.budgetMin?.toString() ?? '';
      _budgetMaxCtrl.text = prefs.budgetMax?.toString() ?? '';
      _travelStyle = _styles.contains(prefs.travelStyle)
          ? prefs.travelStyle
          : null;
      setState(() => _loading = false);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load preferences.';
      });
    }
  }

  List<String> _splitCsv(String input) => input
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final model = TravelerPreferencesModel(
        preferredDestinations: _splitCsv(_destinationsCtrl.text),
        interests: _splitCsv(_interestsCtrl.text),
        accommodationPreferences: _splitCsv(_accommodationCtrl.text),
        transportPreferences: _splitCsv(_transportCtrl.text),
        budgetMin: int.tryParse(_budgetMinCtrl.text.trim()),
        budgetMax: int.tryParse(_budgetMaxCtrl.text.trim()),
        travelStyle: _travelStyle,
      );
      await _service.updatePreferences(model);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Travel preferences saved.')),
      );
      Navigator.pop(context);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save preferences.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Travel Preferences'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _destinationsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Destinations (comma-separated)',
                          hintText: 'Kandy, Ella, Galle',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _interestsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Interests (comma-separated)',
                          hintText: 'Heritage, Hiking, Tea Trails',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accommodationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Accommodation Preferences',
                          hintText: 'Boutique Homestay, Eco Lodge',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _transportCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Transport Preferences',
                          hintText: 'Scooter, Train, Bicycle',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _budgetMinCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min Budget (LKR)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _budgetMaxCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Budget (LKR)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _travelStyle,
                        decoration: const InputDecoration(
                          labelText: 'Travel Style',
                        ),
                        items: _styles
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s[0].toUpperCase() + s.substring(1)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _travelStyle = v),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_saving ? 'Saving...' : 'Save Preferences'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// Notification Settings Screen (GET/PATCH /api/v1/traveler/settings/notifications)
class NotificationSettingsScreen extends StatefulWidget {
  final AccountService? accountService;

  const NotificationSettingsScreen({super.key, this.accountService});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final AccountService _service;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  NotificationSettingsModel _settings = const NotificationSettingsModel();

  @override
  void initState() {
    super.initState();
    _service = widget.accountService ?? AccountService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getNotificationSettings();
      if (!mounted) return;
      setState(() {
        _settings = res;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load notification settings.';
      });
    }
  }

  Future<void> _update(NotificationSettingsModel next) async {
    final previous = _settings;
    setState(() {
      _settings = next;
      _saving = true;
    });
    try {
      final saved = await _service.updateNotificationSettings(next);
      if (!mounted) return;
      setState(() {
        _settings = saved;
        _saving = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _settings = previous;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryNavy,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_saving) const LinearProgressIndicator(minHeight: 2),
                    SwitchListTile(
                      value: _settings.bookingUpdates,
                      title: const Text('Booking Updates'),
                      subtitle: const Text(
                        'Confirmations, rejections, and schedule reminders.',
                      ),
                      onChanged: (v) =>
                          _update(_settings.copyWith(bookingUpdates: v)),
                    ),
                    SwitchListTile(
                      value: _settings.paymentUpdates,
                      title: const Text('Payment Updates'),
                      subtitle: const Text(
                        'Simulated online receipts and pay-at-location status.',
                      ),
                      onChanged: (v) =>
                          _update(_settings.copyWith(paymentUpdates: v)),
                    ),
                    SwitchListTile(
                      value: _settings.communityActivity,
                      title: const Text('Community Activity'),
                      subtitle: const Text(
                        'Comments and interactions on your community posts.',
                      ),
                      onChanged: (v) =>
                          _update(_settings.copyWith(communityActivity: v)),
                    ),
                    SwitchListTile(
                      value: _settings.promotionalUpdates,
                      title: const Text('Promotional Updates'),
                      subtitle: const Text(
                        'Seasonal travel suggestions and highlights.',
                      ),
                      onChanged: (v) =>
                          _update(_settings.copyWith(promotionalUpdates: v)),
                    ),
                  ],
                ),
    );
  }
}
