import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/secure_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../artisan/services/artisan_demo_service.dart';
import '../models/api_error.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_trust_footer.dart';
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
  bool _isSuccessPopupShowing = false;
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

  static const String demoEmail = 'demo@ceylongo.com';
  static const String demoPassword = 'Demo@1234';

  void _onDemoLogin() {
    _emailController.text = demoEmail;
    _passwordController.text = demoPassword;
    _onSubmit();
  }

  Future<void> _showLoginSuccessPopupAndNavigate({
    String targetRoute = '/home',
  }) async {
    if (!mounted || _isSuccessPopupShowing) return;
    _isSuccessPopupShowing = true;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Login Successful',
      barrierColor: Colors.black.withAlpha(90),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              key: const Key('login_success_popup'),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDBEAFE),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withAlpha(30),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.successGreen.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      key: Key('login_success_popup_icon'),
                      color: AppTheme.successGreen,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Login Successful!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Welcome to CeylonGo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      targetRoute,
      (route) => false,
    );
  }

  Future<void> _onSubmit() async {
    if (_isLoading || _isSuccessPopupShowing) return;

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

    final inputEmail = _emailController.text.trim();
    final inputPassword = _passwordController.text;

    // Offline Demo Flow: Only active when explicitly launched in Demo Mode.
    if (ArtisanDemoService.isDemoMode &&
        inputEmail.toLowerCase() == demoEmail &&
        inputPassword == demoPassword) {
      ArtisanDemoService.instance.resetToDefaults();

      const demoUser = UserModel(
        id: 'usr-demo-001',
        fullName: 'Kamal Perera (Demo)',
        email: demoEmail,
        role: 'tourist',
      );

      try {
        await _storageService.saveToken('demo-offline-jwt-token');
        await _storageService.saveUser(demoUser);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        await _showLoginSuccessPopupAndNavigate();
      }
      return;
    }

    try {
      final response = await _authService.login(
        email: inputEmail,
        password: inputPassword, // Never trim passwords
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

        final target = response.user.role == 'provider'
            ? '/provider/dashboard'
            : '/home';
        await _showLoginSuccessPopupAndNavigate(targetRoute: target);
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

    const royalBlue = Color(0xFF0A4DF5);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWhite,
        body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight <= 800;
            final showTrustFooter = constraints.maxHeight >= 500;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                          // Heading with royal-blue underline
                          const AuthHeading(
                            title: 'Welcome Back',
                            subtitle:
                                'Sign in to continue your CeylonGo journey',
                            underlineColor: royalBlue,
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
                                      color: royalBlue,
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

                          // Sign In Primary Button (Royal-blue to deep-blue vertical gradient)
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: _isLoading
                                    ? [
                                        const Color(0xFF1D63FF).withAlpha(150),
                                        const Color(0xFF0839B8).withAlpha(150),
                                      ]
                                    : const [
                                        Color(0xFF1D63FF),
                                        Color(0xFF0839B8),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: royalBlue.withAlpha(55),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              key: const Key('login_submit_button'),
                              onPressed: _isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: AppTheme.backgroundWhite,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                    color: royalBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Service Provider Portal Link
                          Center(
                            child: TextButton.icon(
                              key: const Key('provider_portal_link'),
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushNamed(
                                        context,
                                        '/provider/login',
                                      ),
                              icon: const Icon(
                                Icons.storefront_outlined,
                                size: 17,
                                color: AppTheme.primaryNavy,
                              ),
                              label: const Text(
                                'Service Provider Portal',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                          ),

                          if (ArtisanDemoService.isDemoMode) ...[
                            const SizedBox(height: 12),

                            // Clearly Labeled Offline Demo Flow (Explicit Demo Mode Only)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryNavy.withAlpha(45),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.offline_pin_outlined,
                                        size: 17,
                                        color: AppTheme.primaryNavy,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Offline Demo Flow',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Explore CeylonGo without a backend server:\ndemo@ceylongo.com • Demo@1234',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.5,
                                      color: AppTheme.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 38,
                                    child: ElevatedButton.icon(
                                      key: const Key('offline_demo_login_button'),
                                      onPressed: _isLoading ? null : _onDemoLogin,
                                      icon: const Icon(
                                        Icons.play_circle_filled,
                                        size: 18,
                                        color: AppTheme.backgroundWhite,
                                      ),
                                      label: const Text(
                                        'Sign In as Demo Traveler',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.backgroundWhite,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryNavy,
                                        foregroundColor: AppTheme.backgroundWhite,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (showTrustFooter)
                AuthTrustFooter(isCompact: isCompact),
              const AuthWaveDecoration(
                upperWaveColor: Color(0xFF60C3FF),
                lowerWaveColor: Color(0xFF082B5C),
              ),
            ],
          ),
        ),
      );
    },
  ),
),
    ),
    );
  }
}
