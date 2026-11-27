import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../models/provider_profile_model.dart';
import '../services/provider_api_service.dart';
import '../services/vendor_demo_service.dart';

/// Provider Profile Screen
/// Supports:
/// 1. Real authenticated provider profile loading (`GET /api/v1/providers/me`)
///    and partial editing (`PATCH /api/v1/providers/me`).
/// 2. Clearly labeled Demo Mode view without fake API calls.
class VendorProfileScreen extends StatefulWidget {
  final ProviderApiService? providerService;
  final SecureStorageService? storageService;

  const VendorProfileScreen({
    super.key,
    this.providerService,
    this.storageService,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final ProviderApiService _providerService;
  late final SecureStorageService _storageService;

  final _businessNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _secondaryPhoneCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _businessDistrictCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  bool _isDemoMode = false;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _accessToken;
  ProviderProfile? _profile;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _providerService = widget.providerService ?? ProviderApiService();
    _storageService = widget.storageService ?? SecureStorageService();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _phoneCtrl.dispose();
    _secondaryPhoneCtrl.dispose();
    _districtCtrl.dispose();
    _descriptionCtrl.dispose();
    _provinceCtrl.dispose();
    _businessDistrictCtrl.dispose();
    _cityCtrl.dispose();
    _landmarkCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final demoVendor = VendorDemoService.instance.currentVendor;
    if (demoVendor.isDemoSession) {
      if (!mounted) return;
      setState(() {
        _isDemoMode = true;
        _isLoading = false;
        _profile = null;
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

    if (token == null || token.trim().isEmpty || token.startsWith('demo-')) {
      if (!mounted) return;
      setState(() {
        _isDemoMode = true;
        _isLoading = false;
        _profile = null;
        _accessToken = null;
      });
      return;
    }

    _accessToken = token;
    _isDemoMode = false;

    try {
      final profile = await _providerService.getProfile(token);
      if (!mounted) return;
      _populateControllers(profile);
      VendorDemoService.instance.setAuthenticatedVendor(
        id: profile.userId.toString(),
        businessName: profile.businessName.isNotEmpty
            ? profile.businessName
            : profile.fullName,
        email: profile.email,
      );
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  void _populateControllers(ProviderProfile p) {
    _businessNameCtrl.text = p.businessName;
    _phoneCtrl.text = p.phone;
    _secondaryPhoneCtrl.text = p.secondaryPhone ?? '';
    _districtCtrl.text = p.district;
    _descriptionCtrl.text = p.description ?? '';
    _provinceCtrl.text = p.businessProvince ?? '';
    _businessDistrictCtrl.text = p.businessDistrict ?? '';
    _cityCtrl.text = p.businessCity ?? '';
    _landmarkCtrl.text = p.businessLandmark ?? '';
    _postalCodeCtrl.text = p.businessPostalCode ?? '';
  }

  Future<void> _handleUnauthorized() async {
    try {
      await _storageService.clear();
    } on SecureStorageException catch (_) {}
    VendorDemoService.instance.signOutVendor();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/vendor/login',
      (route) => false,
    );
  }

  Future<void> _onSave() async {
    if (_isSaving || _profile == null || _accessToken == null) return;
    setState(() {
      _errorMessage = null;
      _statusMessage = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final patch = ProviderProfilePatch(
      businessName: _businessNameCtrl.text,
      phone: _phoneCtrl.text,
      secondaryPhone: _secondaryPhoneCtrl.text,
      district: _districtCtrl.text,
      description: _descriptionCtrl.text,
      businessProvince: _provinceCtrl.text,
      businessDistrict: _businessDistrictCtrl.text,
      businessCity: _cityCtrl.text,
      businessLandmark: _landmarkCtrl.text,
      businessPostalCode: _postalCodeCtrl.text,
    ).diffAgainst(_profile!);

    if (patch.isEmpty) {
      setState(() {
        _isEditing = false;
        _statusMessage = 'No changes to save.';
      });
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updated = await _providerService.updateProfile(
        accessToken: _accessToken!,
        patchData: patch,
      );
      if (!mounted) return;
      _populateControllers(updated);
      VendorDemoService.instance.setAuthenticatedVendor(
        id: updated.userId.toString(),
        businessName: updated.businessName.isNotEmpty
            ? updated.businessName
            : updated.fullName,
        email: updated.email,
      );
      await _storageService.saveUser(updated.toUserModel());
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isSaving = false;
        _isEditing = false;
        _statusMessage = 'Business profile updated successfully.';
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _onLogout() async {
    try {
      await _storageService.clear();
    } on SecureStorageException catch (_) {}
    VendorDemoService.instance.signOutVendor();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/vendor/login',
      (route) => false,
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
          'Vendor Profile',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryNavy,
          ),
        ),
        actions: [
          if (!_isDemoMode && _profile != null && !_isEditing)
            TextButton.icon(
              key: const Key('profile_edit_btn'),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _errorMessage = null;
                  _statusMessage = null;
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                key: Key('profile_loading_indicator'),
                child: CircularProgressIndicator(color: AppTheme.primaryNavy),
              )
            : _isDemoMode
                ? _buildDemoModeView(context)
                : _profile == null
                    ? _buildErrorRetryView()
                    : _buildRealProfileView(),
      ),
    );
  }

  Widget _buildDemoModeView(BuildContext context) {
    final vendor = VendorDemoService.instance.currentVendor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          key: const Key('profile_demo_banner'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Text(
            'Demo Mode: Local demo vendor profile. Real backend profile editing is disabled in Demo Mode.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryNavy,
            ),
          ),
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 16),
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
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('vendor_logout_btn'),
            onPressed: _onLogout,
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
    );
  }

  Widget _buildErrorRetryView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load provider profile.',
              key: const Key('profile_error_text'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('profile_retry_btn'),
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A4DF5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealProfileView() {
    final p = _profile!;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                key: const Key('profile_api_error_banner'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.errorRed.withAlpha(80)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_statusMessage != null) ...[
              Container(
                key: const Key('profile_success_banner'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account & Verification (Read-Only)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ReadOnlyRow(label: 'Full Name', value: p.fullName),
                  _ReadOnlyRow(label: 'Email', value: p.email),
                  _ReadOnlyRow(label: 'Provider Type', value: p.providerType),
                  _ReadOnlyRow(
                    label: 'Approval Status',
                    value: p.approvalStatus.toUpperCase(),
                  ),
                  if (p.businessRegistrationNumber != null)
                    _ReadOnlyRow(
                      label: 'Business Reg. No.',
                      value: p.businessRegistrationNumber!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Business Profile Details',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 10),
            _buildField(
              fieldKey: const Key('profile_business_name_field'),
              controller: _businessNameCtrl,
              label: 'Business Name',
              enabled: _isEditing && !_isSaving,
              validator: ProviderValidators.validateBusinessName,
            ),
            _buildField(
              fieldKey: const Key('profile_phone_field'),
              controller: _phoneCtrl,
              label: 'Primary Phone',
              keyboardType: TextInputType.phone,
              enabled: _isEditing && !_isSaving,
              validator: (v) =>
                  ProviderValidators.validatePhone(v, requiredField: true),
            ),
            _buildField(
              fieldKey: const Key('profile_secondary_phone_field'),
              controller: _secondaryPhoneCtrl,
              label: 'Secondary Phone (optional)',
              keyboardType: TextInputType.phone,
              enabled: _isEditing && !_isSaving,
              validator: (v) =>
                  ProviderValidators.validatePhone(v, requiredField: false),
            ),
            _buildField(
              fieldKey: const Key('profile_district_field'),
              controller: _districtCtrl,
              label: 'District',
              enabled: _isEditing && !_isSaving,
              validator: ProviderValidators.validateDistrict,
            ),
            _buildField(
              fieldKey: const Key('profile_description_field'),
              controller: _descriptionCtrl,
              label: 'Business Description (optional)',
              maxLines: 3,
              enabled: _isEditing && !_isSaving,
              validator: (v) => ProviderValidators.validateMaxLength(
                v,
                fieldLabel: 'Description',
                maxLength: 1000,
              ),
            ),
            _buildField(
              fieldKey: const Key('profile_province_field'),
              controller: _provinceCtrl,
              label: 'Province (optional)',
              enabled: _isEditing && !_isSaving,
              validator: (v) => ProviderValidators.validateMaxLength(
                v,
                fieldLabel: 'Province',
                maxLength: 100,
              ),
            ),
            _buildField(
              fieldKey: const Key('profile_business_district_field'),
              controller: _businessDistrictCtrl,
              label: 'Business District (optional)',
              enabled: _isEditing && !_isSaving,
              validator: (v) => ProviderValidators.validateMaxLength(
                v,
                fieldLabel: 'Business District',
                maxLength: 100,
              ),
            ),
            _buildField(
              fieldKey: const Key('profile_city_field'),
              controller: _cityCtrl,
              label: 'City (optional)',
              enabled: _isEditing && !_isSaving,
              validator: (v) => ProviderValidators.validateMaxLength(
                v,
                fieldLabel: 'City',
                maxLength: 100,
              ),
            ),
            _buildField(
              fieldKey: const Key('profile_landmark_field'),
              controller: _landmarkCtrl,
              label: 'Landmark (optional)',
              enabled: _isEditing && !_isSaving,
              validator: (v) => ProviderValidators.validateMaxLength(
                v,
                fieldLabel: 'Landmark',
                maxLength: 255,
              ),
            ),
            _buildField(
              fieldKey: const Key('profile_postal_code_field'),
              controller: _postalCodeCtrl,
              label: 'Postal Code (optional)',
              enabled: _isEditing && !_isSaving,
              validator: (v) => ProviderValidators.validateMaxLength(
                v,
                fieldLabel: 'Postal Code',
                maxLength: 20,
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('profile_cancel_btn'),
                      onPressed: _isSaving
                          ? null
                          : () {
                              _populateControllers(p);
                              setState(() {
                                _isEditing = false;
                                _errorMessage = null;
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('profile_save_btn'),
                      onPressed: _isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A4DF5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('vendor_logout_btn'),
                onPressed: _onLogout,
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

  Widget _buildField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          isDense: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderSlate),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
