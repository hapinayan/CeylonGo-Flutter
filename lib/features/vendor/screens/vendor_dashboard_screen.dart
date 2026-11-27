import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/vendor_models.dart';
import '../services/vendor_demo_service.dart';
import '../widgets/vendor_bottom_nav_bar.dart';
import '../widgets/vendor_listing_image.dart';

/// Final Approved Pure-White Vendor Dashboard Screen
/// Displays a pure white header, 4 KPI statistic cards, 2 compact management
/// shortcuts, recent booking requests, and the fixed 4-item Vendor Bottom Nav.
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final VendorDemoService _service = VendorDemoService.instance;

  Future<void> _navigateAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    if (mounted) {
      setState(() {});
    }
  }

  String _formatLkr(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'LKR ${buf.toString()}';
  }

  VendorListing? _findListingForBooking(VendorBookingRequest booking) {
    for (final item in _service.listings) {
      if (item.title == booking.listingTitle) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vendor = _service.currentVendor;
    final recentBookings = _service.bookings.take(3).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const VendorBottomNavigationBar(currentIndex: 0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pure White Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${vendor.businessName}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            vendor.isDemoSession
                                ? '${vendor.category.label} • ${vendor.location} (Demo Mode)'
                                : '${vendor.category.label} • ${vendor.location}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      key: const Key('vendor_dashboard_profile_icon'),
                      onTap: () => _navigateAndRefresh('/vendor/profile'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDBEAFE),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2x2 KPI Cards
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Total Listings',
                        value: '${_service.totalListingsCount}',
                        icon: Icons.storefront_outlined,
                        accentColor: const Color(0xFF0A4DF5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Active Listings',
                        value: '${_service.activeListingsCount}',
                        icon: Icons.check_circle_outline_rounded,
                        accentColor: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Total Booking Requests',
                        value: '${_service.totalBookingsCount}',
                        icon: Icons.event_note_outlined,
                        accentColor: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Pending Bookings',
                        value: '${_service.pendingBookingsCount}',
                        icon: Icons.hourglass_top_rounded,
                        accentColor: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Recent Booking Requests
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Booking Requests',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      key: const Key('vendor_view_all_bookings'),
                      onTap: () => _navigateAndRefresh('/vendor/bookings'),
                      child: const Text(
                        'View all →',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A4DF5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...recentBookings.map((booking) {
                  final matchedListing = _findListingForBooking(booking);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _navigateAndRefresh('/vendor/bookings'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 54,
                              height: 54,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: VendorListingImage(
                                  photo: matchedListing?.coverPhoto,
                                  fallbackImageUrl:
                                      matchedListing?.imageUrl ?? '',
                                  fallbackIcon: Icons.calendar_today_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.listingTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${booking.customerName} • ${booking.dateRange}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatLkr(booking.totalLkr),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A4DF5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(status: booking.status),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final VendorBookingStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      VendorBookingStatus.pending => const Color(0xFFEA580C),
      VendorBookingStatus.accepted => const Color(0xFF16A34A),
      VendorBookingStatus.rejected => const Color(0xFFDC2626),
      VendorBookingStatus.completed => const Color(0xFF0A4DF5),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
