import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../auth/models/api_error.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/widgets/auth_header.dart';
import '../../auth/widgets/auth_heading.dart';
import '../../auth/widgets/auth_trust_footer.dart';
import '../../auth/widgets/auth_wave_decoration.dart';
import '../services/provider_api_service.dart';
import '../services/vendor_demo_service.dart';

/// Vendor Login Screen
/// Supports backend ProviderApiService sign-in (`POST /api/v1/providers/login`)
/// and a clearly labeled Offline Demo Vendor flow.
class VendorLoginScreen extends StatefulWidget {
  final AuthService? authService;
  final ProviderApiService? providerService;
  final SecureStorageService? storageService;

  const VendorLoginScreen({
    super.key,
    this.authService,
    this.providerService,
    this.storageService,
  });

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final ProviderApiService _providerService;
  late final SecureStorageService _storageService;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  static const Color _royalBlue = Color(0xFF0A4DF5);
  static const String _demoVendorEmail = 'vendor@ceylongo.com';
  static const String _demoVendorPassword = 'Vendor@1234';

  @override
  void initState() {
    super.initState();
    _providerService = widget.providerService ?? ProviderApiService();
    _storageService = widget.storageService ?? SecureStorageService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onDemoVendorLogin() async {
    _emailController.text = _demoVendorEmail;
    _passwordController.text = _demoVendorPassword;
    VendorDemoService.instance.signInDemoVendor();
    try {
      await _storageService.clear();
      await _storageService.saveVendorDemoSession(
        VendorDemoService.instance.toDemoSessionMap(),
      );
    } on SecureStorageException catch (_) {
      // Demo session can proceed in-memory if secure storage is unavailable.
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/vendor/dashboard',
      (route) => false,
    );
  }

  Future<void> _onSubmit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.toLowerCase() == _demoVendorEmail &&
        password == _demoVendorPassword) {
      await _onDemoVendorLogin();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.authService != null && widget.providerService == null) {
        final response = await widget.authService!.login(
          email: email,
          password: password,
        );
        if (!mounted) return;

        final role = response.user.role.trim().toLowerCase();
        if (role != 'vendor' && role != 'provider') {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'This account does not have Vendor access. Please sign in with a Vendor account.';
          });
          return;
        }

        await _storageService.clearVendorDemoSession();
        await _storageService.saveToken(response.accessToken);
        await _storageService.saveUser(response.user);

        if (!mounted) return;
        setState(() => _isLoading = false);

        VendorDemoService.instance.setAuthenticatedVendor(
          id: response.user.id,
          businessName: response.user.fullName,
          email: response.user.email,
        );
      } else {
        final result = await _providerService.login(
          email: email,
          password: password,
        );
        if (!mounted) return;

        final role = result.user.role.trim().toLowerCase();
        if ((role != 'provider' && role != 'vendor') ||
            result.user.approvalStatus.toLowerCase() != 'approved' ||
            !result.user.isActive) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Access restricted to approved, active provider accounts.';
          });
          return;
        }

        await _storageService.clearVendorDemoSession();
        await _storageService.saveToken(result.accessToken);
        await _storageService.saveUser(result.user.toUserModel());

        if (!mounted) return;
        setState(() => _isLoading = false);

        VendorDemoService.instance.setAuthenticatedVendor(
          id: result.user.id.toString(),
          businessName: result.user.businessName.isNotEmpty
              ? result.user.businessName
              : result.user.fullName,
          email: result.user.email,
        );
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/vendor/dashboard',
        (route) => false,
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to sign in right now. Use Offline Demo Vendor or check your server connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13.5,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                      const AuthHeader(showBack: true),
                      const SizedBox(height: 16),
                      const AuthHeading(
                        title: 'Vendor Portal',
                        subtitle:
                            'Sign in to manage your Sri Lankan listings and bookings',
                        underlineColor: _royalBlue,
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.errorRed.withAlpha(75),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      const Text('Email Address', style: labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('vendor_login_email_field'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        validator: FormValidators.validateEmail,
                        decoration: InputDecoration(
                          hintText: 'vendor@ceylongo.com',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppTheme.primaryNavy,
                            size: 20,
                          ),
                          filled: true,
                          isDense: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSlate,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text('Password', style: labelStyle),
                          ),
                          Flexible(
                            child: GestureDetector(
                              key: const Key('vendor_forgot_password_link'),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/forgot-password',
                                arguments: {
                                  'email': _emailController.text.trim(),
                                },
                              ),
                              child: const Text(
                                'Forgot password?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _royalBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('vendor_login_password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        validator: FormValidators.validateLoginPassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppTheme.primaryNavy,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            key: const Key('vendor_toggle_password_btn'),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          filled: true,
                          isDense: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSlate,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1D63FF), Color(0xFF0839B8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          key: const Key('vendor_login_submit_btn'),
                          onPressed: _isLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'New vendor partner? ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            key: const Key('vendor_to_register_link'),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/vendor/register',
                            ),
                            child: const Text(
                              'Register as Vendor',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: _royalBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton.icon(
                          key: const Key('vendor_change_role_btn'),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/role-selection',
                                    (route) => false,
                                  );
                                },
                          icon: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: AppTheme.primaryNavy,
                          ),
                          label: const Text(
                            'Change Role',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Offline Demo Vendor Panel
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryNavy.withAlpha(45),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Offline Demo Vendor Flow',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Explore Vendor Dashboard without a backend:\nvendor@ceylongo.com • Vendor@1234',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                key: const Key('vendor_demo_login_btn'),
                                onPressed: _onDemoVendorLogin,
                                icon: const Icon(
                                  Icons.play_circle_filled,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Sign In as Demo Vendor',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryNavy,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              AuthTrustFooter(isCompact: true),
              AuthWaveDecoration(
                upperWaveColor: Color(0xFF60C3FF),
                lowerWaveColor: Color(0xFF082B5C),
              ),
            ],
          ),
        ],
      ),
    ),
  );
},
          ),
        ),
      ),
    );
  }
}
