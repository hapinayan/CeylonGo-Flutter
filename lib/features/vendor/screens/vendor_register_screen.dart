import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/widgets/auth_header.dart';
import '../../auth/widgets/auth_heading.dart';
import '../../auth/widgets/auth_trust_footer.dart';
import '../../auth/widgets/auth_wave_decoration.dart';
import '../models/vendor_models.dart';
import '../services/vendor_demo_service.dart';

/// Vendor Registration Screen (Demo-Safe Local Registration)
class VendorRegisterScreen extends StatefulWidget {
  final SecureStorageService? storageService;

  const VendorRegisterScreen({super.key, this.storageService});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  VendorCategory _selectedCategory = VendorCategory.homestay;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const Color _royalBlue = Color(0xFF0A4DF5);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterVendor() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    VendorDemoService.instance.registerVendorDemo(
      businessName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      category: _selectedCategory,
      location: _locationController.text.trim(),
    );

    final storage = widget.storageService ?? SecureStorageService();
    try {
      await storage.clear();
      await storage.saveVendorDemoSession(
        VendorDemoService.instance.toDemoSessionMap(),
      );
    } on SecureStorageException catch (_) {
      // Demo registration still proceeds in-memory if secure storage is unavailable.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Demo vendor profile created locally (no backend persistence).',
        ),
        backgroundColor: AppTheme.primaryNavy,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/vendor/dashboard',
      (route) => false,
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        color: AppTheme.textMuted,
        fontSize: 13.5,
      ),
      prefixIcon: Icon(icon, color: AppTheme.primaryNavy, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      isDense: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderSlate),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderSlate),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.primaryNavy,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(showBack: true),
                      const SizedBox(height: 14),
                      const AuthHeading(
                        title: 'Vendor Registration',
                        subtitle:
                            'Register your business or hosting service on CeylonGo (Local Demo)',
                        underlineColor: _royalBlue,
                      ),
                      const SizedBox(height: 18),

                      const Text('Business / Vendor Name', style: labelStyle),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: const Key('vendor_reg_name_field'),
                        controller: _nameController,
                        validator: FormValidators.validateFullName,
                        decoration: _fieldDecoration(
                          hint: 'e.g. Ella Mountain Villa',
                          icon: Icons.storefront_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Email Address', style: labelStyle),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: const Key('vendor_reg_email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: FormValidators.validateEmail,
                        decoration: _fieldDecoration(
                          hint: 'vendor@example.com',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Phone Number', style: labelStyle),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: const Key('vendor_reg_phone_field'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: FormValidators.validatePhoneNumber,
                        decoration: _fieldDecoration(
                          hint: '077 123 4567',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Vendor Category', style: labelStyle),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<VendorCategory>(
                        key: const Key('vendor_reg_category_dropdown'),
                        initialValue: _selectedCategory,
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          hint: 'Select category',
                          icon: Icons.category_outlined,
                        ),
                        items: VendorCategory.values
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat.label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      const Text('Location', style: labelStyle),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: const Key('vendor_reg_location_field'),
                        controller: _locationController,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Location is required'
                            : null,
                        decoration: _fieldDecoration(
                          hint: 'e.g. Kandy, Ella, Galle',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Password', style: labelStyle),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: const Key('vendor_reg_password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: FormValidators.validatePassword,
                        decoration: _fieldDecoration(
                          hint: 'Create a strong password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text('Confirm Password', style: labelStyle),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: const Key('vendor_reg_confirm_field'),
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        validator: (val) =>
                            FormValidators.validateConfirmPassword(
                              val,
                              _passwordController.text,
                            ),
                        decoration: _fieldDecoration(
                          hint: 'Re-enter your password',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1D63FF), Color(0xFF0839B8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          key: const Key('vendor_register_submit_btn'),
                          onPressed: _onRegisterVendor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create Vendor Account (Demo)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('vendor_reg_identity_btn'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/vendor/register/identity',
                        ),
                        icon: const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Real Onboarding: Verify Identity (OTP + NIC)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryNavy,
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Already a registered vendor? ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            key: const Key('vendor_to_login_link'),
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              '/vendor/login',
                            ),
                            child: const Text(
                              'Vendor Sign In',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _royalBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const AuthTrustFooter(isCompact: true),
                      const AuthWaveDecoration(
                        upperWaveColor: Color(0xFF60C3FF),
                        lowerWaveColor: Color(0xFF082B5C),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
