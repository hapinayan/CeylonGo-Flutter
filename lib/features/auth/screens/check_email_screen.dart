import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/light_blue_wave_decoration.dart';

/// Screen 7 / Reset Email Sent Screen
/// Confirmation screen displayed after password reset link has been dispatched.
/// Clean, minimal full-screen layout matching CeylonGo reference design.
class CheckEmailScreen extends StatelessWidget {
  final String? email;

  const CheckEmailScreen({super.key, this.email});

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
                ? 20.0
                : (screenWidth < 430 ? 24.0 : 28.0);
            final topPadding = isShort ? 32.0 : 48.0;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
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
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Bold Dark Navy Heading: "Reset Email Sent!"
                              Text(
                                'Reset Email Sent!',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: isShort ? 24.0 : 28.0,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryNavy,
                                  letterSpacing: -0.6,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 2. Subtitle: "We've sent a password reset link to your email address. Please check your inbox."
                              Text(
                                "We've sent a password reset link to your email address. Please check your inbox.",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: isShort ? 13.0 : 14.0,
                                  color: const Color(0xFF64748B),
                                  height: 1.45,
                                ),
                              ),
                              SizedBox(height: isShort ? 32 : 44),

                              // 3. Full-width blue gradient "Back to Sign In →" Button
                              SizedBox(
                                height: isShort ? 46 : 48,
                                child: ElevatedButton(
                                  key: const Key('back_to_signin_button'),
                                  onPressed: () {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/login',
                                      (route) => false,
                                    );
                                  },
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
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Back to Sign In',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: isShort ? 15.0 : 15.5,
                                              fontWeight: FontWeight.bold,
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
                            ],
                          ),
                        ),

                        // 4. Light-blue bottom wave decoration anchored to the bottom
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
