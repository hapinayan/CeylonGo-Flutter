import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_wave_decoration.dart';
import '../widgets/password_checklist.dart';

/// Screen 8: Create New Password Screen
/// Includes dynamic password strength indicator, validation checklist,
/// and backend verification
class CreateNewPasswordScreen extends StatefulWidget {
  final AuthService? authService;
  final String? resetToken;

  const CreateNewPasswordScreen({
    super.key,
    this.authService,
    this.resetToken,
  });

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    if (widget.resetToken != null) {
      _tokenController.text = widget.resetToken!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tokenController.text.isEmpty) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final argToken = args?['token'] as String?;
      if (argToken != null && argToken.isNotEmpty) {
        _tokenController.text = argToken;
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    setState(() {
      _errorMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = _tokenController.text.trim();
    final newPassword = _passwordController.text;

    try {
      // Connect to real backend reset endpoint
      await _authService.confirmPasswordReset(
        token: token,
        newPassword: newPassword,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to Screen 9 only after confirmed backend update
        Navigator.pushReplacementNamed(context, '/password-reset-success');
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.code == 'BACKEND_NOT_CONFIGURED'
              ? 'Password reset is not yet supported by the CeylonGo backend server. Please contact support@ceylongo.com.'
              : e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'An unexpected error occurred while updating your password.';
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
                            title: 'Create New Password',
                            subtitle:
                                'Your new password must be different from previous passwords.',
                          ),
                          const SizedBox(height: 22),

                          // Server Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              key: const Key('reset_error_banner'),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.errorRed.withAlpha(75),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
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

                          // Reset Code / Token Field
                          const Text('Reset Code / Token', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('reset_token_field'),
                            controller: _tokenController,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter or paste your reset token';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Paste reset token from email',
                              prefixIcon: Icon(
                                Icons.key_outlined,
                                color: AppTheme.primaryNavy,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // New Password Field
                          const Text('New Password', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('new_password_field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
                            onChanged: (_) {
                              // Trigger rebuild for password strength checklist
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter new password',
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
                            validator: FormValidators.validatePassword,
                          ),
                          const SizedBox(height: 12),

                          // Password Strength Indicator & Checklist
                          PasswordChecklist(
                            password: _passwordController.text,
                          ),
                          const SizedBox(height: 14),

                          // Confirm New Password Field
                          const Text('Confirm New Password', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('confirm_new_password_field'),
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => _onSubmit(),
                            decoration: InputDecoration(
                              hintText: 'Re-enter new password',
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
                            validator: (val) =>
                                FormValidators.validateConfirmPassword(
                              val,
                              _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Reset Password Primary Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              key: const Key('reset_password_button'),
                              onPressed: _isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: AppTheme.backgroundWhite,
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
                                      'Reset Password',
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

                          // Back to Sign In Link
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              },
                              child: const Text(
                                'Back to Sign In',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
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

