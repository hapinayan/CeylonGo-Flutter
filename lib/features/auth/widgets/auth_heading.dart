import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Standard CeylonGo Auth Heading with signature orange underline
class AuthHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign textAlign;
  final double? fontSize;

  const AuthHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.center,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final computedFontSize = fontSize ?? (screenWidth < 360 ? 20.0 : 21.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: computedFontSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryNavy,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        // Signature CeylonGo Orange Heading Underline
        Container(
          width: 42,
          height: 3.5,
          decoration: BoxDecoration(
            color: AppTheme.accentOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

