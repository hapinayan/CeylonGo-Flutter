import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_wave_decoration.dart';

/// Screen 7: Check Your Email Screen
/// Displays confirmation and next steps after a password reset request
class CheckEmailScreen extends StatelessWidget {
  final String? email;

  const CheckEmailScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final resolvedEmail = email ??
        args?['email'] as String? ??
        'your-email@example.com';

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding =
        screenWidth < 360 ? 16.0 : (screenWidth < 430 ? 20.0 : 24.0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with Back Arrow
                        const AuthHeader(showBack: true),
                        const SizedBox(height: 24),

                        // Mail Icon Badge
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNavy.withAlpha(20),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryNavy.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            color: AppTheme.primaryNavy,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Heading with signature orange underline
                        const AuthHeading(
                          title: 'Check Your Email',
                          subtitle: 'We have sent password reset instructions to:',
                        ),
                        const SizedBox(height: 16),

                        // Email Badge Container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.borderSlate.withAlpha(80),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.borderSlate,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: AppTheme.primaryNavy,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  resolvedEmail,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryNavy,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Advisory notice
                        Text(
                          'Did not receive the email? Check your spam folder or verify your address.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppTheme.textSecondary.withAlpha(220),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Primary Button: "Open Email App"
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            key: const Key('open_email_app_button'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please check your email client inbox for the reset link.',
                                  ),
                                  backgroundColor: AppTheme.primaryNavy,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.outgoing_mail,
                              color: AppTheme.backgroundWhite,
                            ),
                            label: const Text(
                              'Open Email App',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.backgroundWhite,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: AppTheme.backgroundWhite,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Secondary Button: "Back to Sign In"
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            key: const Key('back_to_signin_button'),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.borderSlate,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
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
                        const SizedBox(height: 16),

                        // Link to Screen 8 (Enter New Password)
                        TextButton(
                          key: const Key('enter_new_password_link'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/create-new-password',
                              arguments: {'email': resolvedEmail},
                            );
                          },
                          child: const Text(
                            'Received your reset link? Set New Password',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

