import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Compact "Recommended for You" entry card for Traveler HomeScreen.
class HomeRecommendedForYouCard extends StatelessWidget {
  final VoidCallback onExploreTap;

  const HomeRecommendedForYouCard({
    super.key,
    required this.onExploreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home_recommended_section'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primarySubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: AppTheme.primaryNavy,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick your Sri Lanka travel interests to discover matching homestays, activities, guides, and artisan experiences.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('home_open_recommendations_btn'),
              onPressed: onExploreTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Explore Recommendations'),
            ),
          ),
        ],
      ),
    );
  }
}

