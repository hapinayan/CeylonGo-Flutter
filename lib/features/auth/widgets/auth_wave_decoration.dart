import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Subtle layered wave decoration matching CeylonGo reference design
class AuthWaveDecoration extends StatelessWidget {
  final double? height;
  final Color? upperWaveColor;
  final Color? lowerWaveColor;

  const AuthWaveDecoration({
    super.key,
    this.height,
    this.upperWaveColor,
    this.lowerWaveColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final waveHeight = height ?? (screenWidth < 360 ? 45.0 : 55.0);

    return SizedBox(
      height: waveHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _AuthWavePainter(
          upperWaveColor: upperWaveColor ?? AppTheme.accentOrange,
          lowerWaveColor: lowerWaveColor ?? AppTheme.primaryNavy,
        ),
      ),
    );
  }
}

class _AuthWavePainter extends CustomPainter {
  final Color upperWaveColor;
  final Color lowerWaveColor;

  const _AuthWavePainter({
    required this.upperWaveColor,
    required this.lowerWaveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Upper accent wave (background wave)
    final upperPaint = Paint()
      ..color = upperWaveColor
      ..style = PaintingStyle.fill;

    final upperPath = Path();
    upperPath.moveTo(0, size.height * 0.45);
    upperPath.quadraticBezierTo(
      size.width * 0.28,
      size.height * 0.1,
      size.width * 0.58,
      size.height * 0.5,
    );
    upperPath.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.85,
      size.width,
      size.height * 0.4,
    );
    upperPath.lineTo(size.width, size.height);
    upperPath.lineTo(0, size.height);
    upperPath.close();
    canvas.drawPath(upperPath, upperPaint);

    // Lower primary wave (foreground wave)
    final lowerPaint = Paint()
      ..color = lowerWaveColor
      ..style = PaintingStyle.fill;

    final lowerPath = Path();
    lowerPath.moveTo(0, size.height * 0.65);
    lowerPath.quadraticBezierTo(
      size.width * 0.24,
      size.height * 0.35,
      size.width * 0.52,
      size.height * 0.7,
    );
    lowerPath.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.98,
      size.width,
      size.height * 0.6,
    );
    lowerPath.lineTo(size.width, size.height);
    lowerPath.lineTo(0, size.height);
    lowerPath.close();
    canvas.drawPath(lowerPath, lowerPaint);
  }

  @override
  bool shouldRepaint(covariant _AuthWavePainter oldDelegate) =>
      oldDelegate.upperWaveColor != upperWaveColor ||
      oldDelegate.lowerWaveColor != lowerWaveColor;
}

