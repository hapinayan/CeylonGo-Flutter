import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Social Sign-In Buttons: Google, Apple, WhatsApp
/// Conforms to reference screenshots while honestly presenting integration status
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Button
        _SocialButton(
          key: const Key('social_btn_google'),
          tooltip: 'Continue with Google',
          onTap: () => _handleTap(context, 'Google'),
          child: const _GoogleIcon(),
        ),
        const SizedBox(width: 16),

        // Apple Button
        _SocialButton(
          key: const Key('social_btn_apple'),
          tooltip: 'Continue with Apple',
          onTap: () => _handleTap(context, 'Apple'),
          child: const Icon(
            Icons.apple,
            color: AppTheme.primaryNavy,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // WhatsApp Button
        _SocialButton(
          key: const Key('social_btn_whatsapp'),
          tooltip: 'Continue with WhatsApp',
          onTap: () => _handleTap(context, 'WhatsApp'),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Color(0xFF25D366), // WhatsApp Brand Green
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  const _SocialButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 54,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSlate, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
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
      width: 22,
      height: 22,
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

