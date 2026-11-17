import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';
import '../widgets/auth_wave_decoration.dart';

/// CeylonGo Full-Screen Clean White Tourist Registration Screen
/// Balanced, evenly distributed full-screen layout optimized for Samsung Galaxy A22.
/// Strictly preserves backend authentication contract (FastAPI / SQL Server).
class RegisterScreen extends StatefulWidget {
  final AuthService? authService;
  final String? initialEmail;

  const RegisterScreen({super.key, this.authService, this.initialEmail});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  late final AuthService _authService;

  String _selectedCountryCode = 'LK +94';
  static const List<String> _countryCodes = [
    'LK +94',
    'US +1',
    'GB +44',
    'AU +61',
    'IN +91',
    'DE +49',
    'FR +33',
    'SG +65',
    'AE +971',
    'CA +1',
    'JP +81',
    'CN +86',
    'NZ +64',
    'IT +39',
    'CH +41',
  ];

  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _termsError = false;

  bool _isLoading = false;
  String? _errorMessage;
  String? _fullNameServerError;
  String? _emailServerError;
  String? _passwordServerError;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() {
      _errorMessage = null;
      _fullNameServerError = null;
      _emailServerError = null;
      _passwordServerError = null;
      _termsError = !_acceptTerms;
    });

    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid || !_acceptTerms) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Backend Contract: registration payload strictly contains full_name, email, password
      final response = await _authService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text, // Passwords must NEVER be trimmed
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Display server success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppTheme.primaryNavy,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to Registration Successful screen
        Navigator.pushReplacementNamed(
          context,
          '/registration-success',
          arguments: {'user': response.user, 'message': response.message},
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          if (e.code == 'EMAIL_ALREADY_EXISTS') {
            _emailServerError = e.message;
          }
          if (e.fields.containsKey('email')) {
            _emailServerError = e.fields['email'];
          }
          if (e.fields.containsKey('full_name')) {
            _fullNameServerError = e.fields['full_name'];
          }
          if (e.fields.containsKey('password')) {
            _passwordServerError = e.fields['password'];
          }
        });
        _formKey.currentState?.validate();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
    BoxConstraints? prefixIconConstraints,
    bool isCompact = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        color: const Color(0xFF94A3B8),
        fontSize: isCompact ? 12.5 : 13.5,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints:
          prefixIconConstraints ??
          BoxConstraints(
            minWidth: isCompact ? 38 : 42,
            minHeight: isCompact ? 34 : 38,
          ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIcon != null
          ? BoxConstraints(
              minWidth: isCompact ? 38 : 42,
              minHeight: isCompact ? 34 : 38,
            )
          : null,
      filled: true,
      isDense: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: isCompact ? 10 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5),
      ),
      errorStyle: TextStyle(
        fontFamily: 'Inter',
        color: AppTheme.errorRed,
        fontSize: isCompact ? 11.0 : 11.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final availableHeight = constraints.maxHeight;
            final isShort = availableHeight < 680;

            final horizontalPadding = screenWidth < 360
                ? 18.0
                : (screenWidth < 430 ? 22.0 : 26.0);
            final topPadding = isShort ? 6.0 : 8.0;
            final bottomPadding = isShort ? 12.0 : 14.0;

            final labelStyle = const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            );

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
                          horizontalPadding,
                          bottomPadding,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Circular Outlined Back Button near the Top-Left
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    key: const Key('register_back_button'),
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back,
                                        color: Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Spacer(flex: 2),

                              // 2. Extra-bold Dark Navy Heading: "Create Your Account"
                              Text(
                                'Create Your Account',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: isShort ? 22.0 : 25.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryNavy,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Subtitle: "Join CeylonGo and start exploring Sri Lanka."
                              Text(
                                'Join CeylonGo and start exploring Sri Lanka.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: isShort ? 12.5 : 13.5,
                                  color: const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Spacer(flex: 3),

                              // Server Error Banner
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.errorRed.withAlpha(75),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppTheme.errorRed,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color: AppTheme.errorRed,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // 3. Full Name Field
                              Text('Full Name', style: labelStyle),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: const Key('register_full_name_field'),
                                controller: _fullNameController,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: AppTheme.textPrimary,
                                ),
                                onChanged: (_) {
                                  if (_fullNameServerError != null ||
                                      _errorMessage != null) {
                                    setState(() {
                                      _fullNameServerError = null;
                                      _errorMessage = null;
                                    });
                                  }
                                },
                                decoration: _inputDecoration(
                                  hintText: 'e.g. Test Traveler',
                                  isCompact: isShort,
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppTheme.primaryNavy,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (_fullNameServerError != null) {
                                    return _fullNameServerError;
                                  }
                                  return FormValidators.validateFullName(value);
                                },
                              ),
                              const SizedBox(height: 6),
                              const Spacer(flex: 2),

                              // 4. Email Address Field
                              Text('Email Address', style: labelStyle),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: const Key('register_email_field'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: AppTheme.textPrimary,
                                ),
                                onChanged: (_) {
                                  if (_emailServerError != null ||
                                      _errorMessage != null) {
                                    setState(() {
                                      _emailServerError = null;
                                      _errorMessage = null;
                                    });
                                  }
                                },
                                decoration: _inputDecoration(
                                  hintText: 'name@example.com',
                                  isCompact: isShort,
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AppTheme.primaryNavy,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (_emailServerError != null) {
                                    return _emailServerError;
                                  }
                                  return FormValidators.validateEmail(value);
                                },
                              ),
                              const SizedBox(height: 6),
                              const Spacer(flex: 2),

                              // 5. Password Field
                              Text('Password', style: labelStyle),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: const Key('register_password_field'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: AppTheme.textPrimary,
                                ),
                                onChanged: (_) {
                                  if (_passwordServerError != null ||
                                      _errorMessage != null) {
                                    setState(() {
                                      _passwordServerError = null;
                                      _errorMessage = null;
                                    });
                                  }
                                },
                                decoration: _inputDecoration(
                                  hintText: 'Enter your password',
                                  isCompact: isShort,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppTheme.primaryNavy,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 36,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                  ),
                                ),
                                validator: (value) {
                                  if (_passwordServerError != null) {
                                    return _passwordServerError;
                                  }
                                  return FormValidators.validatePassword(value);
                                },
                              ),
                              // Password Helper Information Row
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5.0,
                                  bottom: 2.0,
                                  left: 2.0,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 13.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Minimum 8 characters, including a letter and number.',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: isShort ? 11.0 : 11.5,
                                          color: const Color(0xFF64748B),
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Spacer(flex: 2),

                              // 6. Contact Phone Number Field
                              Text('Contact Phone Number', style: labelStyle),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: const Key('register_phone_field'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                enabled: !_isLoading,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  hintText: '77 123 4567',
                                  isCompact: isShort,
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            key: const Key(
                                              'register_country_code_dropdown',
                                            ),
                                            value: _selectedCountryCode,
                                            isDense: true,
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: AppTheme.primaryNavy,
                                              size: 18,
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                            items: _countryCodes.map((code) {
                                              return DropdownMenuItem<String>(
                                                value: code,
                                                child: Text(
                                                  code,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: _isLoading
                                                ? null
                                                : (val) {
                                                    if (val != null) {
                                                      setState(() {
                                                        _selectedCountryCode =
                                                            val;
                                                      });
                                                    }
                                                  },
                                          ),
                                        ),
                                        Container(
                                          height: 22,
                                          width: 1,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                        const Icon(
                                          Icons.phone_outlined,
                                          color: AppTheme.primaryNavy,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final countryErr =
                                      FormValidators.validateCountryCode(
                                        _selectedCountryCode,
                                      );
                                  if (countryErr != null) return countryErr;
                                  return FormValidators.validatePhoneNumber(
                                    value,
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              const Spacer(flex: 2),

                              // 7. Checkbox: "I agree to CeylonGo's Terms and Privacy Notice."
                              InkWell(
                                key: const Key('register_terms_checkbox'),
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _acceptTerms = !_acceptTerms;
                                          if (_acceptTerms) {
                                            _termsError = false;
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _acceptTerms,
                                          activeColor: const Color(0xFF2563EB),
                                          checkColor: Colors.white,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          side: const BorderSide(
                                            color: Color(0xFF94A3B8),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          onChanged: _isLoading
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    _acceptTerms = val ?? false;
                                                    if (_acceptTerms) {
                                                      _termsError = false;
                                                    }
                                                  });
                                                },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: isShort ? 11.5 : 12.5,
                                              color: const Color(0xFF334155),
                                              height: 1.3,
                                            ),
                                            children: const [
                                              TextSpan(
                                                text: "I agree to CeylonGo's ",
                                              ),
                                              TextSpan(
                                                text: 'Terms',
                                                style: TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Notice',
                                                style: TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(text: '.'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_termsError) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: const Text(
                                    "You must agree to CeylonGo's Terms and Privacy Notice to continue",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppTheme.errorRed,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              const Spacer(flex: 3),

                              // 7. Primary Action Button: "Create Account"
                              SizedBox(
                                height: isShort ? 46 : 48,
                                child: ElevatedButton(
                                  key: const Key('register_submit_button'),
                                  onPressed: _isLoading ? null : _onSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: const Color(0x3D2563EB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1D4ED8),
                                          Color(0xFF2563EB),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Create Account',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: isShort
                                                        ? 15.0
                                                        : 15.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Spacer(flex: 3),

                              // 8. Bottom Navigation: "Already have an account? Sign In" near the bottom
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: isShort ? 12.5 : 13.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () {
                                            if (Navigator.canPop(context)) {
                                              Navigator.pop(context);
                                            }
                                          },
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: isShort ? 12.5 : 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
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
          },
        ),
      ),
    );
  }
}

/// Subtle navy and orange wave decoration matching CeylonGo reference design.
/// Retained for backward compatibility with external imports.
class CeylonGoWaveDecoration extends StatelessWidget {
  final double? height;

  const CeylonGoWaveDecoration({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return AuthWaveDecoration(height: height);
  }
}
