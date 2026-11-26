import 'package:flutter/material.dart';

import '../services/artisan_demo_service.dart';

/// Top indicator banner displayed across Artisan screens when Offline Demo Mode is active.
/// Clearly informs evaluators and presenters that displayed data is in-memory mock data
/// with strictly zero database or network traffic.
class ArtisanDemoBanner extends StatelessWidget {
  const ArtisanDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ArtisanDemoService.isDemoMode) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'DEMO MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'In-Memory Offline Simulation • Zero Database Calls',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

