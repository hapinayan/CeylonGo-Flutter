import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Provider Welcome Section
/// Conforms to approved specifications:
/// - Displays "Welcome Back,"
/// - Displays provider's business name
/// - Displays location with pin icon
/// - Excludes "Service Provider" and "Verified Provider"
class ProviderWelcomeSection extends StatelessWidget {
  final String businessName;
  final String location;

  const ProviderWelcomeSection({
    super.key,
    required this.businessName,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final displayBusinessName =
        businessName.isNotEmpty ? businessName : 'Your Business';
    final displayLocation =
        location.isNotEmpty ? location : 'Sri Lanka';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Welcome Back,"
          const Text(
            'Welcome Back,',
            key: Key('provider_welcome_greeting'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),

          // Business Name
          Text(
            displayBusinessName,
            key: const Key('provider_business_name'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
              letterSpacing: -0.4,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Location with pin icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayLocation,
                  key: const Key('provider_location_text'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
