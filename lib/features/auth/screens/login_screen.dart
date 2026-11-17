import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';

/// Screen 4: Full-Screen Clean White CeylonGo Login Screen
/// Balanced, evenly distributed full-screen layout optimized for Samsung Galaxy A22.
/// Authenticates traveler via real FastAPI backend contract.
class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  final SecureStorageService? storageService;
  final String? initialEmail;

  const LoginScreen({
    super.key,
    this.authService,
    this.storageService,
    this.initialEmail,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;
  late final SecureStorageService _storageService;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailServerError;
  String? _passwordServerError;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _storageService = widget.storageService ?? SecureStorageService();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emailController.text.isEmpty) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final argEmail = args?['email'] as String?;
      if (argEmail != null && argEmail.isNotEmpty) {
        _emailController.text = argEmail;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onForgotPasswordTapped() {
    Navigator.pushNamed(
      context,
      '/forgot-password',
      arguments: {'email': _emailController.text.trim()},
    );
  }

  Future<void> _onSubmit() async {
    setState(() {
      _errorMessage = null;
      _emailServerError = null;
      _passwordServerError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text, // Never trim passwords
      );

      // Securely persist token and user profile
      try {
        await _storageService.saveToken(response.accessToken);
        await _storageService.saveUser(response.user);
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to securely store authentication token.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to Screen 5: Login Successful
        Navigator.pushReplacementNamed(
          context,
          '/login-success',
          arguments: {'user': response.user},
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          if (e.fields.containsKey('email')) {
            _emailServerError = e.fields['email'];
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
                                    key: const Key('login_back_button'),
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Container(
                                      key: const Key('auth_back_button'),
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

                              // 2. Extra-bold Dark Navy Heading: "Sign In to CeylonGo"
                              Text(
                                'Sign In to CeylonGo',
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

                              // Subtitle: "Welcome back! Please sign in to your account."
                              Text(
                                'Welcome back! Please sign in to your account.',
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

                              // 3. Email Address Field
                              Text('Email Address', style: labelStyle),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: const Key('login_email_field'),
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
                              const SizedBox(height: 8),
                              const Spacer(flex: 2),

                              // 4. Password Field
                              Text('Password', style: labelStyle),
                              const SizedBox(height: 4),
                              TextFormField(
                                key: const Key('login_password_field'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                enabled: !_isLoading,
                                onFieldSubmitted: (_) => _onSubmit(),
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
                                  return FormValidators.validateLoginPassword(
                                    value,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),

                              // 5. Blue "Forgot Password?" link below Password field, aligned right
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  key: const Key('forgot_password_link'),
                                  onTap: _isLoading
                                      ? null
                                      : _onForgotPasswordTapped,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Spacer(flex: 3),

                              // 6. Royal-Blue Gradient Pill-Shaped "Sign In →" Button
                              SizedBox(
                                height: isShort ? 46 : 48,
                                child: ElevatedButton(
                                  key: const Key('login_submit_button'),
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
                                                  'Sign In',
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
                              const SizedBox(height: 12),
                              const Spacer(flex: 4),

                              // 7. Bottom Link: "Don't have an account? Create Account" near bottom SafeArea
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: isShort ? 12.5 : 13.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  GestureDetector(
                                    key: const Key('login_create_account_link'),
                                    onTap: _isLoading
                                        ? null
                                        : () {
                                            Navigator.pushNamed(
                                              context,
                                              '/register',
                                              arguments: {
                                                'email': _emailController.text
                                                    .trim(),
                                              },
                                            );
                                          },
                                    child: Text(
                                      'Create Account',
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
