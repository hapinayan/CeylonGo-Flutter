import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_wave_decoration.dart';

/// Screen 6: Forgot Password Screen
/// Validates registered email and checks real backend password-reset support
class ForgotPasswordScreen extends StatefulWidget {
  final AuthService? authService;
  final String? initialEmail;

  const ForgotPasswordScreen({
    super.key,
    this.authService,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final AuthService _authService;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
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
    super.dispose();
  }

  Future<void> _onSendResetLink() async {
    setState(() {
      _statusMessage = null;
      _isError = false;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();

    try {
      // Connect to real backend password-reset request endpoint if supported
      await _authService.requestPasswordReset(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to Screen 7 only when backend confirmed success
        Navigator.pushNamed(
          context,
          '/check-email',
          arguments: {'email': email},
        );
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          // Honest status per specification: never fake email transmission
          _statusMessage = e.code == 'BACKEND_NOT_CONFIGURED'
              ? 'Password reset is not yet supported by the CeylonGo backend server. Please contact support@ceylongo.com for assistance.'
              : e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _statusMessage =
              'An unexpected error occurred while contacting the server.';
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
                          // Header with Back Arrow
                          const AuthHeader(showBack: true),
                          const SizedBox(height: 18),

                          // Heading with signature orange underline
                          const AuthHeading(
                            title: 'Forgot Password',
                            subtitle:
                                'Enter your registered email and we will send password reset instructions.',
                          ),
                          const SizedBox(height: 24),

                          // Status Message Banner (Honest backend reporting)
                          if (_statusMessage != null) ...[
                            Container(
                              key: const Key('forgot_password_status_banner'),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isError
                                    ? AppTheme.errorRed.withAlpha(25)
                                    : AppTheme.successGreen.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isError
                                      ? AppTheme.errorRed.withAlpha(75)
                                      : AppTheme.successGreen.withAlpha(75),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    _isError
                                        ? Icons.error_outline_rounded
                                        : Icons.check_circle_outline_rounded,
                                    color: _isError
                                        ? AppTheme.errorRed
                                        : AppTheme.successGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _statusMessage!,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: _isError
                                            ? AppTheme.errorRed
                                            : AppTheme.successGreen,
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

                          // Email Address Field
                          const Text('Email Address', style: labelStyle),
                          const SizedBox(height: 5),
                          TextFormField(
                            key: const Key('forgot_email_field'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => _onSendResetLink(),
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
                            validator: FormValidators.validateEmail,
                          ),
                          const SizedBox(height: 20),

                          // Send Reset Link Primary Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              key: const Key('send_reset_link_button'),
                              onPressed: _isLoading ? null : _onSendResetLink,
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
                                      'Send Reset Link',
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

                          // Back to Sign In link
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Remember your password? ',
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
                          const SizedBox(height: 16),

                          // Preview flow link for testing UI flow
                          Center(
                            child: TextButton.icon(
                              key: const Key('preview_check_email_link'),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/check-email',
                                  arguments: {
                                    'email': _emailController.text.isNotEmpty
                                        ? _emailController.text
                                        : 'traveler@ceylongo.com'
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.remove_red_eye_outlined,
                                size: 16,
                                color: AppTheme.primaryNavy,
                              ),
                              label: const Text(
                                'Preview Email Screen (Demo Flow)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
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

