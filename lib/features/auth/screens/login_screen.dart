import 'package:flutter/material.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';

/// CeylonGo Login Screen
/// Conforms to Sections 1–4 and 7 of Common Development Specification v1.0
class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  final SecureStorageService? storageService;

  const LoginScreen({super.key, this.authService, this.storageService});

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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onForgotPasswordTapped() {
    // Specification Section 1:
    // Visible link only; show "Password reset is coming soon" (no backend call)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset is coming soon'),
        backgroundColor: AppTheme.primaryNavy,
        duration: Duration(seconds: 3),
      ),
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
        // Do not claim login succeeded if secure storage failed
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
        // Prepare successful login navigation to /home
        Navigator.pushReplacementNamed(context, '/home');
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                color: AppTheme.backgroundWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderSlate),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // CeylonGo Brand Header
                        Image.asset(
                          'assets/images/ceylongo_logo.png',
                          height: 100,
                          fit: BoxFit.contain,
                          semanticLabel: 'CeylonGo Logo',
                        ),
                        const SizedBox(height: 24),

                        // Error Banner UI (Accessible)
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
                                      color: AppTheme.errorRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
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
                          decoration: const InputDecoration(
                            hintText: 'name@example.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppTheme.textMuted,
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
                        const SizedBox(height: 20),

                        // Password Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : _onForgotPasswordTapped,
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
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
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppTheme.textMuted,
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
                            return FormValidators.validateLoginPassword(value);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Sign In Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: AppTheme.backgroundWhite,
                            disabledBackgroundColor: AppTheme.accentOrange
                                .withAlpha(150),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Navigation
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
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
      ),
    );
  }
}
