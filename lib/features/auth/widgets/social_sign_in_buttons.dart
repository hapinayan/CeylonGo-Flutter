import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Social Sign-In Buttons: Google & WhatsApp
///
/// Full-width outlined buttons conforming to CeylonGo branding with centered labels,
/// recognizable left-aligned logos, and honest integration reporting.
/// Apple sign-in is completely omitted.
class SocialSignInButtons extends StatelessWidget {
  final ValueChanged<String>? onProviderSelected;

  const SocialSignInButtons({super.key, this.onProviderSelected});

  void _handleTap(BuildContext context, String provider) {
    if (onProviderSelected != null) {
      onProviderSelected!(provider);
      return;
    }

    // Honest status reporting per specification: never fake social authentication
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider sign-in is not yet configured on this server. Please use email.',
        ),
        backgroundColor: AppTheme.primaryNavy,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Continue with Google
        _SocialOutlineButton(
          key: const Key('social_btn_google'),
          label: 'Continue with Google',
          icon: const _GoogleIcon(),
          onPressed: () => _handleTap(context, 'Google'),
        ),
        const SizedBox(height: 12),

        // Continue with WhatsApp
        _SocialOutlineButton(
          key: const Key('social_btn_whatsapp'),
          label: 'Continue with WhatsApp',
          icon: const _WhatsAppIcon(),
          onPressed: () => _handleTap(context, 'WhatsApp'),
        ),
      ],
    );
  }
}

/// Full-width outlined social button with logo on the left and centered text
class _SocialOutlineButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const _SocialOutlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(
          color: AppTheme.borderSlate,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: icon,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Google 'G' icon rendered with high fidelity
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);

    // Draw Google 4-color arcs
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Green (bottom right to bottom left)
    canvas.drawArc(rect, 0.78, 1.57, true, greenPaint);
    // Yellow (bottom left to top left)
    canvas.drawArc(rect, 2.35, 1.57, true, yellowPaint);
    // Red (top left to top right)
    canvas.drawArc(rect, 3.92, 1.57, true, redPaint);
    // Blue (top right to middle)
    canvas.drawArc(rect, 5.49, 1.57, true, bluePaint);

    // White inner cutout
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, innerPaint);

    // Blue horizontal bar
    final barRect = Rect.fromLTRB(
      center.dx - 1,
      center.dy - (radius * 0.22),
      size.width,
      center.dy + (radius * 0.22),
    );
    canvas.drawRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Recognizable WhatsApp icon: green speech bubble with white phone receiver
class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(22, 22),
            painter: _WhatsAppBubblePainter(),
          ),
          const Icon(
            Icons.phone,
            color: Colors.white,
            size: 12,
          ),
        ],
      ),
    );
  }
}

class _WhatsAppBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final greenPaint = Paint()
      ..color = const Color(0xFF25D366) // WhatsApp brand green
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final radius = size.width * 0.45;

    path.addOval(Rect.fromCircle(center: center, radius: radius));

    // Subtle speech bubble tail at bottom-left
    final tailPath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.72)
      ..lineTo(size.width * 0.08, size.height * 0.92)
      ..lineTo(size.width * 0.36, size.height * 0.86)
      ..close();

    path.addPath(tailPath, Offset.zero);
    canvas.drawPath(path, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
