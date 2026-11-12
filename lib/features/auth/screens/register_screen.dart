import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';

/// CeylonGo Register Screen (Traveler Registration)
/// Conforms to Sections 1–4 and 7 of Common Development Specification v1.0
class RegisterScreen extends StatefulWidget {
  final AuthService? authService;

  const RegisterScreen({super.key, this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;

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
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
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
      // Section 4.1: registration payload contains ONLY full_name, email, password
      final response = await _authService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text, // Never trim passwords
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

        // Navigate to /login (do not auto-login or store token per Section 1 & 7)
        Navigator.pop(context);
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
                          height: 90,
                          fit: BoxFit.contain,
                          semanticLabel: 'CeylonGo Logo',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Create Traveler Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 20),

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

                        // Full Name Field
                        const Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
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
                          decoration: const InputDecoration(
                            hintText: 'e.g. Test Traveler',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppTheme.textMuted,
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
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 16),

                        // Password Field
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
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
                          decoration: InputDecoration(
                            hintText: 'At least 8 chars (upper, lower, digit)',
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
                            return FormValidators.validatePassword(value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        const Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          onFieldSubmitted: (_) => _onSubmit(),
                          decoration: InputDecoration(
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppTheme.textMuted,
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
                        const SizedBox(height: 16),

                        // Terms & Privacy Checkbox
                        InkWell(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    activeColor: AppTheme.primaryNavy,
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
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'I agree to the Terms of Service and Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_termsError) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'You must agree to the Terms & Privacy Policy to continue',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Create Account Submit Button
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Sign In Navigation
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 14,
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
