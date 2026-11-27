import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/booking_item_model.dart';
import 'provider_booking_card.dart';

/// Reusable Booking Section for Provider Dashboard
/// Supports Today's Bookings, Pending Requests, and Upcoming Bookings
class ProviderBookingsSection extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<BookingItemModel> bookings;
  final VoidCallback onViewAll;
  final ValueChanged<BookingItemModel> onBookingTap;

  const ProviderBookingsSection({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.bookings,
    required this.onViewAll,
    required this.onBookingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header: Title + "View All" action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // List of bookings or empty state
          if (bookings.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_note_outlined,
                      size: 32,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: bookings
                  .map(
                    (b) => ProviderBookingCard(
                      key: Key('booking_item_${b.id}'),
                      booking: b,
                      onTap: () => onBookingTap(b),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
