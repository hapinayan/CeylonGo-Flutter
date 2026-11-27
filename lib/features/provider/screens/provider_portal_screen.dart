import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/api_error.dart';
import '../../bookings/models/booking_models.dart';
import '../../categories/models/discovery_models.dart';
import '../../profile/services/account_service.dart';
import '../../profile/widgets/notifications_sheet.dart';
import '../models/booking_item_model.dart';
import '../models/provider_dashboard_data.dart';
import '../models/provider_models.dart';
import '../services/provider_service.dart';
import 'provider_bookings_screen.dart';
import 'provider_dashboard_screen.dart';
import 'provider_listings_screen.dart';

/// Live Academic MVP Provider Portal Screen (`/provider/dashboard`)
/// Fetches verification status, listings, bookings, and notifications from the backend,
/// and delegates rendering to the existing ProviderDashboardScreen design.
class ProviderPortalScreen extends StatefulWidget {
  final ProviderService? providerService;
  final AccountService? accountService;

  const ProviderPortalScreen({
    super.key,
    this.providerService,
    this.accountService,
  });

  @override
  State<ProviderPortalScreen> createState() => _ProviderPortalScreenState();
}

class _ProviderPortalScreenState extends State<ProviderPortalScreen> {
  late final ProviderService _service;
  late final AccountService _accountService;

  bool _isLoading = true;
  String? _error;
  ProviderProfileModel? _profile;
  List<ProviderListingModel> _listings = [];
  ProviderDashboardData? _dashboardData;
  List<BookingRecord> _rawBookings = [];

  @override
  void initState() {
    super.initState();
    _service = widget.providerService ?? ProviderService();
    _accountService = widget.accountService ?? AccountService();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _service.getMyProviderProfile();
      final results = await Future.wait([
        _service.getMyListings().catchError((_) => <ProviderListingModel>[]),
        _service.getProviderBookings().catchError((_) => <BookingRecord>[]),
        _accountService.getUnreadCount().catchError((_) => 0),
      ]);

      final listings = results[0] as List<ProviderListingModel>;
      final bookings = results[1] as List<BookingRecord>;
      final unread = results[2] as int;

      final titleByListingId = {
        for (final l in listings) l.id: l.title,
      };

      final now = DateTime.now();
      BookingItemModel toItem(BookingRecord b) {
        return BookingItemModel(
          id: b.id.toString(),
          guestName: b.travelerContact?.fullName ?? 'Traveler #${b.travelerId}',
          serviceTitle: titleByListingId[b.listingId] ?? 'Listing #${b.listingId}',
          dateTimeDescription:
              '${b.startsAt.toLocal().toString().substring(0, 10)} • Qty ${b.quantity}',
          status: b.status,
          amount: formatLkrAmount(b.totalAmount),
        );
      }

      final todayBookings = bookings
          .where((b) =>
              b.startsAt.toLocal().year == now.year &&
              b.startsAt.toLocal().month == now.month &&
              b.startsAt.toLocal().day == now.day &&
              b.status == 'confirmed')
          .map(toItem)
          .toList();

      final pending = bookings
          .where((b) => b.status == 'pending')
          .map(toItem)
          .toList();

      final upcoming = bookings
          .where((b) =>
              b.status == 'confirmed' && b.startsAt.toLocal().isAfter(now))
          .map(toItem)
          .toList();

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _listings = listings;
        _rawBookings = bookings;
        _dashboardData = ProviderDashboardData(
          businessName: profile.businessName,
          location:
              '${profile.district} • ${profile.verificationStatus.toUpperCase()}',
          notificationCount: unread,
          todayBookings: todayBookings,
          pendingRequests: pending,
          upcomingBookings: upcoming,
        );
        _isLoading = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load provider dashboard. Please sign in again.';
      });
    }
  }

  void _showMvpExcludedDialog(String featureName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(featureName),
        content: Text(
          '$featureName is excluded from the active Academic MVP v1.1 backend scope. '
          'Use Manage Listings and View Bookings for active service operations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showProviderProfileSheet() {
    final p = _profile;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              p?.businessName ?? 'Service Provider',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text('District: ${p?.district ?? '-'}'),
            Text('Phone: ${p?.phone ?? '-'}'),
            Text('Listings: ${_listings.length}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p?.verificationStatus == 'approved'
                    ? AppTheme.successGreen.withOpacity(0.1)
                    : AppTheme.accentOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Verification Status: ${(p?.verificationStatus ?? 'pending').toUpperCase()}'
                '${p?.decisionReason != null ? '\nNote: ${p!.decisionReason}' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _service.logoutProvider();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/provider/login',
                  (r) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log Out of Provider Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderDashboardScreen(
      data: _dashboardData,
      isLoading: _isLoading,
      errorMessage: _error,
      onRefresh: _loadDashboard,
      onMenuTap: _showProviderProfileSheet,
      onProfileTap: _showProviderProfileSheet,
      onNotificationsTap: () => showNotificationsSheet(
        context,
        accountService: _accountService,
        onUpdated: _loadDashboard,
      ),
      onManageListingsTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderListingsScreen(providerService: _service),
        ),
      ).then((_) => _loadDashboard()),
      onManageAvailabilityTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderListingsScreen(
            providerService: _service,
            focusAvailability: true,
          ),
        ),
      ).then((_) => _loadDashboard()),
      onAddListingTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderListingsScreen(providerService: _service),
        ),
      ).then((_) => _loadDashboard()),
      onViewBookingsTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderBookingsScreen(providerService: _service),
        ),
      ).then((_) => _loadDashboard()),
      onViewAllBookingsTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderBookingsScreen(providerService: _service),
        ),
      ).then((_) => _loadDashboard()),
      onBookingTap: (BookingItemModel item) {
        final matching = _rawBookings
            .where((b) => b.id.toString() == item.id)
            .toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderBookingsScreen(
              providerService: _service,
              initialStatus: matching.isNotEmpty ? matching.first.status : null,
            ),
          ),
        ).then((_) => _loadDashboard());
      },
      onCommunityTap: () => Navigator.pushNamed(context, '/community'),
      onCreatePromotionTap: () => _showMvpExcludedDialog('Create Promotion'),
      onPayoutsTap: () => _showMvpExcludedDialog('Payouts'),
      onTabSelected: (index) {
        if (index == 0) return;
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderBookingsScreen(providerService: _service),
            ),
          ).then((_) => _loadDashboard());
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderListingsScreen(providerService: _service),
            ),
          ).then((_) => _loadDashboard());
        } else if (index == 3) {
          _showProviderProfileSheet();
        }
      },
    );
  }
}
