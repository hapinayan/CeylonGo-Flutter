import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../models/api_error.dart';
import '../services/auth_service.dart';
import '../widgets/light_blue_wave_decoration.dart';

/// Screen 6: Forgot Password Screen
/// Clean, minimal full-screen layout matching CeylonGo reference design.
/// Validates email and submits password reset request to backend.
class ForgotPasswordScreen extends StatefulWidget {
  final AuthService? authService;
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.authService, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

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
    _emailFocusNode.dispose();
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
      await _authService.requestPasswordReset(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to Screen 2 (Reset Email Sent) only when backend confirmed success
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final availableHeight = constraints.maxHeight;
            final isShort = availableHeight < 680;

            final horizontalPadding = screenWidth < 360
                ? 18.0
                : (screenWidth < 430 ? 22.0 : 26.0);
            final topPadding = isShort ? 8.0 : 12.0;

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
                      ScrollViewKeyboardDismissBehavior.manual,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            topPadding,
                            horizontalPadding,
                            16,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. Circular Outlined Back Button near top-left
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      key: const Key('forgot_back_button'),
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
                                SizedBox(height: isShort ? 14 : 22),

                                // 2. Bold Dark Navy Heading: "Forgot Password?"
                                Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isShort ? 22.0 : 25.0,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryNavy,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // 3. Subtitle: "Enter your email address to reset your password."
                                Text(
                                  'Enter your email address to reset your password.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: isShort ? 12.5 : 13.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: isShort ? 18 : 24),

                                // Status Error Banner (Honest backend reporting)
                                if (_statusMessage != null) ...[
                                  Container(
                                    key: const Key(
                                      'forgot_password_status_banner',
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isError
                                          ? AppTheme.errorRed.withAlpha(25)
                                          : AppTheme.successGreen.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _isError
                                            ? AppTheme.errorRed.withAlpha(75)
                                            : AppTheme.successGreen.withAlpha(
                                                75,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isError
                                              ? Icons.error_outline_rounded
                                              : Icons
                                                    .check_circle_outline_rounded,
                                          color: _isError
                                              ? AppTheme.errorRed
                                              : AppTheme.successGreen,
                                          size: 18,
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
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // 4. Rounded Email Address Input Field
                                Text('Email Address', style: labelStyle),
                                const SizedBox(height: 4),
                                TextFormField(
                                  key: const Key('forgot_email_field'),
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  enabled: !_isLoading,
                                  onFieldSubmitted: (_) => _onSendResetLink(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email address',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      color: const Color(0xFF94A3B8),
                                      fontSize: isShort ? 12.5 : 13.5,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: AppTheme.primaryNavy,
                                      size: 20,
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: isShort ? 38 : 42,
                                      minHeight: isShort ? 34 : 38,
                                    ),
                                    filled: true,
                                    isDense: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isShort ? 12 : 14,
                                      vertical: isShort ? 10 : 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.errorRed,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.errorRed,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorStyle: TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppTheme.errorRed,
                                      fontSize: isShort ? 11.0 : 11.5,
                                    ),
                                  ),
                                  validator: FormValidators.validateEmail,
                                ),
                                SizedBox(height: isShort ? 20 : 28),

                                // 5. Full-width blue gradient "Send Reset Link →" Button
                                SizedBox(
                                  height: isShort ? 46 : 48,
                                  child: ElevatedButton(
                                    key: const Key('send_reset_link_button'),
                                    onPressed: _isLoading
                                        ? null
                                        : _onSendResetLink,
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
                                                child:
                                                    CircularProgressIndicator(
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
                                                    'Send Reset Link',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: isShort
                                                          ? 15.0
                                                          : 15.5,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                const SizedBox(height: 18),

                                // 6. Blue "← Back to Sign In" link
                                Center(
                                  child: GestureDetector(
                                    key: const Key('back_to_signin_link'),
                                    onTap: _isLoading
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                          },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.arrow_back_rounded,
                                            size: 16,
                                            color: Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Back to Sign In',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: isShort ? 12.5 : 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 7. Light-blue bottom wave decoration anchored to the bottom
                        const LightBlueWaveDecoration(height: 70),
                      ],
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
