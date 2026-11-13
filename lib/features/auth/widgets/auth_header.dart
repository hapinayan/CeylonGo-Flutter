import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Standard CeylonGo Auth Header
/// Displays Back button, CeylonGo Brand Logo, and Tagline: "Discover Local. Feel at Home."
class AuthHeader extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final canGoBack = showBack && (onBack != null || Navigator.canPop(context));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canGoBack)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('auth_back_button'),
              icon: const Icon(
                Icons.arrow_back,
                color: AppTheme.primaryNavy,
                size: 24,
              ),
              onPressed: onBack ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          )
        else
          const SizedBox(height: 12),
        const SizedBox(height: 8),

        // Centered CeylonGo Brand Logo
        Center(
          child: Image.asset(
            'assets/images/ceylongo_logo.png',
            height: screenWidth < 360 ? 56 : 64,
            fit: BoxFit.contain,
            semanticLabel: 'CeylonGo Logo',
          ),
        ),
        const SizedBox(height: 6),

        // Exact Tagline: "Discover Local. Feel at Home."
        const Center(
          child: Text(
            'Discover Local. Feel at Home.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

