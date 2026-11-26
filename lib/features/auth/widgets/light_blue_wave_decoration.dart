import 'package:flutter/material.dart';

/// Subtle light-blue wave decoration anchored at the bottom of the CeylonGo auth screens.
/// Matches the reference design with pure, minimal layered soft-blue waves.
class LightBlueWaveDecoration extends StatelessWidget {
  final double height;

  const LightBlueWaveDecoration({super.key, this.height = 70.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LightBlueWavePainter()),
    );
  }
}

class _LightBlueWavePainter extends CustomPainter {
  const _LightBlueWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft background wave (lighter sky blue)
    final bgPaint = Paint()
      ..color =
          const Color(0xFFEFF6FF) // Softest blue tint
      ..style = PaintingStyle.fill;

    final bgPath = Path();
    bgPath.moveTo(0, size.height * 0.45);
    bgPath.cubicTo(
      size.width * 0.30,
      size.height * 0.15,
      size.width * 0.65,
      size.height * 0.70,
      size.width,
      size.height * 0.35,
    );
    bgPath.lineTo(size.width, size.height);
    bgPath.lineTo(0, size.height);
    bgPath.close();
    canvas.drawPath(bgPath, bgPaint);

    // 2. Foreground wave (subtle light-blue)
    final fgPaint = Paint()
      ..color =
          const Color(0xFFDBEAFE) // Light blue accent (Tailwind blue-100)
      ..style = PaintingStyle.fill;

    final fgPath = Path();
    fgPath.moveTo(0, size.height * 0.70);
    fgPath.cubicTo(
      size.width * 0.35,
      size.height * 0.40,
      size.width * 0.70,
      size.height * 0.85,
      size.width,
      size.height * 0.55,
    );
    fgPath.lineTo(size.width, size.height);
    fgPath.lineTo(0, size.height);
    fgPath.close();
    canvas.drawPath(fgPath, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
