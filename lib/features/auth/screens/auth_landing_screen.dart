import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../widgets/social_sign_in_buttons.dart';

/// Screen 1: Sign In / Create Account Entry Screen
/// Exact 3D Cartoon Tourism Login Design:
/// - Header with 3D cartoon tourist boy holding camera, Sigiriya Lion Rock,
///   tropical palms, greenery, lavender-blue sky, and orange spark accents.
/// - Circular white back button at upper-left.
/// - Distinctive layered organic white curved wave transition into the form area.
/// - Two-line bold navy title: 'Sign In /\nCreate Account' with strong visual weight.
/// - Natural soft-wrapped subtitle below header.
/// - Compact rounded email input with navy envelope icon.
/// - Vivid royal-blue gradient 'Continue with Email' pill-shaped button.
/// - Centered 'or continue with' divider.
/// - Outlined Google and WhatsApp buttons with brand logos.
/// - Discreet 'New to CeylonGo? Create Account' link navigating to /register.
/// - Centered Terms & Conditions and Privacy Policy disclaimer.
/// - Responsive layout on Samsung Galaxy A22 (360x800) with zero scrolling.
class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailFocusNode.dispose();
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
    Navigator.pushNamed(context, '/login', arguments: {'email': email});
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          key: const Key('auth_back_button'),
          customBorder: const CircleBorder(),
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.primaryNavy,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2563EB), // Vivid royal blue
            Color(0xFF1D4ED8), // Deep royal blue
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x381D4ED8),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('continue_with_email_button'),
          onTap: _onContinueWithEmail,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Continue with Email',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360
        ? 16.0
        : (screenWidth < 430 ? 20.0 : 24.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWhite,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Dynamic header height: absorbs surplus vertical space on larger viewports (Samsung A22 800px)
            // while scaling gracefully on SafeArea-constrained viewports (728px) and short displays.
            final dynamicHeaderHeight = constraints.maxHeight >= 728.0
                ? (180.0 + (constraints.maxHeight - 728.0) * 0.85).clamp(
                    180.0,
                    260.0,
                  )
                : 180.0;

            const measuredFormHeight = 546.0;
            final totalContentHeight = dynamicHeaderHeight + measuredFormHeight;
            final canScroll = constraints.maxHeight < totalContentHeight;
            final scrollPhysics = canScroll
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics();

            final bottomPadding = constraints.maxHeight >= 800.0 ? 20.0 : 16.0;
            final panelAvailableHeight =
                constraints.maxHeight - dynamicHeaderHeight;
            final panelContentMinHeight =
                panelAvailableHeight - 14.0 - bottomPadding;

            return SingleChildScrollView(
              physics: scrollPhysics,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. 3D Cartoon Tourist & Sigiriya Scenery Header
                    SizedBox(
                      key: const Key('auth_header_container'),
                      height: dynamicHeaderHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Pastel lavender-blue background fallback
                          Positioned.fill(
                            child: Container(color: const Color(0xFFDCE5F5)),
                          ),

                          // 3D Cartoon Tourist Boy + Sigiriya Lion Rock Illustration
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/tourist_sigiriya_header.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) {
                                // Graceful fallback if image asset is not loaded in unit test environment
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFDCE5F5),
                                        Color(0xFFEDF3FC),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Clear, elegant organic white curved wave transition at bottom of header
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: -1,
                            height: 46,
                            child: const CustomPaint(
                              painter: _HeaderOrganicWavePainter(),
                            ),
                          ),

                          // Small circular white back button at upper-left
                          Positioned(
                            left: 16,
                            top: 0,
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildBackButton(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Form & Content Area
                    Container(
                      key: const Key('auth_content_panel'),
                      constraints: BoxConstraints(
                        minHeight: panelAvailableHeight,
                      ),
                      width: double.infinity,
                      color: AppTheme.backgroundWhite,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            14,
                            horizontalPadding,
                            bottomPadding,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 440,
                                minHeight: canScroll
                                    ? 0.0
                                    : panelContentMinHeight,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisAlignment: canScroll
                                      ? MainAxisAlignment.start
                                      : MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Group 1: Two-Line Extra-Bold Navy Heading & Subtitle
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Sign In /\nCreate Account',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: screenWidth < 360
                                                ? 26.0
                                                : 27.0,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primaryNavy,
                                            letterSpacing: -0.6,
                                            height: 1.15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Your gateway to authentic Sri Lankan experiences.',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF64748B),
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Group 2: Email input field & Continue button
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: canScroll ? 14.0 : 0.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            key: const Key('entry_email_field'),
                                            controller: _emailController,
                                            focusNode: _emailFocusNode,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) =>
                                                _onContinueWithEmail(),
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              color: AppTheme.textPrimary,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Enter your email address',
                                              hintStyle: const TextStyle(
                                                fontFamily: 'Inter',
                                                color: Color(0xFF94A3B8),
                                                fontSize: 13.5,
                                              ),
                                              prefixIcon: const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 14,
                                                  right: 10,
                                                ),
                                                child: Icon(
                                                  Icons.mail_outline_rounded,
                                                  color: AppTheme.primaryNavy,
                                                  size: 20,
                                                ),
                                              ),
                                              prefixIconConstraints:
                                                  const BoxConstraints(
                                                    minWidth: 44,
                                                    minHeight: 44,
                                                  ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 10,
                                                  ),
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE2E8F0),
                                                  width: 1.2,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE2E8F0),
                                                  width: 1.2,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF2563EB),
                                                  width: 1.5,
                                                ),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.errorRed,
                                                  width: 1.2,
                                                ),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    borderSide:
                                                        const BorderSide(
                                                          color:
                                                              AppTheme.errorRed,
                                                          width: 1.5,
                                                        ),
                                                  ),
                                            ),
                                            validator:
                                                FormValidators.validateEmail,
                                          ),
                                          const SizedBox(height: 12),

                                          // Continue with Email Vivid Royal Blue Button
                                          _buildContinueButton(),
                                        ],
                                      ),
                                    ),

                                    // Group 3: Divider: "or continue with"
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: canScroll ? 14.0 : 0.0,
                                      ),
                                      child: Row(
                                        children: const [
                                          Expanded(
                                            child: Divider(
                                              color: Color(0xFFE2E8F0),
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'or continue with',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: Color(0xFFE2E8F0),
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Group 4: Social Buttons: Google & WhatsApp
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: canScroll ? 14.0 : 0.0,
                                      ),
                                      child: const SocialSignInButtons(
                                        buttonHeight: 42.0,
                                        spacing: 8.0,
                                        borderRadius: 12.0,
                                      ),
                                    ),

                                    // Group 5: New to CeylonGo? Create Account Link
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: canScroll ? 14.0 : 0.0,
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          const Text(
                                            'New to CeylonGo? ',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/register',
                                                arguments: {
                                                  'email': _emailController.text
                                                      .trim(),
                                                },
                                              );
                                            },
                                            child: const Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.accentOrange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Group 6: Terms & Conditions and Privacy Policy Disclaimer
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: canScroll ? 18.0 : 0.0,
                                      ),
                                      child: Text.rich(
                                        TextSpan(
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            height: 1.35,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: 'By continuing, you agree to our\n',
                                            ),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.baseline,
                                              baseline: TextBaseline.alphabetic,
                                              child: GestureDetector(
                                                onTap: () {},
                                                child: const Text(
                                                  'Terms & Conditions',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primaryNavy,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const TextSpan(text: ' and '),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.baseline,
                                              baseline: TextBaseline.alphabetic,
                                              child: GestureDetector(
                                                onTap: () {},
                                                child: const Text(
                                                  'Privacy Policy',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primaryNavy,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const TextSpan(text: '.'),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

/// Exact solid white asymmetrical organic wave painter:
/// Starts lower on the left (overlapping tourist's lower body)
/// and rises smoothly toward the right beneath Sigiriya Rock.
/// Provides a completely pure white transition without gray seams.
class _HeaderOrganicWavePainter extends CustomPainter {
  const _HeaderOrganicWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    // Starts lower on the left (at 80% height), overlapping tourist's lower body
    path.moveTo(0, size.height * 0.80);
    // Smooth asymmetrical Bézier curve rising up beneath Sigiriya
    path.cubicTo(
      size.width * 0.36,
      size.height * 0.78,
      size.width * 0.65,
      size.height * 0.18,
      size.width,
      size.height * 0.22,
    );
    path.lineTo(size.width, size.height + 2);
    path.lineTo(0, size.height + 2);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
