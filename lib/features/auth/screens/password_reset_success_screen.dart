import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_wave_decoration.dart';

/// Screen 9: Password Reset Successful Screen
/// Confirms successful password update and navigates back to Sign In
class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

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
                        // Header (no back button on terminal success)
                        const AuthHeader(showBack: false),
                        const SizedBox(height: 24),

                        // Success Badge
                        Container(
                          width: 80,
                          height: 80,
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
                            color: AppTheme.successGreen,
                            size: 46,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Heading with signature orange underline
                        const AuthHeading(
                          title: 'Password Reset Successful',
                          subtitle:
                              'Your password has been updated. You can now sign in with your new password.',
                        ),
                        const SizedBox(height: 28),

                        // Primary Button: "Back to Sign In"
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            key: const Key('back_to_sign_in_button'),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: AppTheme.backgroundWhite,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Back to Sign In',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.backgroundWhite,
                              ),
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

