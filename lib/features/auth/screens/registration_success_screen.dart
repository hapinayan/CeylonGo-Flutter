import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/user_model.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_wave_decoration.dart';

/// Screen 3: Registration Successful
/// Displays confirmed registration details with actual user name and email
class RegistrationSuccessScreen extends StatelessWidget {
  final UserModel? user;
  final String? message;

  const RegistrationSuccessScreen({super.key, this.user, this.message});

  @override
  Widget build(BuildContext context) {
    // Read user from widget or route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final resolvedUser = user ?? args?['user'] as UserModel?;
    final successMessage = message ??
        args?['message'] as String? ??
        'Your CeylonGo account has been created successfully.';

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
                        // Header (no back button, registration is finalized)
                        const AuthHeader(showBack: false),
                        const SizedBox(height: 24),

                        // Success Animated / Styled Icon Badge
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
                          title: 'Registration Successful',
                          subtitle:
                              'Your CeylonGo traveler account is ready to use.',
                        ),
                        const SizedBox(height: 24),

                        // Actual Registered User Details Card
                        if (resolvedUser != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.borderSlate,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(6),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppTheme.primaryNavy,
                                      child: Icon(
                                        Icons.person,
                                        color: AppTheme.backgroundWhite,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            resolvedUser.fullName.isNotEmpty
                                                ? resolvedUser.fullName
                                                : 'Traveler',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            resolvedUser.email,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryNavy.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        resolvedUser.role.toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 24,
                                  color: AppTheme.borderSlate,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppTheme.accentOrange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        successMessage,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Primary Button: "Explore CeylonGo"
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            key: const Key('explore_ceylongo_button'),
                            onPressed: () {
                              // Navigates to Welcome Back (Sign In) with registered email prefilled
                              Navigator.pushReplacementNamed(
                                context,
                                '/login',
                                arguments: {'email': resolvedUser?.email ?? ''},
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
                              'Explore CeylonGo',
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

                        // Secondary Link: "Back to Sign In"
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
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

