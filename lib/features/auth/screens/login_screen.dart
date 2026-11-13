import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_wave_decoration.dart';

/// Screen 4: Welcome Back (Login) Screen
/// Authenticates traveler via real FastAPI backend contract
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
    // Navigates to Screen 6: Forgot Password flow
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth < 360 ? 16.0 : (screenWidth < 430 ? 20.0 : 24.0);

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
                          // Top Header with Back Arrow
                          const AuthHeader(showBack: true),
                          const SizedBox(height: 18),

                          // Heading with signature orange underline
                          const AuthHeading(
                            title: 'Welcome Back',
                            subtitle:
                                'Sign in to continue your CeylonGo journey',
                          ),
                          const SizedBox(height: 22),

                          // Error Banner UI
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
                            const SizedBox(height: 14),
                          ],

                          // Email Address Field
                          const Text('Email Address', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('login_email_field'),
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
                            decoration: InputDecoration(
                              hintText: 'name@example.com',
                              hintStyle: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppTheme.textMuted,
                                fontSize: 13.5,
                              ),
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppTheme.primaryNavy,
                                size: 20,
                              ),
                              filled: true,
                              isDense: true,
                              fillColor: AppTheme.backgroundWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderSlate,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderSlate,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryNavy,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.errorRed,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.errorRed,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (_emailServerError != null) {
                                return _emailServerError;
                              }
                              return FormValidators.validateEmail(value);
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password Field Label + Forgot Password link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text('Password', style: labelStyle),
                              ),
                              Flexible(
                                child: GestureDetector(
                                  key: const Key('forgot_password_link'),
                                  onTap: _isLoading
                                      ? null
                                      : _onForgotPasswordTapped,
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentOrange,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('login_password_field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => _onSubmit(),
                            onChanged: (_) {
                              if (_passwordServerError != null ||
                                  _errorMessage != null) {
                                setState(() {
                                  _passwordServerError = null;
                                  _errorMessage = null;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppTheme.textMuted,
                                fontSize: 13.5,
                              ),
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
                              filled: true,
                              isDense: true,
                              fillColor: AppTheme.backgroundWhite,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderSlate,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderSlate,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryNavy,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.errorRed,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.errorRed,
                                  width: 1.5,
                                ),
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
                          const SizedBox(height: 20),

                          // Sign In Primary Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              key: const Key('login_submit_button'),
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
                                      'Sign In',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.backgroundWhite,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Sign Up Navigation Link
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
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
                                        Navigator.pushNamed(
                                          context,
                                          '/register',
                                          arguments: {
                                            'email':
                                                _emailController.text.trim()
                                          },
                                        );
                                      },
                                child: const Text(
                                  'Create Account',
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
              const SizedBox(height: 16),
              const AuthWaveDecoration(),
            ],
          ),
        ),
      ),
    );
  }
}
