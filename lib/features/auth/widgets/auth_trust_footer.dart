import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Minimal trust footer displaying a small green outlined shield-check icon
/// and the CeylonGo tagline: "Discover Local. Feel at Home."
///
/// Designed to sit in the balanced whitespace between the form content
/// and the bottom wave decoration across all CeylonGo authentication screens.
class AuthTrustFooter extends StatelessWidget {
  final bool isCompact;
  final EdgeInsetsGeometry? padding;

  const AuthTrustFooter({
    super.key,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('auth_trust_footer'),
      color: AppTheme.backgroundWhite,
      padding: padding ?? EdgeInsets.symmetric(vertical: isCompact ? 4.0 : 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Small minimal green outlined shield-check icon
          Icon(
            Icons.verified_user_outlined,
            key: const Key('auth_trust_shield_icon'),
            size: isCompact ? 16.0 : 18.0,
            color: AppTheme.successGreen,
            semanticLabel: 'Verified Trust Badge',
          ),
          const SizedBox(height: 4),
          // Centered CeylonGo Tagline
          Text(
            'Discover Local. Feel at Home.',
            key: const Key('auth_trust_tagline'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 11.5 : 12.0,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

