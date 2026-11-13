import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Subtle navy and orange wave decoration matching CeylonGo reference design
class AuthWaveDecoration extends StatelessWidget {
  final double? height;

  const AuthWaveDecoration({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final waveHeight = height ?? (screenWidth < 360 ? 45.0 : 55.0);

    return SizedBox(
      height: waveHeight,
      width: double.infinity,
      child: CustomPaint(
        painter: _AuthWavePainter(),
      ),
    );
  }
}

class _AuthWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Orange accent wave (background wave)
    final orangePaint = Paint()
      ..color = AppTheme.accentOrange
      ..style = PaintingStyle.fill;

    final orangePath = Path();
    orangePath.moveTo(0, size.height * 0.45);
    orangePath.quadraticBezierTo(
      size.width * 0.28,
      size.height * 0.1,
      size.width * 0.58,
      size.height * 0.5,
    );
    orangePath.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.85,
      size.width,
      size.height * 0.4,
    );
    orangePath.lineTo(size.width, size.height);
    orangePath.lineTo(0, size.height);
    orangePath.close();
    canvas.drawPath(orangePath, orangePaint);

    // Navy primary wave (foreground wave)
    final navyPaint = Paint()
      ..color = AppTheme.primaryNavy
      ..style = PaintingStyle.fill;

    final navyPath = Path();
    navyPath.moveTo(0, size.height * 0.65);
    navyPath.quadraticBezierTo(
      size.width * 0.24,
      size.height * 0.35,
      size.width * 0.52,
      size.height * 0.7,
    );
    navyPath.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.98,
      size.width,
      size.height * 0.6,
    );
    navyPath.lineTo(size.width, size.height);
    navyPath.lineTo(0, size.height);
    navyPath.close();
    canvas.drawPath(navyPath, navyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

