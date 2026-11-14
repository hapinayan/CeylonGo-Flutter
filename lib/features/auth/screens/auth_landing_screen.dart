import 'package:flutter/material.dart';

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

    return Scaffold(
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

                          // Heading with signature orange underline
                          const AuthHeading(
                            title: 'Welcome to CeylonGo',
                            subtitle:
                                'Sign in or create an account to start exploring Sri Lanka',
                          ),
                          const SizedBox(height: 24),

                          // Email Address Field Label
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
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
                          const SizedBox(height: 18),

                          // Primary Button: Continue with Email
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              key: const Key('continue_with_email_button'),
                              onPressed: _onContinueWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: AppTheme.backgroundWhite,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
              if (showTrustFooter)
                AuthTrustFooter(isCompact: isCompact),
              const AuthWaveDecoration(),
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

