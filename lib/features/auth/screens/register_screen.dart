import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';
import '../widgets/auth_trust_footer.dart';
import '../widgets/auth_wave_decoration.dart';

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
    bool isCompact = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        color: AppTheme.textMuted,
        fontSize: isCompact ? 12.5 : 13.5,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints ??
          BoxConstraints(
            minWidth: isCompact ? 36 : 44,
            minHeight: isCompact ? 32 : 40,
          ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIcon != null
          ? BoxConstraints(
              minWidth: isCompact ? 36 : 44,
              minHeight: isCompact ? 32 : 40,
            )
          : null,
      filled: true,
      isDense: true,
      fillColor: AppTheme.backgroundWhite,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: isCompact ? 8 : 12,
      ),
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
      errorStyle: TextStyle(
        fontFamily: 'Inter',
        color: AppTheme.errorRed,
        fontSize: isCompact ? 11.5 : 12.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isCompact = constraints.maxHeight <= 820;
            final isShort = constraints.maxHeight < 680;
            final showTrustFooter = constraints.maxHeight >= 680;

            final horizontalPadding = screenWidth < 360
                ? 16.0
                : (screenWidth < 430 ? 20.0 : 24.0);
            final waveHeight = isShort ? 26.0 : (isCompact ? 32.0 : 50.0);
            final logoHeight = isShort ? 30.0 : (isCompact ? 36.0 : 56.0);
            final fieldGap = isShort ? 4.0 : (isCompact ? 6.0 : 12.0);
            final labelGap = isShort ? 1.5 : (isCompact ? 2.0 : 3.0);

            final labelStyle = TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 12.5 : 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            );

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isShort ? 2.0 : (isCompact ? 4.0 : 10.0),
                        horizontalPadding,
                        0,
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
                                    style: IconButton.styleFrom(
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: Size.zero,
                                      padding: EdgeInsets.zero,
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: AppTheme.primaryNavy,
                                      size: 22,
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
                                SizedBox(height: isShort ? 2 : (isCompact ? 3 : 8)),

                                // Centered CeylonGo Brand Logo
                                Center(
                                  child: Image.asset(
                                    'assets/images/ceylongo_logo.png',
                                    height: logoHeight,
                                    fit: BoxFit.contain,
                                    semanticLabel: 'CeylonGo Logo',
                                  ),
                                ),
                                SizedBox(height: isShort ? 1 : (isCompact ? 2 : 6)),

                                // Exact Tagline: "Discover Local. Feel at Home."
                                Center(
                                  child: Text(
                                    'Discover Local. Feel at Home.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: isCompact ? 11.5 : 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: isShort ? 5 : (isCompact ? 8 : 18),
                                ),

                                // Heading: "Create Your CeylonGo Account" with orange underline
                                Text(
                                  'Create Your CeylonGo Account',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isShort
                                        ? 16.5
                                        : (isCompact ? 17.5 : 21),
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: isShort ? 2 : 3),
                                Center(
                                  child: Container(
                                    width: isCompact ? 36 : 42,
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentOrange,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isShort ? 3 : 5),

                                // Subtitle
                                Text(
                                  "Join CeylonGo and start exploring Sri Lanka's local stays, experiences, and more.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 11.5 : 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.25,
                                  ),
                                ),
                                SizedBox(
                                  height: isShort ? 6 : (isCompact ? 8 : 18),
                                ),

                                // Server Error Banner
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: EdgeInsets.all(isCompact ? 8 : 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.errorRed.withAlpha(75),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppTheme.errorRed,
                                          size: isCompact ? 18 : 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: AppTheme.errorRed,
                                              fontSize: isCompact ? 12 : 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 6 : 12),
                                ],

                                // 1. Full Name Field
                                Text('Full Name', style: labelStyle),
                                SizedBox(height: labelGap),
                                TextFormField(
                                  key: const Key('register_full_name_field'),
                                  controller: _fullNameController,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isLoading,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 13.0 : 13.5,
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
                                    isCompact: isCompact,
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      color: AppTheme.primaryNavy,
                                      size: isCompact ? 18 : 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_fullNameServerError != null) {
                                      return _fullNameServerError;
                                    }
                                    return FormValidators.validateFullName(value);
                                  },
                                ),
                                SizedBox(height: fieldGap),

                                // 2. Email Address Field
                                Text('Email Address', style: labelStyle),
                                SizedBox(height: labelGap),
                                TextFormField(
                                  key: const Key('register_email_field'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isLoading,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 13.0 : 13.5,
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
                                    isCompact: isCompact,
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: AppTheme.primaryNavy,
                                      size: isCompact ? 18 : 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_emailServerError != null) {
                                      return _emailServerError;
                                    }
                                    return FormValidators.validateEmail(value);
                                  },
                                ),
                                SizedBox(height: fieldGap),

                                // 3. Contact Phone Number Field (Unified with Country Code)
                                Text('Contact Phone Number', style: labelStyle),
                                SizedBox(height: labelGap),
                                _buildUnifiedPhoneField(isCompact: isCompact),
                                SizedBox(height: fieldGap),

                                // 4. Password Field
                                Text('Password', style: labelStyle),
                                SizedBox(height: labelGap),
                                TextFormField(
                                  key: const Key('register_password_field'),
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isLoading,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 13.0 : 13.5,
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
                                    isCompact: isCompact,
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppTheme.primaryNavy,
                                      size: isCompact ? 18 : 20,
                                    ),
                                    suffixIcon: IconButton(
                                      style: IconButton.styleFrom(
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        minimumSize: Size.zero,
                                        padding: EdgeInsets.zero,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppTheme.textMuted,
                                        size: isCompact ? 18 : 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth: isCompact ? 36 : 42,
                                        minHeight: isCompact ? 32 : 40,
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
                                SizedBox(height: fieldGap),

                                // 5. Confirm Password Field
                                Text('Confirm Password', style: labelStyle),
                                SizedBox(height: labelGap),
                                TextFormField(
                                  key: const Key(
                                    'register_confirm_password_field',
                                  ),
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  enabled: !_isLoading,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isCompact ? 13.0 : 13.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                  onFieldSubmitted: (_) => _onSubmit(),
                                  decoration: _inputDecoration(
                                    hintText: 'Re-enter your password',
                                    isCompact: isCompact,
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      color: AppTheme.primaryNavy,
                                      size: isCompact ? 18 : 20,
                                    ),
                                    suffixIcon: IconButton(
                                      style: IconButton.styleFrom(
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        minimumSize: Size.zero,
                                        padding: EdgeInsets.zero,
                                      ),
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppTheme.textMuted,
                                        size: isCompact ? 18 : 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth: isCompact ? 36 : 42,
                                        minHeight: isCompact ? 32 : 40,
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
                                SizedBox(height: fieldGap),

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
                                    padding: EdgeInsets.symmetric(
                                      vertical: isCompact ? 2 : 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: isCompact ? 20 : 24,
                                          height: isCompact ? 20 : 24,
                                          child: Checkbox(
                                            value: _acceptTerms,
                                            activeColor: AppTheme.accentOrange,
                                            checkColor:
                                                AppTheme.backgroundWhite,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            side: const BorderSide(
                                              color: AppTheme.borderSlate,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            onChanged: _isLoading
                                                ? null
                                                : (val) {
                                                    setState(() {
                                                      _acceptTerms =
                                                          val ?? false;
                                                      if (_acceptTerms) {
                                                        _termsError = false;
                                                      }
                                                    });
                                                  },
                                          ),
                                        ),
                                        SizedBox(width: isCompact ? 8 : 10),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: isCompact
                                                    ? 11.0
                                                    : 12.5,
                                                color: AppTheme.textSecondary,
                                                height: 1.25,
                                              ),
                                              children: const [
                                                TextSpan(
                                                  text:
                                                      "I agree to CeylonGo's ",
                                                ),
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
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isCompact ? 28 : 34,
                                    ),
                                    child: const Text(
                                      "You must agree to CeylonGo's Terms and Privacy Notice to continue",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppTheme.errorRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(
                                  height: isShort ? 6 : (isCompact ? 8 : 18),
                                ),

                                // Primary Button: "Create Account"
                                SizedBox(
                                  height: isCompact ? 42 : 48,
                                  child: ElevatedButton(
                                    key: const Key('register_submit_button'),
                                    onPressed: _isLoading ? null : _onSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentOrange,
                                      foregroundColor:
                                          AppTheme.backgroundWhite,
                                      disabledBackgroundColor: AppTheme
                                          .accentOrange
                                          .withAlpha(150),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppTheme.backgroundWhite,
                                            ),
                                          )
                                        : Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: isCompact ? 15 : 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.backgroundWhite,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  height: isShort ? 4 : (isCompact ? 6 : 16),
                                ),

                                // Bottom Navigation: "Already have an account? Sign In"
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: isCompact ? 12.5 : 13.5,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _isLoading
                                          ? null
                                          : () {
                                              Navigator.pop(context);
                                            },
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: isCompact ? 12.5 : 13.5,
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

                    if (showTrustFooter)
                      AuthTrustFooter(isCompact: isCompact),

                    // Subtle Navy and Orange Wave Decoration at the Bottom
                    CeylonGoWaveDecoration(height: waveHeight),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnifiedPhoneField({required bool isCompact}) {
    return TextFormField(
      key: const Key('register_phone_field'),
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: isCompact ? 13.0 : 13.5,
        color: AppTheme.textPrimary,
      ),
      decoration: _inputDecoration(
        hintText: '77 123 4567',
        isCompact: isCompact,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: isCompact ? 8 : 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('register_country_code_dropdown'),
                  value: _selectedCountryCode,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryNavy,
                    size: isCompact ? 16 : 18,
                  ),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 12.5 : 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  items: _countryCodes.map((code) {
                    return DropdownMenuItem<String>(
                      value: code,
                      child: Text(
                        code,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompact ? 12.5 : 13,
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
                height: isCompact ? 18 : 22,
                width: 1,
                margin: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8),
                color: AppTheme.borderSlate,
              ),
              Icon(
                Icons.phone_outlined,
                color: AppTheme.primaryNavy,
                size: isCompact ? 17 : 19,
              ),
              SizedBox(width: isCompact ? 6 : 8),
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

/// Subtle navy and orange wave decoration matching CeylonGo reference design.
/// Wraps [AuthWaveDecoration] for consistency across authentication screens.
class CeylonGoWaveDecoration extends StatelessWidget {
  final double? height;

  const CeylonGoWaveDecoration({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return AuthWaveDecoration(height: height);
  }
}
