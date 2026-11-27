import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/booking_item_model.dart';
import '../models/provider_dashboard_data.dart';
import '../widgets/provider_app_header.dart';
import '../widgets/provider_bookings_section.dart';
import '../widgets/provider_bottom_navigation.dart';
import '../widgets/provider_management_grid.dart';
import '../widgets/provider_welcome_section.dart';
import 'provider_placeholder_screen.dart';

/// CeylonGo Service Provider Mobile Dashboard — Phase 01
/// Approved Minimal Blue + White Mobile Dashboard
/// Conforms strictly to specification and UI reference requirements.
class ProviderDashboardScreen extends StatefulWidget {
  final ProviderDashboardData? data;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onManageListingsTap;
  final VoidCallback? onViewBookingsTap;
  final VoidCallback? onCreatePromotionTap;
  final VoidCallback? onManageAvailabilityTap;
  final VoidCallback? onCommunityTap;
  final VoidCallback? onPayoutsTap;
  final VoidCallback? onAddListingTap;
  final VoidCallback? onViewAllBookingsTap;
  final ValueChanged<BookingItemModel>? onBookingTap;
  final ValueChanged<int>? onTabSelected;

  const ProviderDashboardScreen({
    super.key,
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.onMenuTap,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onManageListingsTap,
    this.onViewBookingsTap,
    this.onCreatePromotionTap,
    this.onManageAvailabilityTap,
    this.onCommunityTap,
    this.onPayoutsTap,
    this.onAddListingTap,
    this.onViewAllBookingsTap,
    this.onBookingTap,
    this.onTabSelected,
  });

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _currentTabIndex = 0;

  void _navigateToPlaceholder(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderPlaceholderScreen(
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading State
    if (widget.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
          ),
        ),
      );
    }

    // 2. Error State
    if (widget.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.borderSlate),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to Load Dashboard',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (widget.onRefresh != null)
                        ElevatedButton.icon(
                          onPressed: widget.onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Resolved view data (defaults to empty data when null)
    final dashboardData = widget.data ?? ProviderDashboardData.empty();

    final scrollableContent = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Royal Blue Header
          ProviderAppHeader(
            notificationCount: dashboardData.notificationCount,
            onMenuTap: widget.onMenuTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Provider Menu',
                      icon: Icons.menu_rounded,
                    ),
            onNotificationsTap: widget.onNotificationsTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Notifications',
                      icon: Icons.notifications_outlined,
                    ),
            onProfileTap: widget.onProfileTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Provider Profile',
                      icon: Icons.account_circle_outlined,
                    ),
          ),

          // 2. White Welcome Section
          ProviderWelcomeSection(
            businessName: dashboardData.businessName,
            location: dashboardData.location,
          ),

          const SizedBox(height: 6),

          // 3. Six Management Actions Grid (3-column, 2-row)
          ProviderManagementGrid(
            onManageListings: widget.onManageListingsTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Manage Listings',
                      icon: Icons.list_alt_rounded,
                    ),
            onViewBookings: widget.onViewBookingsTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'View Bookings',
                      icon: Icons.calendar_month_rounded,
                    ),
            onCreatePromotion: widget.onCreatePromotionTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Create Promotion',
                      icon: Icons.local_offer_rounded,
                    ),
            onManageAvailability: widget.onManageAvailabilityTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Manage Availability',
                      icon: Icons.event_available_rounded,
                    ),
            onCommunityFeed: widget.onCommunityTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Community Feed',
                      icon: Icons.forum_rounded,
                    ),
            onPayouts: widget.onPayoutsTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Payouts',
                      icon: Icons.account_balance_wallet_rounded,
                    ),
          ),

          const SizedBox(height: 8),

          // 4. Booking Sections
          // Section A: Today's Bookings
          ProviderBookingsSection(
            key: const Key('section_today_bookings'),
            title: "Today's Bookings",
            emptyMessage: 'No bookings scheduled for today.',
            bookings: dashboardData.todayBookings,
            onViewAll: widget.onViewAllBookingsTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: "Today's Bookings — All",
                      icon: Icons.calendar_today_rounded,
                    ),
            onBookingTap: widget.onBookingTap ??
                (BookingItemModel item) => _navigateToPlaceholder(
                      context,
                      title: 'Booking Details',
                      subtitle:
                          'Guest: ${item.guestName}\nService: ${item.serviceTitle}',
                      icon: Icons.receipt_long_rounded,
                    ),
          ),

          // Section B: Pending Requests
          ProviderBookingsSection(
            key: const Key('section_pending_requests'),
            title: 'Pending Requests',
            emptyMessage: 'No pending booking requests awaiting review.',
            bookings: dashboardData.pendingRequests,
            onViewAll: widget.onViewAllBookingsTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Pending Requests — All',
                      icon: Icons.pending_actions_rounded,
                    ),
            onBookingTap: widget.onBookingTap ??
                (BookingItemModel item) => _navigateToPlaceholder(
                      context,
                      title: 'Pending Request Details',
                      subtitle:
                          'Guest: ${item.guestName}\nService: ${item.serviceTitle}',
                      icon: Icons.pending_outlined,
                    ),
          ),

          // Section C: Upcoming Bookings
          ProviderBookingsSection(
            key: const Key('section_upcoming_bookings'),
            title: 'Upcoming Bookings',
            emptyMessage: 'No upcoming reservations found.',
            bookings: dashboardData.upcomingBookings,
            onViewAll: widget.onViewAllBookingsTap ??
                () => _navigateToPlaceholder(
                      context,
                      title: 'Upcoming Bookings — All',
                      icon: Icons.event_available_rounded,
                    ),
            onBookingTap: widget.onBookingTap ??
                (BookingItemModel item) => _navigateToPlaceholder(
                      context,
                      title: 'Upcoming Booking Details',
                      subtitle:
                          'Guest: ${item.guestName}\nService: ${item.serviceTitle}',
                      icon: Icons.event_note_rounded,
                    ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: widget.onRefresh != null
          ? RefreshIndicator(
              onRefresh: widget.onRefresh!,
              color: const Color(0xFF2563EB),
              child: scrollableContent,
            )
          : scrollableContent,
      bottomNavigationBar: ProviderBottomNavigation(
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          if (widget.onTabSelected != null) {
            widget.onTabSelected!(index);
            return;
          }
          setState(() {
            _currentTabIndex = index;
          });
          if (index != 0) {
            final tabTitles = ['Home', 'Bookings', 'Reports', 'Profile'];
            _navigateToPlaceholder(
              context,
              title: tabTitles[index],
              icon: Icons.tab_rounded,
            );
          }
        },
        onAddPressed: widget.onAddListingTap ??
            () => _navigateToPlaceholder(
                  context,
                  title: 'Add New Listing / Experience',
                  subtitle:
                      'Create new accommodations, homestays, or community experiences.',
                  icon: Icons.add_circle_outline_rounded,
                ),
      ),
    );
  }
}
