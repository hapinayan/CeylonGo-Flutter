import 'package:flutter/material.dart';
import 'provider_management_card.dart';

/// Six management cards arranged in a 3-column, 2-row grid
/// 1. Manage Listings
/// 2. View Bookings
/// 3. Create Promotion
/// 4. Manage Availability
/// 5. Community Feed
/// 6. Payouts
class ProviderManagementGrid extends StatelessWidget {
  final VoidCallback onManageListings;
  final VoidCallback onViewBookings;
  final VoidCallback onCreatePromotion;
  final VoidCallback onManageAvailability;
  final VoidCallback onCommunityFeed;
  final VoidCallback onPayouts;

  const ProviderManagementGrid({
    super.key,
    required this.onManageListings,
    required this.onViewBookings,
    required this.onCreatePromotion,
    required this.onManageAvailability,
    required this.onCommunityFeed,
    required this.onPayouts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Row 1: Manage Listings, View Bookings, Create Promotion
          Row(
            children: [
              Expanded(
                child: ProviderManagementCard(
                  key: const Key('action_manage_listings'),
                  title: 'Manage Listings',
                  icon: Icons.list_alt_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                  onTap: onManageListings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProviderManagementCard(
                  key: const Key('action_view_bookings'),
                  title: 'View Bookings',
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBackgroundColor: const Color(0xFFECFDF5),
                  onTap: onViewBookings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProviderManagementCard(
                  key: const Key('action_create_promotion'),
                  title: 'Create Promotion',
                  icon: Icons.local_offer_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBackgroundColor: const Color(0xFFFFF7ED),
                  onTap: onCreatePromotion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Manage Availability, Community Feed, Payouts
          Row(
            children: [
              Expanded(
                child: ProviderManagementCard(
                  key: const Key('action_manage_availability'),
                  title: 'Manage Availability',
                  icon: Icons.event_available_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBackgroundColor: const Color(0xFFF5F3FF),
                  onTap: onManageAvailability,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProviderManagementCard(
                  key: const Key('action_community_feed'),
                  title: 'Community Feed',
                  icon: Icons.forum_rounded,
                  iconColor: const Color(0xFF0891B2),
                  iconBackgroundColor: const Color(0xFFECFEFF),
                  onTap: onCommunityFeed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ProviderManagementCard(
                  key: const Key('action_payouts'),
                  title: 'Payouts',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBackgroundColor: const Color(0xFFEFF6FF),
                  onTap: onPayouts,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
