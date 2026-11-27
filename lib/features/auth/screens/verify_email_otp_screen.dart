import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/api_error.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/light_blue_wave_decoration.dart';

/// Email OTP Verification Screen
/// Completes traveler registration via POST /api/v1/auth/verify-email
/// and supports resending codes via POST /api/v1/auth/resend-email-otp.
class VerifyEmailOtpScreen extends StatefulWidget {
  final AuthService? authService;
  final String? email;
  final String? registrationId;
  final String? fullName;
  final int initialResendAfter;

  const VerifyEmailOtpScreen({
    super.key,
    this.authService,
    this.email,
    this.registrationId,
    this.fullName,
    this.initialResendAfter = 60,
  });

  @override
  State<VerifyEmailOtpScreen> createState() => _VerifyEmailOtpScreenState();
}

class _VerifyEmailOtpScreenState extends State<VerifyEmailOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  late final AuthService _authService;

  String _email = '';
  String _registrationId = '';
  String _fullName = '';
  bool _argsLoaded = false;

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _infoMessage;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _email = widget.email ?? '';
    _registrationId = widget.registrationId ?? '';
    _fullName = widget.fullName ?? '';
    _startCooldown(widget.initialResendAfter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _argsLoaded = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _email = (args['email'] as String?) ?? _email;
        _registrationId =
            (args['registrationId'] as String?) ?? _registrationId;
        _fullName = (args['fullName'] as String?) ?? _fullName;
        final resendAfter = args['resendAfter'] as int?;
        if (resendAfter != null && resendAfter > 0) {
          _startCooldown(resendAfter);
        }
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    if (seconds <= 0) {
      setState(() => _cooldownSeconds = 0);
      return;
    }
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  Future<void> _onVerify() async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_email.isEmpty || _registrationId.isEmpty) {
      setState(() {
        _errorMessage =
            'Registration session details are missing. Please register again.';
      });
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final message = await _authService.verifyEmailOtp(
        email: _email,
        registrationId: _registrationId,
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isVerifying = false);

      Navigator.pushReplacementNamed(
        context,
        '/registration-success',
        arguments: {
          'user': UserModel(
            id: '',
            fullName: _fullName,
            email: _email,
            role: 'traveler',
            emailVerified: true,
          ),
          'message': message,
        },
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Unable to verify code. Please try again.';
      });
    }
  }

  Future<void> _onResend() async {
    if (_isResending || _cooldownSeconds > 0) return;

    if (_email.isEmpty || _registrationId.isEmpty) {
      setState(() {
        _errorMessage = 'Registration session missing. Please register again.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final challenge = await _authService.resendEmailOtp(
        email: _email,
        registrationId: _registrationId,
      );
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _registrationId = challenge.registrationId;
        _infoMessage = challenge.message;
      });
      _startCooldown(challenge.resendAfter);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = 'Failed to resend verification code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const royalBlue = Color(0xFF0A4DF5);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
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
                                const AuthHeader(showBack: true),
                                const SizedBox(height: 20),
                                AuthHeading(
                                  title: 'Verify Your Email',
                                  subtitle:
                                      'Enter the 6-digit verification code sent to ${_email.isNotEmpty ? _email : 'your email address'}.',
                                  underlineColor: royalBlue,
                                ),
                                const SizedBox(height: 22),

                                if (_errorMessage != null) ...[
                                  Container(
                                    key: const Key('otp_error_banner'),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.errorRed.withAlpha(75),
                                      ),
                                    ),
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
                                  const SizedBox(height: 14),
                                ],

                                if (_infoMessage != null) ...[
                                  Container(
                                    key: const Key('otp_info_banner'),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            AppTheme.successGreen.withAlpha(75),
                                      ),
                                    ),
                                    child: Text(
                                      _infoMessage!,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: AppTheme.successGreen,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                const Text(
                                  'Verification Code',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  key: const Key('verify_otp_field'),
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  enabled: !_isVerifying,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                    color: AppTheme.primaryNavy,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '000000',
                                    counterText: '',
                                    filled: true,
                                    fillColor: AppTheme.backgroundWhite,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderSlate,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryNavy,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    final clean = value?.trim() ?? '';
                                    if (clean.length != 6) {
                                      return 'Enter the 6-digit verification code';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    key: const Key('verify_otp_submit_btn'),
                                    onPressed: _isVerifying ? null : _onVerify,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentOrange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isVerifying
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Verify Email & Create Account',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                Center(
                                  child: TextButton(
                                    key: const Key('resend_otp_btn'),
                                    onPressed: (_isResending ||
                                            _cooldownSeconds > 0)
                                        ? null
                                        : _onResend,
                                    child: _isResending
                                        ? const Text('Sending new code...')
                                        : Text(
                                            _cooldownSeconds > 0
                                                ? 'Resend code in ${_cooldownSeconds}s'
                                                : 'Resend Verification Code',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                              color: royalBlue,
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
                    const LightBlueWaveDecoration(height: 70),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
