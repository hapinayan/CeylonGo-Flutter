import 'package:flutter/material.dart';

/// Featured business badge indicating admin curation and community spotlight.
/// Note: Must NOT be labeled as paid advertising per project specifications.
class FeaturedBadge extends StatelessWidget {
  final double fontSize;

  const FeaturedBadge({
    super.key,
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: fontSize + 1, color: const Color(0xFFD97706)),
          const SizedBox(width: 4),
          Text(
            'Featured Spotlight',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF92400E),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

