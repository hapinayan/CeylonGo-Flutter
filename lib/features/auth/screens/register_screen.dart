import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';

/// CeylonGo Redesigned Tourist Registration (Sign Up) Screen
/// Clean, minimal, mobile-responsive UI optimized for 320px–430px screens
/// Strictly preserves backend authentication contract (FastAPI / SQL Server)
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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
  bool _obscureConfirmPassword = true;
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
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      // Phone number and country code are kept separate on client until backend support is confirmed
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
          arguments: {
            'user': response.user,
            'message': response.message,
          },
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
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        color: AppTheme.textMuted,
        fontSize: 13.5,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      suffixIcon: suffixIcon,
      filled: true,
      isDense: true,
      fillColor: AppTheme.backgroundWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderSlate, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderSlate, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : (screenWidth < 430 ? 20.0 : 24.0);
    final waveHeight = screenWidth < 360 ? 45.0 : 55.0;

    const labelStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Navigation: Back Arrow
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.primaryNavy,
                                size: 24,
                              ),
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              tooltip: 'Back',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Centered CeylonGo Brand Logo
                          Center(
                            child: Image.asset(
                              'assets/images/ceylongo_logo.png',
                              height: screenWidth < 360 ? 56 : 64,
                              fit: BoxFit.contain,
                              semanticLabel: 'CeylonGo Logo',
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Exact Tagline: "Discover Local. Feel at Home."
                          const Center(
                            child: Text(
                              'Discover Local. Feel at Home.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Heading: "Create Your CeylonGo Account" with orange underline
                          Text(
                            'Create Your CeylonGo Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: screenWidth < 360 ? 20 : 21,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryNavy,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Container(
                              width: 42,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          const Text(
                            "Join CeylonGo and start exploring Sri Lanka's local stays, experiences, and more.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Server Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.errorRed.withAlpha(75),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.errorRed,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppTheme.errorRed,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // 1. Full Name Field
                          const Text('Full Name', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('register_full_name_field'),
                            controller: _fullNameController,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
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
                          const SizedBox(height: 12),

                          // 2. Email Address Field
                          const Text('Email Address', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('register_email_field'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
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
                          const SizedBox(height: 12),

                          // 3. Contact Phone Number Field (Unified with Country Code)
                          const Text('Contact Phone Number', style: labelStyle),
                          const SizedBox(height: 5),
                          _buildUnifiedPhoneField(),
                          const SizedBox(height: 12),

                          // 5. Password Field
                          const Text('Password', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('register_password_field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
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
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppTheme.primaryNavy,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textMuted,
                                  size: 20,
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
                          const SizedBox(height: 12),

                          // 6. Confirm Password Field
                          const Text('Confirm Password', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('register_confirm_password_field'),
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => _onSubmit(),
                            decoration: _inputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppTheme.primaryNavy,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                tooltip: _obscureConfirmPassword
                                    ? 'Show password'
                                    : 'Hide password',
                              ),
                            ),
                            validator: (value) =>
                                FormValidators.validateConfirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                          ),
                          const SizedBox(height: 12),

                          // Checkbox: "I agree to CeylonGo's Terms and Privacy Notice."
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
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _acceptTerms,
                                      activeColor: AppTheme.accentOrange,
                                      checkColor: AppTheme.backgroundWhite,
                                      side: const BorderSide(
                                        color: AppTheme.borderSlate,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
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
                                      text: const TextSpan(
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          color: AppTheme.textSecondary,
                                          height: 1.35,
                                        ),
                                        children: [
                                          TextSpan(text: "I agree to CeylonGo's "),
                                          TextSpan(
                                            text: 'Terms',
                                            style: TextStyle(
                                              color: AppTheme.accentOrange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Notice',
                                            style: TextStyle(
                                              color: AppTheme.accentOrange,
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
                            const SizedBox(height: 5),
                            const Padding(
                              padding: EdgeInsets.only(left: 34),
                              child: Text(
                                "You must agree to CeylonGo's Terms and Privacy Notice to continue",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppTheme.errorRed,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Primary Button: "Create Account"
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              key: const Key('register_submit_button'),
                              onPressed: _isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: AppTheme.backgroundWhite,
                                disabledBackgroundColor: AppTheme.accentOrange
                                    .withAlpha(150),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppTheme.backgroundWhite,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.backgroundWhite,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bottom Navigation: "Already have an account? Sign In"
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                      },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentOrange,
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
              const SizedBox(height: 12),

              // Subtle Navy and Orange Wave Decoration at the Bottom
              CeylonGoWaveDecoration(height: waveHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedPhoneField() {
    return TextFormField(
      key: const Key('register_phone_field'),
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
      decoration: _inputDecoration(
        hintText: '77 123 4567',
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('register_country_code_dropdown'),
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
                              _selectedCountryCode = val;
                            });
                          }
                        },
                ),
              ),
              Container(
                height: 22,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: AppTheme.borderSlate,
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
        final countryErr = FormValidators.validateCountryCode(_selectedCountryCode);
        if (countryErr != null) return countryErr;
        return FormValidators.validatePhoneNumber(value);
      },
    );
  }
}

/// Subtle navy and orange wave decoration matching CeylonGo reference design
class CeylonGoWaveDecoration extends StatelessWidget {
  final double height;

  const CeylonGoWaveDecoration({super.key, this.height = 55});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CeylonGoWavePainter(),
      ),
    );
  }
}

class _CeylonGoWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Orange accent wave (background wave)
    final orangePaint = Paint()
      ..color = AppTheme.accentOrange
      ..style = PaintingStyle.fill;

    final orangePath = Path();
    orangePath.moveTo(0, size.height * 0.45);
    orangePath.quadraticBezierTo(
      size.width * 0.28,
      size.height * 0.1,
      size.width * 0.58,
      size.height * 0.5,
    );
    orangePath.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.85,
      size.width,
      size.height * 0.4,
    );
    orangePath.lineTo(size.width, size.height);
    orangePath.lineTo(0, size.height);
    orangePath.close();
    canvas.drawPath(orangePath, orangePaint);

    // Navy primary wave (foreground wave)
    final navyPaint = Paint()
      ..color = AppTheme.primaryNavy
      ..style = PaintingStyle.fill;

    final navyPath = Path();
    navyPath.moveTo(0, size.height * 0.65);
    navyPath.quadraticBezierTo(
      size.width * 0.24,
      size.height * 0.35,
      size.width * 0.52,
      size.height * 0.7,
    );
    navyPath.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.98,
      size.width,
      size.height * 0.6,
    );
    navyPath.lineTo(size.width, size.height);
    navyPath.lineTo(0, size.height);
    navyPath.close();
    canvas.drawPath(navyPath, navyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
