import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_trust_footer.dart';
import '../widgets/auth_wave_decoration.dart';
import '../widgets/social_sign_in_buttons.dart';

/// Screen 1: Sign In / Register Entry Screen
/// Clean landing gateway with email validation and social login options
class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onContinueWithEmail() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();

    // Navigates to Welcome Back (Login) screen with prefilled email,
    // where user can enter password or toggle to Register if new.
    Navigator.pushNamed(
      context,
      '/login',
      arguments: {'email': email},
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth < 360 ? 16.0 : (screenWidth < 430 ? 20.0 : 24.0);

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
                                // Top Brand Header (without back button on entry root)
                                const AuthHeader(showBack: false),
                          const SizedBox(height: 20),

                          // Heading with royal-blue underline
                          const AuthHeading(
                            title: 'Welcome to CeylonGo',
                            subtitle:
                                'Sign in or create an account to start exploring Sri Lanka',
                            underlineColor: royalBlue,
                          ),
                          const SizedBox(height: 24),

                          // Email Address Field Label
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Email Address Input
                          TextFormField(
                            key: const Key('entry_email_field'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _onContinueWithEmail(),
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
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryNavy,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryNavy,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryNavy,
                                  width: 1.6,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.errorRed,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.errorRed,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            validator: FormValidators.validateEmail,
                          ),
                          const SizedBox(height: 18),

                          // Primary Button: Continue with Email (Royal-blue to deep-blue gradient)
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
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
                              key: const Key('continue_with_email_button'),
                              onPressed: _onContinueWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: AppTheme.backgroundWhite,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Continue with Email',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.backgroundWhite,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 18 : 24),

                          // Divider: "Or continue with"
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: AppTheme.borderSlate,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  'Or continue with',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary
                                        .withAlpha(200),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: AppTheme.borderSlate,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 16 : 20),

                          // Social Logins: Google & WhatsApp
                          const SocialSignInButtons(),
                          SizedBox(height: isCompact ? 18 : 24),

                          // New to CeylonGo? Create an Account
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'New to CeylonGo? ',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/register',
                                    arguments: {
                                      'email': _emailController.text.trim()
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

